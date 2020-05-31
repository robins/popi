# lock the script so only one runs at a time
exec 200<$0
flock -n 200 || exit 1

# $1=branch
# $2=folder
# $3=hash

if (( $# < 3 )); then
echo "Need at least 3 arguments (branch folder hash). For e.g. master master 14ea36520389dbb1b48524223cf09389154a0f2e"
exit 1
fi

port=5433 #Currently we are not geared towards changing port

tempdel="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
basedir="$(dirname "$tempdel")"

srcdir=${basedir}/repo/postgres
scriptdir=${basedir}/script
logdir=${basedir}/log
historylog=$logdir/history.log

stagedir=${basedir}/stage/${2}
installdir=${stagedir}/install
bindir=${installdir}/bin
datadir=${installdir}/data

logprefixfile=${scriptdir}/logprefix
touch ${logprefixfile}

catalogdir=${basedir}/catalog
q2=${catalogdir}/q2

hash=${3}
branch=${1}
enable_logging=1
needconfigure=0

log() {
  if [[ ${enable_logging} -eq 1 ]]; then
    dt=`date '+%Y-%m-%d %H:%M:%S'`
    echo "${dt}: "`cat ${logprefixfile}`" :${1}"
  fi
}

logh() {
  log "Run (${branch}): ${1}" >> ${historylog}
}

checkIsRepoDirOkay() {
    if [ -f ${srcdir}/README ]; then
        #Postgres repo already exists
        return 0
    fi
    return 1
}

startScript() {
    mkdir -p ${logdir}
    logh "=== Start Run Script ==="

    mkdir -p ${catalogdir}
    touch ${q2}
}

teardown() {

pkill -o "postgres"

if [ -d "${datadir}" ]; then
  logh "Removing previous data folder, if any" && \
    cd ${stagedir}/ && \
    rm -rf ${stagedir}/install/data
fi
}

stopScript() {
    logh "--- Stop Run Script ---"
        teardown
        exit ${1}
}

isHashAlreadyProcessed() {
        resultdir=${basedir}/obs/${branch}/${hash}
        if [ -d "${resultdir}" ]; then
                logh "Looks like we've already processed this Hash. Skipping"
                stopScript 0
        fi
}

appendCommitToQ2() {
    logh "Attempting to push commit (${hash}) to Q2"
    if [ `grep ${1} ${q2}| wc -l` -eq 0 ]; then
        echo ${1} >> ${q2}
    else
        logh "Possibly commit ${1} already exists in Q2"
    fi
}

isPostgresUp() {
        while :
        do
                if [ `ps -ef | grep "postgres" | grep "popi" | wc -l` -gt 0 ]; then
                        break
                fi
                sleep 1
        done
}

#check_if_db_down() {
# if  `ps -ef | grep postgres |
#}

startScript

isHashAlreadyProcessed

if [ ! -d ${srcdir} ]
then
        logh "Need to clone Git repo first"
        mkdir -p ${srcdir}
        cd ${srcdir}
        git clone https://github.com/postgres/postgres.git .
        needconfigure=1
else
        cd ${srcdir}
        logh "Checkout repo (at dir ${srcdir})" && \
                git checkout ${1} && \
                git checkout ${hash} .
fi

teardown

#if [ ${port} -ne 5433 ]; then
#       make distclean
#       nice -n 19 ./configure --prefix=${installdir} --enable-depend --enable-cassert --with-pgport=${port}
#fi

all_success=0

if ! $(checkIsRepoDirOkay) ; then
        logh "Something wrong with Repo Dir. Exiting" 1
        exit 1
fi



logh "Git reset" && \
        nice -n 19 git reset --hard &>> /dev/null && \
        logh "Cleaning up"
        nice -n 19 make --silent -j4 clean
        logh "Running Configure"
        nice -n 19 ./configure --prefix=${installdir} --enable-cassert --enable-depend --with-pgport=${port} >> /dev/null
        logh "Compiling Postgres" && \
        nice -n 19 make --silent -j4 install &>> /dev/null && \
        logh "Starting up Database" && \
        nice -n 19 ${bindir}/initdb --nosync -D ${datadir} && \
        #Wait 5 seconds. We don't want tests to fail because the IO couldnt keep up with recent DB start
        sleep 5 && \
        echo "cluster_name='popi${2}'" >> ${datadir}/postgresql.conf && \
        echo "listen_addresses='127.0.0.1'" >> ${datadir}/postgresql.conf && \
        logh "Starting Postgres" && \
        ${bindir}/pg_ctl -D ${datadir} -l ${logdir}/logfile_master.txt start && \
        isPostgresUp && \
                logh "Calling RunTest" && \
                        bash ${scriptdir}/runtests.sh ${2} ${port} ${hash} &>>${historylog} && \
                        all_success=1

logh "Successfuly processed Commit: ${hash}"

if [ $all_success -eq 0 ]; then
        appendCommitToQ2 ${hash}
        stopScript 1
fi

stopScript 0
