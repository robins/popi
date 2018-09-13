# lock the script so only one runs at a time
exec 200<$0
flock -n 200 || exit 1

# $1=branch
# $2=folder

if (( $# < 2 )); then
echo "Need at least 2 arguments (branch folder). For e.g. master master"
exit 1
fi

port=5433 #Currently we are not geared towards changing port

basedir=/home/pi/projects/popi
srcdir=${basedir}/repo
scriptdir=${basedir}/script
logdir=${basedir}/log/${2}
installdir=${basedir}/stage/${2}/install
bindir=${installdir}/bin
datadir=${installdir}/data

cd ${srcdir}
echo "Starting Script" && \
	git checkout ${1} && \
	git pull && \
#	Only required if this is a new git repo
	./configure --prefix=${installdir} --enable-depend --with-pgport=${port} && \
#	${bindir}/pg_ctl -D ${datadir} stop && \
	make -j4 install && \
	cd /home/pi/projects/popi/stage/master/ && \
	rm -rf install/data && \
	${bindir}/initdb -D ${datadir} && \
        ${bindir}/pg_ctl -D ${datadir} start && \
	#Wait 5 seconds. We don't want tests to fail because the IO couldnt keep up with recent DB start
	sleep 5 && \
	echo "DB Started" && \
	exit 1


#Stop old instance before installing new version
#sudo -u postgres -H sh -c "/bin/bash ${scriptdir}/pg_stop.sh ${2} ${port}"
#pg_stop
#/bin/bash ${scriptdir}/pg_stop.sh ${2} ${port}
#sudo make -j4 install
#sudo -u postgres -H sh -c "/bin/bash ${scriptdir}/pg_start.sh ${2} ${3}"
#/bin/bash ${scriptdir}/pg_start.sh ${2} ${port}
#pg_start


bash ${scriptdir}/runtests.sh $2 &>${logdir}/runtests.log
