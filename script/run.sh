# lock the script so only one runs at a time
exec 200<$0
flock -n 200 || exit 1

cd /home/robins/projects/pg/${2}/
git checkout $1
git pull
make -j4 clean 
./configure --prefix=/opt/postgres/${2} --enable-depend --with-pgport=${3}
make -j4

#Before installing new PG version, we need to ensure that the old PG has been stopped
sudo -u postgres -H sh -c "/bin/bash /home/robins/projects/popi/script/pg_stop.sh ${2} ${3}"
sudo -u root -H sh -c "make -j4 install"
sudo -u postgres -H sh -c "/bin/bash /home/robins/projects/popi/script/pg_start.sh ${2} ${3}"


#Wait some time. We don't want tests to fail because the IO couldnt keep up with recent DB start
sleep 10

bash /home/robins/projects/popi/script/runtests.sh $2 &>/home/robins/projects/popi/log/runtests.log
