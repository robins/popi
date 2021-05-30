# lock the script so only one runs at a time
exec 200<$0
flock -n 200 || exit 1

if (( $# < 3 )); then
# 1 -> folder
# 2 -> port
# 3 -> commit - hash
echo "Need at least 3 arguments (folder port hash). For e.g. master 5433 14ea36520389dbb1b48524223cf09389154a0f2e"
exit 1
fi

tempdel="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
basedir="$(dirname "$tempdel")"

scriptdir=${basedir}/script
logdir=${basedir}/log
historylog=${logdir}/history.log
installdir=${basedir}/stage/${1}/install
bindir=${installdir}/bin
datadir=${installdir}/data
obsdir=${basedir}/obs/${1}/${3}
logprefixfile=${scriptdir}/logprefix

port=${2}
branch=${1} # XXX: We're piggy backing the branch name on the folder name, ideally we need this done properly

dbuser=`whoami`
enable_logging=1

log() {
  if [[ ${enable_logging} -eq 1 ]]; then
    dt=`date '+%Y-%m-%d %H:%M:%S'`
    echo "${dt}: "`cat ${logprefixfile}`" :${1}"
  fi
}

logh() {
  log "RunTest (${branch}): ${1}" >> ${historylog}
}

startScript() {
    mkdir -p ${logdir}
    logh "=== Start RunTest Script ==="
}

stopScript() {
    logh "--- Stop RunTest Script ---"
}

runsql() {
  ${bindir}/psql -h localhost -U ${dbuser} -p ${port} -c "${1}" postgres &>> ${historylog}
}

ExitIfBinariesAreMissing() {
  if [[ ! -d ${bindir} ]]; then
    echo Are you sure that the Repository exists? Quitting.
    exit 1
  fi
}


ExitIfBinariesAreMissing
touch ${logprefixfile}
startScript

logh "Dropping old pgbench DB"
runsql "DROP DATABASE IF EXISTS pgbench;"

logh "Creating pgbench DB"
runsql "CREATE DATABASE pgbench;"

# Disable Unlogged tables for now
unlogged=""

logh "Creating pgbench tables"
${bindir}/pgbench -i -h localhost -U ${dbuser} -p ${port} pgbench

logh "Running Pre SQL"
${bindir}/psql -1f ${scriptdir}/pre.sql ${unlogged} -h localhost -U ${dbuser} -p ${port} pgbench

q=${scriptdir}/a.sql
s=10
w=100
runtests=1


function waitnwatch {
  max="$(( `nproc` * 25 ))"
  while true; do
    upstr=$(uptime | grep -aob "average:" | grep -oE '[0-9]+')
    c1=$(uptime | cut -b ${upstr}- | awk '{print $2;}' | sed s/,//g)
          c=`echo $c1*100|bc`
          c=${c%.*}

    logh "Current CPU (${c}) vs Allowed threshold (${max})"
    if [[ $c -le $max ]]; then
      logh "Condition satisfied. Going ahead with Test."
      break
    fi

    sleep $s
  done
}

runiteration() {
#1 connections
#2 parallel threads
#3 is_prepared
#4 is_select_only
#5 is_connect_only

  fname=''
  other_options=''

  if [[ $3 -eq 1 ]]; then
    other_options=${other_options}' -M prepared '
    fname='M'
  fi

  if [[ $4 -eq 1 ]]; then
    other_options=${other_options}' -S '
    fname="${fname}S"
  fi

  if [[ $5 -eq 1 ]]; then
    other_options=${other_options}' -C '
    fname="C${fname}"
  fi

  fname="c${1}j${2}${fname}T${w}"

  ${bindir}/pgbench -n -c${1} -j${2} ${other_options} -P1 -p ${port} -T${w} -h localhost -U ${dbuser} pgbench &>${obsdir}/${fname}
}

  mkdir -p ${obsdir}

if [[ $runtests -eq 1 ]]; then

  logh "Triggering pgbench"

runsql 'SELECT now(), version();'

for is_conn_included in 2;
  do
  for is_select_only in 1;
    do
    for is_prepared in 1;
      do
        for i in 2 ; # 3 4; # 8 12 16 32 64 ;
        do
          waitnwatch
          logh "Iteration (\\\$i=$i) (\\\$is_conn_included=$is_conn_included) (\\\$is_select_only=$is_select_only) (\\\$is_prepared=$is_prepared) for ${w} seconds" && \
          runiteration $i 1 ${is_prepared} ${is_select_only} ${is_conn_included}
        done
      done
    done
  done
fi

runsql 'SELECT now(), version();'

#${bindir}/psql -1f ${scriptdir}/post.sql -U ${dbuser} -p ${port} pgbench

stopScript
