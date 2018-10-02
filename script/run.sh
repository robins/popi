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

basedir=/home/pi/projects/popi
srcdir=${basedir}/repo
scriptdir=${basedir}/script
logdir=${basedir}/log
historylog=$logdir/history.log

stagedir=${basedir}/stage/${2}
installdir=${stagedir}/install
bindir=${installdir}/bin
datadir=${installdir}/data

hash=${3}
branch=${1}
enable_logging=1

log() {
  if [[ ${enable_logging} -eq 1 ]]; then
    dt=`date '+%Y-%m-%d %H:%M:%S'`
    echo "${dt}: ${1}"
  fi
}

logh() {
  log "Run (${branch}): ${1}" >> ${historylog}
}

startScript() {
    mkdir -p ${logdir}
    logh "=== Start Run Script ==="
}

teardown() {

pkill -o "postgres"

if [ -d "${datadir}" ]; then
  logh "Removing previous data folder, if any" && \
    cd ${stagedir}/ && \
    rm -rf install/data
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
    q2=${basedir}/catalog/q2
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

cd ${srcdir}
logh "Checkout commit" && \
	git checkout ${1} && \
	git checkout ${hash} .
#	Only required if this is a new git repo

teardown

if [ ${port} -ne 5433 ]; then
  logh "Configuring Postgres (Since port seems to have changed)" && \
  ./configure --prefix=${installdir} --enable-depend --with-pgport=${port}
fi

all_success=0

logh "Compiling Postgres"
#make --silent -j4 clean && \
	make --silent -j4 install && \
	${bindir}/initdb --nosync -D ${datadir} && \
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

if [ $all_success -eq 0 ]; then
	appendCommitToQ2 ${hash}
	stopScript 1
fi

stopScript 0
