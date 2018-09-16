#XXX: Per docs, we should be doing at least a pgbench -i s4 for a 4 connection test

#XXX: See what needs to be done for minor version change. Keep non-cycling T means the results would be broken in minor version numbers.
#     irrespective of whether we eventually cycle T or not, we should be resetting the non-matching versions first, when re-running

# lock the script so only one runs at a time
#exec 200<$0
#flock -n 200 || exit 1

if (( $# < 3 )); then
# 1 -> folder
# 2 -> port
# 3 -> commit - hash
echo "Need at least 3 arguments (folder port hash). For e.g. master 5433 14ea36520389dbb1b48524223cf09389154a0f2e"
exit 1
fi

basedir=/home/pi/projects/popi
scriptdir=${basedir}/script
logdir=${basedir}/log/${1}
installdir=${basedir}/stage/${1}/install
bindir=${installdir}/bin
datadir=${installdir}/data
obsdir=${basedir}/obs/${1}/${3}
port=${2}

dbuser=pi
enable_logging=1

log() {
        if [[ ${enable_logging} -eq 1 ]]; then
                echo ${1}
        fi
}

#This is a hack that get pgbench working for old branches.
#/postgres/master is outside this repo, but its (effectively) a static binary that we could link with here
#rm -f /opt/postgres/${1}/bin/pgbench
#sudo -u root -H sh -c ln -s /opt/postgres/pgbench /opt/postgres/${1}/bin/pgbench"

# Can't do a --if-exists here, since old pg versions dont understand and bail, which is not what we want

log "Dropping old pgbench DB"
${bindir}/dropdb -h localhost -U ${dbuser} -p ${port} pgbench &>/dev/null

log "Creating pgbench DB"
${bindir}/createdb -h localhost -U ${dbuser} -p ${port} pgbench

# Disable Unlogged tables for now
unlogged=""

log "Creating pgbench tables"
${bindir}/pgbench -i -h localhost -U ${dbuser} -p ${port} pgbench

log "Runing Pre SQL"
${bindir}/psql -1f ${scriptdir}/pre.sql ${unlogged} -h localhost -U ${dbuser} -p ${port} pgbench

#if [[ ${1} -eq "master" ]]; then
#	${bindir}/bin/psql -c 'ALTER USER pi SET max_parallel_processes=4;' -h localhost -U ${dbuser} -p ${port} pgbench
#fi

q=${scriptdir}/a.sql
s=1
w=20
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
#3 additional options
  ${bindir}/pgbench -n -c${1} -j${2} ${3} -P1 -p ${port} -T${w} -h localhost -U ${dbuser} pgbench &>${obsdir}/c${1}j${2}FT${w}.txt
}

  echo "Runtest: Triggering battery of tests T=${t}" >> ${logdir}/history.log
  mkdir -p ${obsdir}

if [[ $runtests -eq 1 ]]; then

  echo "Runtest: Triggering pgbench instance at (`pwd`)" >> ${logdir}/history.log

#  waitnwatch; 
#  ${bindir}/pgbench -n -c1 -j1 -P1 -p ${port} -T${w} -h localhost -U ${dbuser} pgbench &>${obsdir}/c1j1FT${w}.txt
  #waitnwatch; 

for i in 1 2 3 4 8 12 16 32 64 ;
  do
    runiteration $i $(($i<4?1:4))
  done

for i in 1 2 3 4 8 12 16 32 64 ;
  do
    runiteration $i $(($i<4?1:4)) '-S'
  done

for i in 1 2 3 4 8 12 16 32 64 ;
  do
    runiteration $i $(($i<4?1:4)) '-M prepared'
  done

for i in 1 2 3 4 8 12 16 32 64 ;
  do
    runiteration $i $(($i<4?1:4)) '-S -M prepared'
  done

fi

  ${bindir}/psql -h localhost -U ${dbuser} -p ${port} -c 'SELECT version();' postgres > ${logdir}/version.txt

#${bindir}/psql -1f ${scriptdir}/post.sql -U ${dbuser} -p ${port} pgbench

log "RunTests completed. Exiting"
