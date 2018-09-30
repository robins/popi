#XXX: Sometime add a cross-check that each folder grepped should be considered only
#     when there exists a file with the fold name in it (basically is the same major version)

basedir=/home/pi/projects/popi
obsdir=${basedir}/obs
repodir=${basedir}/repo
scriptdir=${basedir}/script
resultdir=${basedir}/obs/results

log() {
  if [[ ${enable_logging} -eq 1 ]]; then
    dt=`date '+%Y-%m-%d %H:%M:%S'`
    echo "${dt}: ${1}"
  fi
}

logh() {
  log "ParseObs: ${1}" >> ${historylog}
}

startScript() {
    mkdir -p ${logdir}
    logh "=== Start ParseObservation Script ==="
}

stopScript() {
    logh "--- Stop ParseObservation Script ---"
}

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


function iterateCommit() {
	new_out_file=${1}_sorted
	truncate -s 0 ${new_out_file}

	git --git-dir ${repodir}/.git log --pretty=format:"%H %at %ad" --after="2018-09-01" --date=local| sort -k2 | while read -r line;
	do
		githash=`echo $line | awk -F " " '{print $1;}'`
		s=`grep ${githash} ${1} | awk -F ' ' '{print $2}'`
		epoch=`echo ${line} | awk -F ' ' '{print $2}'`
		if [[ "$s" -gt 0 ]]; then
#			echo ${githash} ${epoch} ${s} >> ${new_out_file}
			echo ${epoch} ${s} >> ${new_out_file}
		fi
	done

	rm ${1}
	mv ${new_out_file} ${1}
}

# Bash script to find the percentage difference between max / min. Doubt this'd be used once we have
# ascending order of commit hash performance, but it's a good line to keep for now.
# sort -k2 c1j1MST1.txt | paste -s | awk -F " " '{if ($2 > $4*1.001) print "$1 is Faster than $3 by ",(($2-$4)/$4*100),"% (",$2," vs ",$4,")"; if ($4 > $2*1.001) print "$3 is Faster than $1 by ",(($4-$2)/$2*100),"% (",$4," vs ",$2,")";}'

function iterateOneTest () {
	output_filename=${basedir}/obs/results/$1
	truncate -s 0 ${output_filename}
	filename=${1}

	find ${obsdir}/master/* -name ${filename} | while read -r filepath; do
#			echo ${filepath} ${filename} ${output_filename}
#			iterateCommit ${filepath} ${filename} ${output_filename}

			hash=`echo "${filepath}" | grep -oe '[0-9a-f]\{40\}'`
            tps=$(GetTPSValue $filepath)
            echo "${hash} ${tps}" >> ${output_filename}
	done

	iterateCommit ${output_filename}
}

function plotTest() {
	inputFile=${resultdir}/$1

	sed -i -e "s/XXXXXX/${1}/g" ${scriptdir}/resultplot.gp

	gnuplot ${scriptdir}/resultplot.gp > ${resultdir}/${1}.png

	sed -i -e "s/${1}/XXXXXX/g" ${scriptdir}/resultplot.gp
}

function iterateAllTests () {
	find ${obsdir}/master/* -regextype posix-extended -regex '.*c[0-9]+j[0-9]+.+T[1-9][0-9]{2,5}' | awk -F "/" '{print $9}' | sort | uniq | while read -r test; do
		logh "Processing ${test}"
		iterateOneTest ${test}
		plotTest ${test}
	done
}

iterateAllTests
