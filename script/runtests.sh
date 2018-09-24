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

basedir=/home/pi/projects/popi
scriptdir=${basedir}/script
logdir=${basedir}/log
historylog=${logdir}/history.log
installdir=${basedir}/stage/${1}/install
bindir=${installdir}/bin
datadir=${installdir}/data
obsdir=${basedir}/obs/${1}/${3}

port=${2}
branch=${1} # XXX: We're piggy backing the branch name on the folder name, ideally we need this done properly

dbuser=pi
enable_logging=1

log() {
  if [[ ${enable_logging} -eq 1 ]]; then
    dt=`date '+%Y-%m-%d %H:%M:%S'`
    echo "${dt}: ${1}"
  fi
}

logh() {
  log "RunTest (${branch} branch): ${1}" >> ${historylog}
}

runsql() {
  ${bindir}/psql -h localhost -U ${dbuser} -p ${port} -c "${1}" postgres &>> ${historylog}
}

logh "Start Script"

logh "Dropping old pgbench DB"
runsql "DROP DATABASE IF EXISTS pgbench;"

logh "Creating pgbench DB"
runsql "CREATE DATABASE pgbench;"

# Disable Unlogged tables for now
unlogged=""

logh "Creating pgbench tables"
${bindir}/pgbench -i -h localhost -U ${dbuser} -p ${port} pgbench

logh "Runing Pre SQL"
${bindir}/psql -1f ${scriptdir}/pre.sql ${unlogged} -h localhost -U ${dbuser} -p ${port} pgbench

q=${scriptdir}/a.sql
s=1
w=100
runtests=1


function waitnwatch {
  max=100
  while true; do
    upstr=$(uptime | grep -aob "average:" | grep -oE '[0-9]+')
    c1=$(uptime | cut -b ${upstr}- | awk '{print $2;}' | sed s/,//g)
          c=`echo $c1*100|bc`
          c=${c%.*}

    echo "Current CPU (${c}) vs Allowed threshold (${max})"
    if [[ $c -le $max ]]; then
      echo "Proceeding"
      break
    fi

    date
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

#  waitnwatch; 
#  ${bindir}/pgbench -n -c1 -j1 -P1 -p ${port} -T${w} -h localhost -U ${dbuser} pgbench &>${obsdir}/c1j1FT${w}.txt
  #waitnwatch; 

runsql 'SELECT now(), version();'

#for i in 1 2 3 4 8 12 16 32 64 ;
for is_conn_included in 1 2;
  do
  for is_select_only in 1 2;
    do
    for is_prepared in 1 2;
      do
        for i in 1 2;
        do
          logh "Iteration (\\\$i=$i) (\\\$is_conn_included=$is_conn_included) (\\\$is_select_only=$is_select_only) (\\\$is_prepared=$is_prepared) for ${w} seconds" && \
            runiteration $i $(($i<4?1:4)) ${is_prepared} ${is_select_only} ${is_conn_included}
        done
      done
    done
  done
fi

runsql 'SELECT now(), version();'

#${bindir}/psql -1f ${scriptdir}/post.sql -U ${dbuser} -p ${port} pgbench

logh "Stop  Script"
