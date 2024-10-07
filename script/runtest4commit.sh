#!/bin/bash

## This script accepts 3 variables (test, config, commit) and populates the /obs/test/ folder with the performance numbers
## observed for that test.
##
## It assumes that the engine is already up at the port number given in the test folder, and logs all details
## to the logprefix given in the test folder


# Abort, if another instance of this program is already running
scriptname=$(basename "$0")
n=`ps -ef | grep "$scriptname"| grep -v grep | grep -v "$$" | wc -l`
[ "$n" -ge 1 ] && echo "$scriptname already running. Aborting" && exit 1


[[ $# -lt 2 ]] && echo "Need at least 2 arguments (test, commit). For e.g. select1 db0c96cc18aec417101e37e59fcc53d4bf647915" && exit 1

test="$1"
commit="$2"

# XXX: branches not implemented yet
branch=master

tempdel="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
basedir="$(dirname "$tempdel")"

scriptdir=${basedir}/script
logdir=${basedir}/log
historylog=${logdir}/history.log
installdir=${basedir}/stage/${branch}/install
bindir=${installdir}/bin
datadir=${installdir}/data

ts=$(p=`pwd` && cd /home/popi/proj/popi/repo/postgres && git show -s --date=format:'%Y%m%d' --format=%cd ${commit} && cd $p)
obsdir=${basedir}/obs/${test}/${ts}_${commit}

dbuser=`whoami`
dbname="test_$test"
pgbench_test_duration=10

cpu=`nproc`

testdir=${basedir}/test/${test}

defaultlogprefix="99999"
defaultport=5433
defaultparallelism=$(( ${cpu} + 1 ))

logprefix=$defaultlogprefix
port=$defaultport
parallelism=$defaultparallelism

enable_logging=1

decho() {

  # Exit early, if logging is disabled
  [[ ${enable_logging} -ne 1 ]] && exit 0

  dtformat='%Y-%m-%d %H:%M:%S'
  prefix="$dtformat: $logprefix:"
  
  echo "${scriptname} (${branch}): ${1}" | ts "$prefix" | tee -a ${historylog} 
}

GetTestDetails() {

  logprefixfile=${testdir}/logprefix
  if [[ -f ${logprefixfile} ]]; then
    logprefix=`cat ${logprefixfile}`
  else
    decho "Unable to locate logprefixfile (${logprefixfile}). Quitting."
    exit 1
  fi

  portfile=${testdir}/port
  if [[ -f ${port} ]]; then
    port=`cat ${portfile}`
  else
    echo "Unable to locate port file (${portfile}). Using default($port)"
  fi

  parallelismfile=${testdir}/parallelism
  if [[ -f ${parallelismfile} ]]; then
    parallelism=`cat ${parallelismfile}`
  else
    echo "Unable to locate parallelism file (${parallelismfile}). Using default ($parallelism)"
  fi 

  durationfile=${testdir}/duration
  if [[ -f ${durationfile} ]]; then
    pgbench_test_duration=`cat ${durationfile}`
  else
    echo "Unable to locate duration file (${durationfile}). Using default ($pgbench_test_duration)"
  fi 
}

RunPreSQL() {
  # If the test doesn't a specific pre.sql, then use an empty file.
  [[ -f "${testdir}/pre.sql" ]] && sqlfile="${testdir}/pre.sql" || sqlfile="${scriptdir}/empty.sql"

  decho "Running Pre SQL ($sqlfile)"

  # Abort, if somehow the Pre SQL doesn't exist
  [[ ! -f ${sqlfile} ]] && exit 1

  ${bindir}/psql -1f "$sqlfile" -U ${dbuser} -p ${port} $dbname 2>&1 || exit 1
}

RunPostSQL() {
  # If the test doesn't have a specific post.sql, then use an empty file.
  [[ -f "${testdir}/post.sql" ]] && sqlfile="${testdir}/post.sql" || sqlfile="${scriptdir}/empty.sql"

  decho "Running Post SQL ($sqlfile)"

  # Abort, if somehow the Post SQL doesn't exist
  [[ ! -f ${sqlfile} ]] && exit 1

  ${bindir}/psql -1f "$sqlfile" -U ${dbuser} -p ${port} $dbname 2>&1 || exit 1
}

ExecuteTestRun() {
  sqlfile="${testdir}/query.sql"

  decho "Running Test SQL ($sqlfile)"

  # Abort, if the test doesn't have query.sql
  [[ ! -f ${sqlfile} ]] && exit 1

  RunPgbenchWithFile ${parallelism} ${sqlfile} || exit 1
}


Prepare4TestRun() {
  mkdir -pv ${logdir} || exit 1
  decho "--------------------"
  decho "Start ${scriptname} Script"
  
  decho "Dropping old database ($dbname)"
  runsql "DROP DATABASE IF EXISTS $dbname;"

  decho "Creating database ($dbname)"
  runsql "CREATE DATABASE $dbname;"

  # Disable Unlogged tables for now
  unlogged=""

  Prepare4Pgbench ||  exit 1

  RunPreSQL || exit 1

  mkdir -pv ${obsdir} || exit 1
}

TeardownTestRun() {
  RunPostSQL

  decho "Stop ${scriptname} Script"
}

runsql() {
  ${bindir}/psql -tx -U ${dbuser} -p ${port} -c "${1}" postgres 2>&1 | awk NF | while IFS= read -r line
  do 
    decho "$line"; 
  done
}

function WaitTillCPUIdle {
  
  s=10 # Sleep 4 N seconds per iteration
  max="$(( `nproc` * 25 ))"
  
  while true; do
    upstr=$(uptime | grep -aob "average:" | grep -oE '[0-9]+')
    c1=$(uptime | cut -b ${upstr}- | awk '{print $2;}' | sed s/,//g)
          c=`echo $c1*100|bc`
          c=${c%.*}

    decho "Current CPU (${c}) vs Allowed threshold (${max})"
    if [[ $c -le $max ]]; then
      #decho "Condition satisfied. Continuing."
      break
    fi

    sleep $s
  done
}

Prepare4Pgbench() {
  decho "Creating pgbench tables"
  ${bindir}/pgbench -is1 -U ${dbuser} -p ${port} "$dbname"
}

RunPgbenchWithFile() {
  #1 connections
  #2 script

  conn="$1"
  script="$2"
  obslogname="c${1}T${test}D${pgbench_test_duration}"

  decho "Starting PgBench run"
  ${bindir}/pgbench -f "$script" -c${conn} -j${cpu} -P1 -p ${port} -T${pgbench_test_duration} -U ${dbuser} ${dbname} 2>&1 | tee -a ${obsdir}/${obslogname} || exit 1
  decho "Stopping PgBench run"
}

RunPgbenchIteration() {
  #1 connections
  #2 parallelthreads
  #3 is_prepared
  #4 is_select_only
  #5 is_connect_only
  #6 !!! is w - do we need this?

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

  fname="c${1}j${2}${fname}T${6}"

  ${bindir}/pgbench -n -c${1} -j${2} ${other_options} -P1 -p ${port} -T${w} -h localhost -U ${dbuser} pgbench &>${obsdir}/${fname}
}

LoopThroughPgbenchRuns() {
  w=100
  runtests=0

  if [[ $runtests -eq 1 ]]; then

    decho "Triggering pgbench"
    runsql 'SELECT now(), version();'

    for is_conn_included in 2;
    do
    for is_select_only in 1;
      do
      for is_prepared in 1;
        do
          for i in 2 ; # 3 4; # 8 12 16 32 64 ;
          do
            WaitTillCPUIdle
            decho "Iteration (\\\$i=$i) (\\\$is_conn_included=$is_conn_included) (\\\$is_select_only=$is_select_only) (\\\$is_prepared=$is_prepared) for ${w} seconds" && \
            RunPgbenchIteration $i 1 ${is_prepared} ${is_select_only} ${is_conn_included} $w
          done
        done
      done
    done
  fi
}

# Abort, if binaries are missing
[[ ! -d ${bindir} ]]        && echo "Unable to locate psql binary. Was engine compilation successful? Quitting." && exit 1

GetTestDetails || exit 1

Prepare4TestRun || exit 1

ExecuteTestRun || exit 1

TeardownTestRun || exit 1
