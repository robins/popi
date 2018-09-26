#XXX: Sometime add a cross-check that each folder grepped should be considered only
#     when there exists a file with the fold name in it (basically is the same major version)

basedir=/home/pi/projects/popi
obsdir=${basedir}/obs
repodir=${basedir}/repo


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

	if [ -f ${1} ]; then
		v=`grep "including connections" ${1} | awk '{print int($3)}'`
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

	git log --pretty=format:"%H" --after="2018-09-01" | tac | while read -r hash;
	do
		if [ -f ${hash} ]; then
			tps=$(GetTPSValue $hash)
			echo ${hash} ${tps} >> $3
			echo "Trying ${hash} - Found"
		else
			echo Trying ${hash} - Not Found
		fi
	done
exit 1
}


#sort -k2 c1j1MST1.txt | paste -s | awk -F " " '{if ($2 > $4*1.001) print "$1 is Faster than $3 by ",(($2-$4)/$4*100),"% (",$2," vs ",$4,")"; if ($4 > $2*1.001) print "$3 is Faster than $1 by ",(($4-$2)/$2*100),"% (",$4," vs ",$2,")";}'

function iterateTest () {
	output_filename=${basedir}/obs/results/$1.txt
	truncate -s 0 ${output_filename}
	filename=${1}

	find ${obsdir}/master/* -name ${filename} | while read -r filepath; do
#			echo ${filepath} ${filename} ${output_filename}
#			iterateCommit ${filepath} ${filename} ${output_filename}

			hash=`echo "${filepath}" | grep -oe '[0-9a-f]\{40\}'`
            tps=$(GetTPSValue $filepath)
            echo "${hash} ${tps}" >> ${output_filename}
	done
}

function iterateTests () {
	find ${obsdir}/master/* -regextype posix-extended -regex '.*c[0-9]+j[0-9]+.+T[0-9]' | awk -F "/" '{print $9}' | while read -r test; do
		echo ${test}
		iterateTest ${test}
	done
}

iterateTests

#iterateVer c4j4ST100
