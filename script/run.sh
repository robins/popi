# lock the script so only one runs at a time
exec 200<$0
flock -n 200 || exit 1

# $1=branch
# $2=folder
# $3=port

basedir=/home/pi/projects/popi
srcdir=${basedir}/repo
scriptdir=${basedir}/script
logdir=/opt/postgres/log/${2}
installdir=/opt/postgres/${2}
bindir=${installdir}/bin

cd ${srcdir}
git checkout ${1} && \
	git pull && \
#	make -j4 clean && \
#	./configure --prefix=${bindir} --enable-depend --with-pgport=${3} && \
	make -j4

#Before installing new PG version, we need to ensure that the old PG has been stopped
sudo -u postgres -H sh -c "/bin/bash ${scriptdir}/pg_stop.sh ${2} ${3}"
sudo make -j4 install
sudo -u postgres -H sh -c "/bin/bash ${scriptdir}/pg_start.sh ${2} ${3}"


#Wait some time. We don't want tests to fail because the IO couldnt keep up with recent DB start
sleep 10

bash ${scriptdir}/runtests.sh $2 &>${logdir}/runtests.log
