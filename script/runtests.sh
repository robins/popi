#XXX: Per docs, we should be doing at least a pgbench -i s4 for a 4 connection test

#XXX: See what needs to be done for minor version change. Keep non-cycling T means the results would be broken in minor version numbers.
#     irrespective of whether we eventually cycle T or not, we should be resetting the non-matching versions first, when re-running

# lock the script so only one runs at a time
exec 200<$0
flock -n 200 || exit 1

#XXX: See that no places use hardwired folder paths
basedir=/home/pi/projects/popi
scriptdir=${basedir}/script
obsdir=${basedir}/obs/${1}

#1=folder

port=9999
bindir=/opt/postgres/master/bin
logdir=${basedir}/log/${1}

#This is a hack that get pgbench working for old branches.
#/postgres/master is outside this repo, but its (effectively) a static binary that we could link with here
#rm -f /opt/postgres/${1}/bin/pgbench
#sudo -u root -H sh -c ln -s /opt/postgres/pgbench /opt/postgres/${1}/bin/pgbench"

# Can't do a --if-exists here, since old pg versions dont understand and bail, which is not what we want
${bindir}/dropdb -U postgres -p ${port} pgbench &>/dev/null

${bindir}/createdb -U postgres -p ${port} pgbench

# Disable Unlogged tables for now
unlogged=""

${bindir}/pgbench -i s8 -U postgres -p ${port} pgbench
${bindir}/psql -1f ${scriptdir}/pre.sql ${unlogged} -U postgres -p ${port} pgbench

if [[ ${1} -eq "master" ]]; then
	${bindir}/bin/psql -c 'SET max_parallel_processes=4;' -U postgres -p ${port} pgbench
fi

q=${scriptdir}/a.sql
s=1
w=10
runtests=1


