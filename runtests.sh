/opt/postgres/master/bin/dropdb --if-exists -U postgres pgbench
/opt/postgres/master/bin/createdb -U postgres pgbench
/opt/postgres/master/bin/pgbench -i -s8 -U postgres pgbench

proj=/home/robins/projects/pgbench
t=`cat ${proj}/T.txt`

projVer=${proj}/$1/$t
mkdir -p ${projVer}
cd ${projVer}
s=30

sleep $s; /opt/postgres/master/bin/pgbench -c4 -j4 -P1 -T100 -U postgres pgbench 				&>c4j4T100.txt
sleep $s; /opt/postgres/master/bin/pgbench -c4 -j4 -P1 -S -T100 -U postgres pgbench 				&>c4j4ST100.txt
sleep $s; /opt/postgres/master/bin/pgbench -c4 -j4 -P1 -M prepared -T100 -U postgres pgbench 			&>c4j4MT100.txt
sleep $s; /opt/postgres/master/bin/pgbench -c4 -j4 -P1 -M prepared -S -T100 -U postgres pgbench 		&>c4j4MST100.txt
sleep $s; /opt/postgres/master/bin/pgbench -c4 -j4 -P1 -f ../a.sql -T100 -U postgres pgbench 			&>c4j4FT100.txt
sleep $s; /opt/postgres/master/bin/pgbench -c4 -j4 -P1 -f ../a.sql -S -T100 -U postgres pgbench 		&>c4j4FST100.txt
sleep $s; /opt/postgres/master/bin/pgbench -c4 -j4 -P1 -M prepared -f ../a.sql -T100 -U postgres pgbench 	&>c4j4MFT100.txt
sleep $s; /opt/postgres/master/bin/pgbench -c4 -j4 -P1 -M prepared -f ../a.sql -S -T100 -U postgres pgbench 	&>c4j4MFST100.txt
sleep $s; /opt/postgres/master/bin/pgbench -c4 -j4 -P1 -C -T100 -U postgres pgbench 				&>c4j4CT100.txt
sleep $s; /opt/postgres/master/bin/pgbench -c4 -j4 -P1 -C -S -T100 -U postgres pgbench 				&>c4j4CST100.txt
sleep $s; /opt/postgres/master/bin/pgbench -c4 -j4 -P1 -C -M prepared -T100 -U postgres pgbench 		&>c4j4CMT100.txt
sleep $s; /opt/postgres/master/bin/pgbench -c4 -j4 -P1 -C -M prepared -S -T100 -U postgres pgbench 		&>c4j4CMST100.txt

sleep $s; /opt/postgres/master/bin/pgbench -c8 -j4 -P1 -T100 -U postgres pgbench 				&>c8j4T100.txt
sleep $s; /opt/postgres/master/bin/pgbench -c8 -j4 -P1 -S -T100 -U postgres pgbench 				&>c8j4ST100.txt
sleep $s; /opt/postgres/master/bin/pgbench -c8 -j4 -P1 -M prepared -T100 -U postgres pgbench 			&>c8j4MT100.txt
sleep $s; /opt/postgres/master/bin/pgbench -c8 -j4 -P1 -M prepared -S -T100 -U postgres pgbench 		&>c8j4MST100.txt
sleep $s; /opt/postgres/master/bin/pgbench -c8 -j4 -P1 -f ../a.sql -T100 -U postgres pgbench 			&>c8j4FT100.txt
sleep $s; /opt/postgres/master/bin/pgbench -c8 -j4 -P1 -f ../a.sql -S -T100 -U postgres pgbench 		&>c8j4FST100.txt
sleep $s; /opt/postgres/master/bin/pgbench -c8 -j4 -P1 -M prepared -f ../a.sql -T100 -U postgres pgbench 	&>c8j4MFT100.txt
sleep $s; /opt/postgres/master/bin/pgbench -c8 -j4 -P1 -M prepared -f ../a.sql -S -T100 -U postgres pgbench 	&>c8j4MFST100.txt
sleep $s; /opt/postgres/master/bin/pgbench -c8 -j4 -P1 -C -T100 -U postgres pgbench				&>c8j4CT100.txt
sleep $s; /opt/postgres/master/bin/pgbench -c8 -j4 -P1 -C -S -T100 -U postgres pgbench 				&>c8j4CST100.txt
sleep $s; /opt/postgres/master/bin/pgbench -c8 -j4 -P1 -C -M prepared -T100 -U postgres pgbench 		&>c8j4CMT100.txt
sleep $s; /opt/postgres/master/bin/pgbench -c8 -j4 -P1 -C -M prepared -S -T100 -U postgres pgbench 		&>c8j4CMST100.txt

sleep $s; /opt/postgres/master/bin/pgbench -c64 -j4 -P1 -T100 -U postgres pgbench 				&>c64j4T100.txt
sleep $s; /opt/postgres/master/bin/pgbench -c64 -j4 -P1 -S -T100 -U postgres pgbench 				&>c64j4ST100.txt
sleep $s; /opt/postgres/master/bin/pgbench -c64 -j4 -P1 -M prepared -T100 -U postgres pgbench 			&>c64j4MT100.txt
sleep $s; /opt/postgres/master/bin/pgbench -c64 -j4 -P1 -M prepared -S -T100 -U postgres pgbench 		&>c64j4MST100.txt
sleep $s; /opt/postgres/master/bin/pgbench -c64 -j4 -P1 -f ../a.sql -T100 -U postgres pgbench 			&>c64j4FT100.txt
sleep $s; /opt/postgres/master/bin/pgbench -c64 -j4 -P1 -f ../a.sql -S -T100 -U postgres pgbench 		&>c64j4FST100.txt
sleep $s; /opt/postgres/master/bin/pgbench -c64 -j4 -P1 -M prepared -f ../a.sql -T100 -U postgres pgbench 	&>c64j4MFT100.txt
sleep $s; /opt/postgres/master/bin/pgbench -c64 -j4 -P1 -M prepared -f ../a.sql -S -T100 -U postgres pgbench 	&>c64j4MFST100.txt
sleep $s; /opt/postgres/master/bin/pgbench -c64 -j4 -P1 -C -T100 -U postgres pgbench 				&>c64j4CT100.txt
sleep $s; /opt/postgres/master/bin/pgbench -c64 -j4 -P1 -C -S -T100 -U postgres pgbench 			&>c64j4CST100.txt
sleep $s; /opt/postgres/master/bin/pgbench -c64 -j4 -P1 -C -M prepared -T100 -U postgres pgbench 		&>c64j4CMT100.txt
sleep $s; /opt/postgres/master/bin/pgbench -c64 -j4 -P1 -C -M prepared -S -T100 -U postgres pgbench 		&>c64j4CMST100.txt

/opt/postgres/master/bin/psql -U postgres -c 'SELECT version();' postgres 					> version.txt
