cd /home/robins/projects/pg
git checkout $1
git pull
./configure --prefix=/opt/postgres/pgbench --enable-depend --with-pgport=${3}
make clean 
make -j4
sudo -u root -H sh -c "make install"
sudo -u postgres -H sh -c "/bin/bash /home/postgres/reload_pg.sh pgbench ${3}"
sleep 10

bash /home/robins/projects/pgbench/runtests.sh $2
bash /home/robins/projects/pgbench/runtests.sh $2
bash /home/robins/projects/pgbench/runtests.sh $2
bash /home/robins/projects/pgbench/runtests.sh $2
bash /home/robins/projects/pgbench/runtests.sh $2
bash /home/robins/projects/pgbench/runtests.sh $2
bash /home/robins/projects/pgbench/runtests.sh $2
bash /home/robins/projects/pgbench/runtests.sh $2
bash /home/robins/projects/pgbench/runtests.sh $2
bash /home/robins/projects/pgbench/runtests.sh $2
