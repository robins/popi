# lock the script so only one runs at a time
exec 200<$0
flock -n 200 || exit 1

# $1=branch
# $2=folder

port=5432 #Currently we are not geared towards changing port

basedir=/home/pi/projects/popi
srcdir=${basedir}/repo
scriptdir=${basedir}/script
logdir=${basedir}/log/${2}
installdir=${basedir}/stage/${2}/install
bindir=${installdir}/bin
datadir=${installdir}/data

pg_stop () {
	echo $bindir
	${bindir}/pg_ctl -D ${datadir} stop
}

pg_start () {
        echo $bindir
        ${bindir}/pg_ctl -D ${datadir} start
}


cd ${srcdir}
git checkout ${1} && \
	git pull && \
	make -j4 clean && \
	./configure --prefix=${installdir} --enable-depend --with-pgport=${port} && \
	make -j4 && \
	pg_stop  && \
	make -j4 install && \
	pg_start


#Stop old instance before installing new version
#sudo -u postgres -H sh -c "/bin/bash ${scriptdir}/pg_stop.sh ${2} ${port}"
#pg_stop
#/bin/bash ${scriptdir}/pg_stop.sh ${2} ${port}
#sudo make -j4 install
#sudo -u postgres -H sh -c "/bin/bash ${scriptdir}/pg_start.sh ${2} ${3}"
#/bin/bash ${scriptdir}/pg_start.sh ${2} ${port}
#pg_start
exit 1

#Wait 5 seconds. We don't want tests to fail because the IO couldnt keep up with recent DB start
sleep 5

bash ${scriptdir}/runtests.sh $2 &>${logdir}/runtests.log
