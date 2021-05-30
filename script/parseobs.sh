# lock the script so only one runs at a time
exec 200<$0
flock -n 200 || exit 1

#XXX: Sometime add a cross-check that each folder grepped should be considered only
#     when there exists a file with the fold name in it (basically is the same major version)

tempdel="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
basedir="$(dirname "$tempdel")"

obsdir=${basedir}/obs
repodir=${basedir}/repo
srcdir=${repodir}/postgres
scriptdir=${basedir}/script
resultdir=${basedir}/obs/results
logdir=${basedir}/log
historylog=${logdir}/history.log

enable_logging=1
mkdir -p ${resultdir}

log() {
  if [[ ${enable_logging} -eq 1 ]]; then
    dt=`date '+%Y-%m-%d %H:%M:%S'`
    echo "${dt}: ${1}"
  fi
}

logh() {
  log "ParseObs: ${FUNCNAME[ 1 ]}: ${1}" >> ${historylog}
}

lexit() {
	logh "Exiting as requested"
	stopScript
	exit ${1}
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
	if [ -f ${new_out_file} ]; then
		truncate -s 0 ${new_out_file}
	fi
	
	logh "Iterating Commit ${1} {$2}"

  #going through ALL commits since 1st Sept 2019 and sorting them in order
	git --git-dir ${srcdir}/.git log --pretty=format:"%H %at %ad" --after="2021-05-01" --date=local| sort -k2 | while read -r line;
	do
		logh "echo $line | awk -F ' ' '{print \$1;}'"
		githash=`echo $line | awk -F " " '{print \$1;}'`
		logh "grep ${githash} ${1} | awk -F ' ' '{print \$2}'"
		s=`grep ${githash} ${1} | awk -F ' ' '{print \$2}'`
		logh "echo ${line} | awk -F ' ' '{print \$2}'"
		epoch=`echo ${line} | awk -F ' ' '{print \$2}'`
logh "########################### ${epoch} ${s} ${githash} ${new_out_file}"
#exit 1
		if [[ "$s" -gt 0 ]]; then
			logh "${githash} ${epoch} ${s} >> ${new_out_file}."
			echo ${epoch} ${s} >> ${new_out_file}
		fi
	done

	if [ -s ${new_out_file} ];
	then
		rm ${1}
		mv ${new_out_file} ${1}
	else
		logh "Somehow the Sorted file (${new_out_file}) is empty. Skipping swap"
	fi
}

# Bash script to find the percentage difference between max / min. Doubt this'd be used once we have
# ascending order of commit hash performance, but it's a good line to keep for now.
# sort -k2 c1j1MST1.txt | paste -s | awk -F " " '{if ($2 > $4*1.001) print "$1 is Faster than $3 by ",(($2-$4)/$4*100),"% (",$2," vs ",$4,")"; if ($4 > $2*1.001) print "$3 is Faster than $1 by ",(($4-$2)/$2*100),"% (",$4," vs ",$2,")";}'

function iterateOneTest () {

  # Ensure that a file for this test-type exists
	output_filename=${resultdir}/$1
	if [ -f ${output_filename} ]; then
		truncate -s 0 ${output_filename}
	fi
	filename=${1}

	find ${obsdir}/master/* -name ${filename} | while read -r filepath; do
#			logh "${filepath} ${filename} ${output_filename}"
			iterateCommit ${filepath} ${filename} ${output_filename}

			hash=`echo "${filepath}" | grep -oe '[0-9a-f]\{40\}'`
            tps=$(GetTPSValue $filepath)
            echo "${hash} ${tps}" >> ${output_filename}
	done

	iterateCommit ${output_filename}
}

function plotTest() {
	inputFile=${resultdir}/$1
	logh "Plotting ${1}"
	sed -i -e "s/XXXXXX/${1}/g" ${scriptdir}/resultplot.gp

	gnuplot ${scriptdir}/resultplot.gp > ${resultdir}/${1}.png

	sed -i -e "s/${1}/XXXXXX/g" ${scriptdir}/resultplot.gp
}

function iterateAllTests () {
  # This processes all test result folders (and the files within them) and finds the uniq test types within them (across all commits)
	find ${obsdir}/master/* -regextype posix-extended -regex '.*c[0-9]+j[0-9]+.+T[1-9][0-9]{2,5}' | awk -F "/" '{print $9}' | sort | uniq | while read -r test; do
		logh "Processing ${test}"
		iterateOneTest ${test}
		plotTest ${test}
		logh "Completed ${test}"
		exit
	done
}

startScript
iterateAllTests
stopScript
