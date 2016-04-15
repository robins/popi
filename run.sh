# lock the script so only one runs at a time
exec 200<$0
flock -n 200 || exit 1

cd /home/robins/projects/pg/${2}/
#git checkout $1
git pull
#./configure --prefix=/opt/postgres/pgbench --enable-depend --with-pgport=${3}
#make clean 
make -j4

#Before installing new PG version, we need to ensure that the old PG has been stopped
sudo -u postgres -H sh -c "/bin/bash /home/robins/projects/pgbench/pg_stop.sh pgbench ${3}"
sudo -u root -H sh -c "make install"
sudo -u postgres -H sh -c "/bin/bash /home/robins/projects/pgbench/pg_start.sh pgbench ${3}"

bash /home/robins/projects/pgbench/runtests.sh $2 &>/home/robins/projects/pgbench/log/runtests.log
