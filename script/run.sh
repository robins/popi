# lock the script so only one runs at a time
#exec 200<$0
#flock -n 200 || exit 1

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
logdir=${basedir}/log/${2}

stagedir=${basedir}/stage/${2}
installdir=${stagedir}/install
bindir=${installdir}/bin
datadir=${installdir}/data

hash=${3}
enable_logging=1

log() {
        if [[ ${enable_logging} -eq 1 ]]; then
                echo ${1}
        fi
}

#check_if_db_down() {
# if  `ps -ef | grep postgres | 
#}

cd ${srcdir}
log "Starting Script" && \
	git checkout ${1} && \
	git checkout ${hash} . && \
	git pull && \
#	Only required if this is a new git repo
	./configure --prefix=${installdir} --enable-depend --with-pgport=${port} && \
	${bindir}/pg_ctl -D ${datadir} stop


cd ${stagedir}/ && \
	rm -rf install/data

make -j4 install && \
	${bindir}/initdb -D ${datadir} && \
	#Wait 5 seconds. We don't want tests to fail because the IO couldnt keep up with recent DB start
	sleep 5 && \
	echo "cluster_name='popi${2}'" >> ${datadir}/postgresql.conf && \
	echo "listen_addresses='127.0.0.1'" >> ${datadir}/postgresql.conf && \
        ${bindir}/pg_ctl -D ${datadir} -l ${logdir}/logfile_master.txt start && \
	sleep 5


#Stop old instance before installing new version
#sudo -u postgres -H sh -c "/bin/bash ${scriptdir}/pg_stop.sh ${2} ${port}"
#pg_stop
#/bin/bash ${scriptdir}/pg_stop.sh ${2} ${port}
#sudo make -j4 install
#sudo -u postgres -H sh -c "/bin/bash ${scriptdir}/pg_start.sh ${2} ${3}"
#/bin/bash ${scriptdir}/pg_start.sh ${2} ${port}
#pg_start


log "Setup done. Next calling RunTests to actually trigger the tests"
bash ${scriptdir}/runtests.sh ${2} ${port} ${hash} &>${logdir}/runtests.log
