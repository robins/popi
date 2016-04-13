#XXX: Pause this script if first of the CPU ratios is beyond 0.1 

#XXX: See what needs to be done for minor version change. Keep non-cycling T means the results would be broken in minor version numbers.
#     irrespective of whether we eventually cycle T or not, we should be resetting the non-matching versions first, when re-running

# lock the script so only one runs at a time
exec 200<$0
flock -n 200 || exit 1

proj=/home/robins/projects/pgbench
t=`cat ${proj}/$1/T.txt`

if ! [[ "$t" =~ ^[0-9]$ ]]; then
  t=0
fi

port=9999
bindir=/opt/postgres/pgbench
sudo -u root -H sh -c "ln -s /opt/postgres/master/bin/pgbench /opt/postgres/pgbench/bin/pgbench"
${bindir}/bin/dropdb -U postgres -p ${port} pgbench  # old pg versions didnt understand --if-exists and fail
${bindir}/bin/createdb -U postgres -p ${port} pgbench
${bindir}/bin/pgbench -i -s8 -U postgres -p ${port} pgbench


q=${proj}/a.sql
projVer=${proj}/$1/$t
mkdir -p ${projVer}
cd ${projVer}
s=50
w=100
runtests=1
runversion=1

echo "Runtest: Triggering battery of tests T=${t}" >> /home/robins/pgbench/log/history.log

