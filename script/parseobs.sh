#XXX: Sometime add a cross-check that each folder grepped should be considered only
#     when there exists a file with the fold name in it (basically is the same major version)

basedir=/home/pi/projects/popi
obsdir=${basedir}/obs

# Get all active versions from the internet
# XXX: Ensure slow internet connections don't hold up this run
versions=( `timeout -s SIGTERM 10 curl -so - "http://www.postgresql.org/support/versioning/" | \
        grep -A100 "EOL" | \
        grep -B2 "Yes" | \
        grep "colFirst" | \
        cut --bytes=25-27 | \
	sort | \
        tr '\n' ' '` master)

if [ ${#versions[@]} -le 2 ]; then
#        versions=(9.4 9.5 9.6 10 master)
        versions=(master)
fi

echo "Versions:  ${versions[@]}"

function getDescription() {
  s="${1/C/Newconn}"
  s="${s/j4/Thread4}"
  s="${s/F/File}"
  s="${s/c4/Conn4}"
  s="${s/c8/Conn8}"
  s="${s/c64/Conn64}"
  s="${s/M/Prepared}"
  s="${s/S/Readonly}"
  s="${s/T100/100secs}"
  s="${s/c8/Conn8}"
	echo $s
}

function GetTPSValue() {
	f=/home/robins/projects/pgbench/obs/$1/$2/$3

	if [ -f "$f" ]; then
 		v=`grep "including connections" $f | awk '{print int($3)}'`
	fi
	if [[ "$v" =~ ^[0-9]+$ ]] && [ "$v" -ge 0 -a "$v" -le 1000000 ];
	then
		if [[ $v -gt 0 ]]; then
			echo $v
		else
			echo 0
		fi
	else
		echo 0
	fi
}

function GetAverageTPSValue() {
  n=0
  TPSTotal=0
  for t in {0..9};
    do
      tps=$(GetTPSValue $1 $t $2)
      TPSTotal=`expr $TPSTotal + $tps`
      if [[ $tps -gt 0 ]]; then
        n=`expr $n + 1`
      fi
    done
#echo $TPSTotal
#echo $n
  if [ $n -eq 0 ]; then
    echo 0
  else
    echo $(( TPSTotal / n ))
  fi
#echo "done"
}



function iterateVer() {

        filename=$1.txt

        t=$(getDescription $1)
        echo $t

        for i in "${versions[@]}"
        do
                tps=$(GetAverageTPSValue $i $filename)
                echo ${tps} 
        done
}

function iterateCommit() {

        output_filename=${basedir}/obs/results/$1.txt

        git log --pretty=format:"%H" --after="2018-09-01" | tac | while read -r hash; do
                f=${obsdir}/master/${test}.txt
		if [ -f ${f} ]; then
			tps=$(GetTPSValue $f)
 	                echo ${tps} >> ${output_filename}
		fi
        done
}




function iterateTest () {
        find ${obsdir}/master/* -name ${1} | while read -r filepath; do
                filename=${1}
                echo ${filepath} ${filename}
                #mkdir -p ${basedir}/obs/results/$line
#               iterateVer ${filepath} ${filename}
        done
}

function iterateTests () {
	find ${obsdir}/master/* -regextype posix-extended -regex '.*c[0-9]+j[0-9]+.+T[0-9]' | awk -F "/" '{print $9}' | while read -r test; do
		echo ${test}
		iterateTest ${test}
exit 1
	done
}

iterateTests

#iterateVer c4j4ST100
