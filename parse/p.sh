# Get all active versions from the internet
# Ensure slow internet connections don't hold up this run
versions=( `timeout -s SIGTERM 10 curl -so - "http://www.postgresql.org/support/versioning/" | \
        grep -A100 "EOL" | \
        grep -B2 "Yes" | \
        grep "colFirst" | \
        cut --bytes=25-27 | \
#        sed 's/\.//g' | \
	sort | \
        tr '\n' ' '` master)

if [ ${#versions[@]} -le 2 ]; then
        versions=(9.1 9.2 9.3 9.4 9.5 master)
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
	f=/home/robins/projects/pgbench/$1/$2/$3

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


function iterateVar () {
	metric=(c4j4ST100 c8j4ST100 c64j4ST100 c4j4CMST100 c4j4CMT100 c4j4CST100 c4j4CT100 c4j4FST100 c4j4FT100 c4j4MFST100 c4j4MFT100 c4j4MST100 c4j4MT100 c4j4T100 c64j4CMST100 c64j4CMT100 c64j4CST100 c64j4CT100 c64j4FST100 c64j4FT100 c64j4MFST100 c64j4MFT100 c64j4MST100 c64j4MT100 c64j4T100 c8j4CMST100 c8j4CMT100 c8j4CST100 c8j4CT100 c8j4FST100 c8j4FT100 c8j4MFST100 c8j4MFT100 c8j4MST100 c8j4MT100 c8j4T100)

	n="${#metric[@]}"
	for i in `seq $n`
	do
		iterateVer ${metric[$i-1]}
	done
}

iterateVar

#iterateVer c4j4ST100