function waitnwatch {
  max=100
  while true; do
    upstr=$(uptime | grep -aob "average:" | grep -oE '[0-9]+')
    c1=$(uptime | cut -b ${upstr}- | awk '{print $2;}' | sed s/,//g)
          c=`echo $c1*100|bc`
          c=${c%.*}

    echo "Current CPU (${c}) vs Allowed threshold (${max})"
    if [[ $c -le $max ]]; then
      echo "Proceeding"
      break
    fi

    date
    sleep $s
  done
}

#XXX Instead of looping, which is temporary. Create a logic that checks which (of 0-9) needs to be refreshed and randomize between them, if multiple candidates found
for t in `seq 0 0`;
do

  echo "Runtest: Triggering battery of tests T=${t}" >> ${logdir}/history.log
  mkdir -p ${obsdir}/${t}
  cd ${obsdir}/${t}

if [ $runtests -eq 1 ]; then

  echo "Runtest: Triggering pgbench instance at (`pwd`)" >> ${logdir}/history.log

  waitnwatch; ${bindir}/pgbench -n -c1 -j1 -P1 -p ${port}                -f ${q}    -T${w} -U postgres pgbench &>${logdir}/c1j1FT${w}.txt
  #waitnwatch; ${bindir}/bin/pgbench -n -c2 -j2 -P1 -p ${port}                -f ${q}    -T${w} -U postgres pgbench &>c2j2FT${w}.txt
  #waitnwatch; ${bindir}/bin/pgbench -n -c3 -j3 -P1 -p ${port}                -f ${q}    -T${w} -U postgres pgbench &>c3j3FT${w}.txt
  #waitnwatch; ${bindir}/bin/pgbench -n -c4 -j4 -P1 -p ${port}                -f ${q}    -T${w} -U postgres pgbench &>c4j4FT${w}.txt

  #waitnwatch; ${bindir}/bin/pgbench -c2 -j4 -P1 -p ${port}                -f ${q}    -T${w} -U postgres pgbench &>c2j4FT100.txt
  #waitnwatch; ${bindir}/bin/pgbench -c2 -j4 -P1 -p ${port}    -M prepared -f ${q}    -T${w} -U postgres pgbench &>c2j4MFT100.txt

  #waitnwatch; ${bindir}/bin/pgbench -c3 -j4 -P1 -p ${port}                -f ${q}    -T${w} -U postgres pgbench &>c3j4FT100.txt
  #waitnwatch; ${bindir}/bin/pgbench -c3 -j4 -P1 -p ${port}    -M prepared -f ${q}    -T${w} -U postgres pgbench &>c3j4MFT100.txt

  #waitnwatch; ${bindir}/bin/pgbench -c4 -j4 -P1 -p ${port}                           -T${w} -U postgres pgbench &>c4j4T100.txt
  #waitnwatch; ${bindir}/bin/pgbench -c4 -j4 -P1 -p ${port}                        -S -T${w} -U postgres pgbench &>c4j4ST100.txt
  #waitnwatch; ${bindir}/bin/pgbench -c4 -j4 -P1 -p ${port}    -M prepared            -T${w} -U postgres pgbench &>c4j4MT100.txt
  #waitnwatch; ${bindir}/bin/pgbench -c4 -j4 -P1 -p ${port}    -M prepared         -S -T${w} -U postgres pgbench &>c4j4MST100.txt
  #waitnwatch; ${bindir}/bin/pgbench -c4 -j4 -P1 -p ${port}                -f ${q}    -T${w} -U postgres pgbench &>c4j4FT100.txt
  #waitnwatch; ${bindir}/bin/pgbench -c4 -j4 -P1 -p ${port}                -f ${q} -S -T${w} -U postgres pgbench &>c4j4FST100.txt
  #waitnwatch; ${bindir}/bin/pgbench -c4 -j4 -P1 -p ${port}    -M prepared -f ${q}    -T${w} -U postgres pgbench &>c4j4MFT100.txt
  #waitnwatch; ${bindir}/bin/pgbench -c4 -j4 -P1 -p ${port}    -M prepared -f ${q} -S -T${w} -U postgres pgbench &>c4j4MFST100.txt
  #waitnwatch; ${bindir}/bin/pgbench -c4 -j4 -P1 -p ${port} -C                        -T${w} -U postgres pgbench &>c4j4CT100.txt
  #waitnwatch; ${bindir}/bin/pgbench -c4 -j4 -P1 -p ${port} -C                     -S -T${w} -U postgres pgbench &>c4j4CST100.txt
  #waitnwatch; ${bindir}/bin/pgbench -c4 -j4 -P1 -p ${port} -C -M prepared            -T${w} -U postgres pgbench &>c4j4CMT100.txt
  #waitnwatch; ${bindir}/bin/pgbench -c4 -j4 -P1 -p ${port} -C -M prepared         -S -T${w} -U postgres pgbench &>c4j4CMST100.txt

  #waitnwatch; ${bindir}/bin/pgbench -c8 -j4 -P1 -p ${port}                           -T${w} -U postgres pgbench &>c8j4T100.txt
  #waitnwatch; ${bindir}/bin/pgbench -c8 -j4 -P1 -p ${port}                        -S -T${w} -U postgres pgbench &>c8j4ST100.txt
  #waitnwatch; ${bindir}/bin/pgbench -c8 -j4 -P1 -p ${port}    -M prepared            -T${w} -U postgres pgbench &>c8j4MT100.txt
  #waitnwatch; ${bindir}/bin/pgbench -c8 -j4 -P1 -p ${port}    -M prepared         -S -T${w} -U postgres pgbench &>c8j4MST100.txt
  #waitnwatch; ${bindir}/bin/pgbench -c8 -j4 -P1 -p ${port}                -f ${q}    -T${w} -U postgres pgbench &>c8j4FT100.txt
  #waitnwatch; ${bindir}/bin/pgbench -c8 -j4 -P1 -p ${port}                -f ${q} -S -T${w} -U postgres pgbench &>c8j4FST100.txt
  #waitnwatch; ${bindir}/bin/pgbench -c8 -j4 -P1 -p ${port}    -M prepared -f ${q}    -T${w} -U postgres pgbench &>c8j4MFT100.txt
  #waitnwatch; ${bindir}/bin/pgbench -c8 -j4 -P1 -p ${port}    -M prepared -f ${q} -S -T${w} -U postgres pgbench &>c8j4MFST100.txt
  #waitnwatch; ${bindir}/bin/pgbench -c8 -j4 -P1 -p ${port} -C                        -T${w} -U postgres pgbench &>c8j4CT100.txt
  #waitnwatch; ${bindir}/bin/pgbench -c8 -j4 -P1 -p ${port} -C                     -S -T${w} -U postgres pgbench &>c8j4CST100.txt
  #waitnwatch; ${bindir}/bin/pgbench -c8 -j4 -P1 -p ${port} -C -M prepared            -T${w} -U postgres pgbench &>c8j4CMT100.txt
  #waitnwatch; ${bindir}/bin/pgbench -c8 -j4 -P1 -p ${port} -C -M prepared         -S -T${w} -U postgres pgbench &>c8j4CMST100.txt
  #waitnwatch; ${bindir}/bin/pgbench -c64 -j4 -P1 -p ${port}                           -T${w} -U postgres pgbench &>c64j4T100.txt
  #waitnwatch; ${bindir}/bin/pgbench -c64 -j4 -P1 -p ${port}                        -S -T${w} -U postgres pgbench &>c64j4ST100.txt
  #waitnwatch; ${bindir}/bin/pgbench -c64 -j4 -P1 -p ${port}    -M prepared            -T${w} -U postgres pgbench &>c64j4MT100.txt
  #waitnwatch; ${bindir}/bin/pgbench -c64 -j4 -P1 -p ${port}    -M prepared         -S -T${w} -U postgres pgbench &>c64j4MST100.txt
  #waitnwatch; ${bindir}/bin/pgbench -c64 -j4 -P1 -p ${port}                -f ${q}    -T${w} -U postgres pgbench &>c64j4FT100.txt
  #waitnwatch; ${bindir}/bin/pgbench -c64 -j4 -P1 -p ${port}                -f ${q} -S -T${w} -U postgres pgbench &>c64j4FST100.txt
  #waitnwatch; ${bindir}/bin/pgbench -c64 -j4 -P1 -p ${port}    -M prepared -f ${q}    -T${w} -U postgres pgbench &>c64j4MFT100.txt
  #waitnwatch; ${bindir}/bin/pgbench -c64 -j4 -P1 -p ${port}    -M prepared -f ${q} -S -T${w} -U postgres pgbench &>c64j4MFST100.txt
  #waitnwatch; ${bindir}/bin/pgbench -c64 -j4 -P1 -p ${port} -C                        -T${w} -U postgres pgbench &>c64j4CT100.txt
  #waitnwatch; ${bindir}/bin/pgbench -c64 -j4 -P1 -p ${port} -C                     -S -T${w} -U postgres pgbench &>c64j4CST100.txt
  #waitnwatch; ${bindir}/bin/pgbench -c64 -j4 -P1 -p ${port} -C -M prepared            -T${w} -U postgres pgbench &>c64j4CMT100.txt
  #waitnwatch; ${bindir}/bin/pgbench -c64 -j4 -P1 -p ${port} -C -M prepared         -S -T${w} -U postgres pgbench &>c64j4CMST100.txt

fi

    ${bindir}/psql -U postgres -p ${port} -c 'SELECT version();' postgres > ${logdir}/version.txt
done

#${bindir}/psql -1f ${scriptdir}/post.sql -U postgres -p ${port} pgbench