function waitnwatch {
while true; do
  c1=$(uptime | awk '{print $10}' | sed s/,//g)
        c=`echo $c1*100|bc`
        c=${c%.*}

  if [[ $c -le 10 ]]; then
    break
  fi

  echo "Waiting for idle CPU. Currently (${c1})"
  sleep $s
done
}

if [ $runtests -eq 1 ]; then

  waitnwatch; ${bindir}/bin/pgbench -c4 -j4 -P1 -p ${port}                           -T${w} -U postgres pgbench &>c4j4T100.txt
  sleep $s; ${bindir}/bin/pgbench -c4 -j4 -P1 -p ${port}                        -S -T${w} -U postgres pgbench &>c4j4ST100.txt
  sleep $s; ${bindir}/bin/pgbench -c4 -j4 -P1 -p ${port}    -M prepared            -T${w} -U postgres pgbench &>c4j4MT100.txt
  sleep $s; ${bindir}/bin/pgbench -c4 -j4 -P1 -p ${port}    -M prepared         -S -T${w} -U postgres pgbench &>c4j4MST100.txt
  sleep $s; ${bindir}/bin/pgbench -c4 -j4 -P1 -p ${port}                -f ${q}    -T${w} -U postgres pgbench &>c4j4FT100.txt
  sleep $s; ${bindir}/bin/pgbench -c4 -j4 -P1 -p ${port}                -f ${q} -S -T${w} -U postgres pgbench &>c4j4FST100.txt
  sleep $s; ${bindir}/bin/pgbench -c4 -j4 -P1 -p ${port}    -M prepared -f ${q}    -T${w} -U postgres pgbench &>c4j4MFT100.txt
  sleep $s; ${bindir}/bin/pgbench -c4 -j4 -P1 -p ${port}    -M prepared -f ${q} -S -T${w} -U postgres pgbench &>c4j4MFST100.txt
  sleep $s; ${bindir}/bin/pgbench -c4 -j4 -P1 -p ${port} -C                        -T${w} -U postgres pgbench &>c4j4CT100.txt
  sleep $s; ${bindir}/bin/pgbench -c4 -j4 -P1 -p ${port} -C                     -S -T${w} -U postgres pgbench &>c4j4CST100.txt
  sleep $s; ${bindir}/bin/pgbench -c4 -j4 -P1 -p ${port} -C -M prepared            -T${w} -U postgres pgbench &>c4j4CMT100.txt
  sleep $s; ${bindir}/bin/pgbench -c4 -j4 -P1 -p ${port} -C -M prepared         -S -T${w} -U postgres pgbench &>c4j4CMST100.txt

  sleep $s; ${bindir}/bin/pgbench -c8 -j4 -P1 -p ${port}                           -T${w} -U postgres pgbench &>c8j4T100.txt
  sleep $s; ${bindir}/bin/pgbench -c8 -j4 -P1 -p ${port}                        -S -T${w} -U postgres pgbench &>c8j4ST100.txt
  sleep $s; ${bindir}/bin/pgbench -c8 -j4 -P1 -p ${port}    -M prepared            -T${w} -U postgres pgbench &>c8j4MT100.txt
  sleep $s; ${bindir}/bin/pgbench -c8 -j4 -P1 -p ${port}    -M prepared         -S -T${w} -U postgres pgbench &>c8j4MST100.txt
  sleep $s; ${bindir}/bin/pgbench -c8 -j4 -P1 -p ${port}                -f ${q}    -T${w} -U postgres pgbench &>c8j4FT100.txt
  sleep $s; ${bindir}/bin/pgbench -c8 -j4 -P1 -p ${port}                -f ${q} -S -T${w} -U postgres pgbench &>c8j4FST100.txt
  sleep $s; ${bindir}/bin/pgbench -c8 -j4 -P1 -p ${port}    -M prepared -f ${q}    -T${w} -U postgres pgbench &>c8j4MFT100.txt
  sleep $s; ${bindir}/bin/pgbench -c8 -j4 -P1 -p ${port}    -M prepared -f ${q} -S -T${w} -U postgres pgbench &>c8j4MFST100.txt
  sleep $s; ${bindir}/bin/pgbench -c8 -j4 -P1 -p ${port} -C                        -T${w} -U postgres pgbench &>c8j4CT100.txt
  sleep $s; ${bindir}/bin/pgbench -c8 -j4 -P1 -p ${port} -C                     -S -T${w} -U postgres pgbench &>c8j4CST100.txt
  sleep $s; ${bindir}/bin/pgbench -c8 -j4 -P1 -p ${port} -C -M prepared            -T${w} -U postgres pgbench &>c8j4CMT100.txt
  sleep $s; ${bindir}/bin/pgbench -c8 -j4 -P1 -p ${port} -C -M prepared         -S -T${w} -U postgres pgbench &>c8j4CMST100.txt

  sleep $s; ${bindir}/bin/pgbench -c64 -j4 -P1 -p ${port}                           -T${w} -U postgres pgbench &>c64j4T100.txt
  sleep $s; ${bindir}/bin/pgbench -c64 -j4 -P1 -p ${port}                        -S -T${w} -U postgres pgbench &>c64j4ST100.txt
  sleep $s; ${bindir}/bin/pgbench -c64 -j4 -P1 -p ${port}    -M prepared            -T${w} -U postgres pgbench &>c64j4MT100.txt
  sleep $s; ${bindir}/bin/pgbench -c64 -j4 -P1 -p ${port}    -M prepared         -S -T${w} -U postgres pgbench &>c64j4MST100.txt
  sleep $s; ${bindir}/bin/pgbench -c64 -j4 -P1 -p ${port}                -f ${q}    -T${w} -U postgres pgbench &>c64j4FT100.txt
  sleep $s; ${bindir}/bin/pgbench -c64 -j4 -P1 -p ${port}                -f ${q} -S -T${w} -U postgres pgbench &>c64j4FST100.txt
  sleep $s; ${bindir}/bin/pgbench -c64 -j4 -P1 -p ${port}    -M prepared -f ${q}    -T${w} -U postgres pgbench &>c64j4MFT100.txt
  sleep $s; ${bindir}/bin/pgbench -c64 -j4 -P1 -p ${port}    -M prepared -f ${q} -S -T${w} -U postgres pgbench &>c64j4MFST100.txt
  sleep $s; ${bindir}/bin/pgbench -c64 -j4 -P1 -p ${port} -C                        -T${w} -U postgres pgbench &>c64j4CT100.txt
  sleep $s; ${bindir}/bin/pgbench -c64 -j4 -P1 -p ${port} -C                     -S -T${w} -U postgres pgbench &>c64j4CST100.txt
  sleep $s; ${bindir}/bin/pgbench -c64 -j4 -P1 -p ${port} -C -M prepared            -T${w} -U postgres pgbench &>c64j4CMT100.txt
  sleep $s; ${bindir}/bin/pgbench -c64 -j4 -P1 -p ${port} -C -M prepared         -S -T${w} -U postgres pgbench &>c64j4CMST100.txt

fi

if [ $runversion -eq 1 ]; then
  ${bindir}/bin/psql -U postgres -p ${port} -c 'SELECT version();' postgres           > version.txt
fi

#echo $((($t + 1) % 10)) > ${proj}/$1/T.txt 
echo $(($t + 1)) > ${proj}/$1/T.txt 
