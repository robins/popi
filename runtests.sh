
proj=/home/robins/projects/pgbench
t=`cat ${proj}/T.txt`

if ! [[ "$t" =~ ^[0-9]$ ]]; then
        t=0
fi

bindir=/opt/postgres/pgbench
sudo -u root -H sh -c "ln -s /opt/postgres/master/bin/pgbench /opt/postgres/pgbench/bin/pgbench"
${bindir}/bin/dropdb --if-exists -U postgres pgbench
${bindir}/bin/createdb -U postgres pgbench
${bindir}/bin/pgbench -i -s8 -U postgres pgbench

projVer=${proj}/$1/$t
mkdir -p ${projVer}
cd ${projVer}
s=50
w=100

sleep $s; ${bindir}/bin/pgbench -c4 -j4 -P1 -T${w} -U postgres pgbench 				&>c4j4T100.txt
sleep $s; ${bindir}/bin/pgbench -c4 -j4 -P1 -S -T${w} -U postgres pgbench 				&>c4j4ST100.txt
sleep $s; ${bindir}/bin/pgbench -c4 -j4 -P1 -M prepared -T${w} -U postgres pgbench 			&>c4j4MT100.txt
sleep $s; ${bindir}/bin/pgbench -c4 -j4 -P1 -M prepared -S -T${w} -U postgres pgbench 		&>c4j4MST100.txt
sleep $s; ${bindir}/bin/pgbench -c4 -j4 -P1 -f ../a.sql -T${w} -U postgres pgbench 			&>c4j4FT100.txt
sleep $s; ${bindir}/bin/pgbench -c4 -j4 -P1 -f ../a.sql -S -T${w} -U postgres pgbench 		&>c4j4FST100.txt
sleep $s; ${bindir}/bin/pgbench -c4 -j4 -P1 -M prepared -f ../a.sql -T${w} -U postgres pgbench 	&>c4j4MFT100.txt
sleep $s; ${bindir}/bin/pgbench -c4 -j4 -P1 -M prepared -f ../a.sql -S -T${w} -U postgres pgbench 	&>c4j4MFST100.txt
sleep $s; ${bindir}/bin/pgbench -c4 -j4 -P1 -C -T${w} -U postgres pgbench 				&>c4j4CT100.txt
sleep $s; ${bindir}/bin/pgbench -c4 -j4 -P1 -C -S -T${w} -U postgres pgbench 			&>c4j4CST100.txt
sleep $s; ${bindir}/bin/pgbench -c4 -j4 -P1 -C -M prepared -T${w} -U postgres pgbench 		&>c4j4CMT100.txt
sleep $s; ${bindir}/bin/pgbench -c4 -j4 -P1 -C -M prepared -S -T${w} -U postgres pgbench 		&>c4j4CMST100.txt

sleep $s; ${bindir}/bin/pgbench -c8 -j4 -P1 -T${w} -U postgres pgbench 				&>c8j4T100.txt
sleep $s; ${bindir}/bin/pgbench -c8 -j4 -P1 -S -T${w} -U postgres pgbench 				&>c8j4ST100.txt
sleep $s; ${bindir}/bin/pgbench -c8 -j4 -P1 -M prepared -T${w} -U postgres pgbench 			&>c8j4MT100.txt
sleep $s; ${bindir}/bin/pgbench -c8 -j4 -P1 -M prepared -S -T${w} -U postgres pgbench 		&>c8j4MST100.txt
sleep $s; ${bindir}/bin/pgbench -c8 -j4 -P1 -f ../a.sql -T${w} -U postgres pgbench 			&>c8j4FT100.txt
sleep $s; ${bindir}/bin/pgbench -c8 -j4 -P1 -f ../a.sql -S -T${w} -U postgres pgbench 		&>c8j4FST100.txt
sleep $s; ${bindir}/bin/pgbench -c8 -j4 -P1 -M prepared -f ../a.sql -T${w} -U postgres pgbench 	&>c8j4MFT100.txt
sleep $s; ${bindir}/bin/pgbench -c8 -j4 -P1 -M prepared -f ../a.sql -S -T${w} -U postgres pgbench 	&>c8j4MFST100.txt
sleep $s; ${bindir}/bin/pgbench -c8 -j4 -P1 -C -T${w} -U postgres pgbench				&>c8j4CT100.txt
sleep $s; ${bindir}/bin/pgbench -c8 -j4 -P1 -C -S -T${w} -U postgres pgbench 			&>c8j4CST100.txt
sleep $s; ${bindir}/bin/pgbench -c8 -j4 -P1 -C -M prepared -T${w} -U postgres pgbench 		&>c8j4CMT100.txt
sleep $s; ${bindir}/bin/pgbench -c8 -j4 -P1 -C -M prepared -S -T${w} -U postgres pgbench 		&>c8j4CMST100.txt

sleep $s; ${bindir}/bin/pgbench -c64 -j4 -P1 -T${w} -U postgres pgbench 				&>c64j4T100.txt
sleep $s; ${bindir}/bin/pgbench -c64 -j4 -P1 -S -T${w} -U postgres pgbench 				&>c64j4ST100.txt
sleep $s; ${bindir}/bin/pgbench -c64 -j4 -P1 -M prepared -T${w} -U postgres pgbench 			&>c64j4MT100.txt
sleep $s; ${bindir}/bin/pgbench -c64 -j4 -P1 -M prepared -S -T${w} -U postgres pgbench 		&>c64j4MST100.txt
sleep $s; ${bindir}/bin/pgbench -c64 -j4 -P1 -f ../a.sql -T${w} -U postgres pgbench 			&>c64j4FT100.txt
sleep $s; ${bindir}/bin/pgbench -c64 -j4 -P1 -f ../a.sql -S -T${w} -U postgres pgbench 		&>c64j4FST100.txt
sleep $s; ${bindir}/bin/pgbench -c64 -j4 -P1 -M prepared -f ../a.sql -T${w} -U postgres pgbench 	&>c64j4MFT100.txt
sleep $s; ${bindir}/bin/pgbench -c64 -j4 -P1 -M prepared -f ../a.sql -S -T${w} -U postgres pgbench 	&>c64j4MFST100.txt
sleep $s; ${bindir}/bin/pgbench -c64 -j4 -P1 -C -T${w} -U postgres pgbench 				&>c64j4CT100.txt
sleep $s; ${bindir}/bin/pgbench -c64 -j4 -P1 -C -S -T${w} -U postgres pgbench 			&>c64j4CST100.txt
sleep $s; ${bindir}/bin/pgbench -c64 -j4 -P1 -C -M prepared -T${w} -U postgres pgbench 		&>c64j4CMT100.txt
sleep $s; ${bindir}/bin/pgbench -c64 -j4 -P1 -C -M prepared -S -T${w} -U postgres pgbench 		&>c64j4CMST100.txt

${bindir}/bin/psql -U postgres -c 'SELECT version();' postgres 					> version.txt

echo $((($t + 1) % 10)) > ${proj}/T.txt 
