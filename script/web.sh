#!/bin/bash

# Abort, if another instance of this program is already running
scriptname=$(basename "$0")
n=`ps -ef | grep "$scriptname"| grep -v grep | grep -v "$$" | wc -l`
[ "$n" -ge 1 ] && echo "$scriptname already running. Aborting" && exit 1

tempdel="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
basedir="$(dirname "$tempdel")"

obsdir=${basedir}/obs
scriptdir=${basedir}/script
resultdir=${basedir}/obs/results
logdir=${basedir}/log
historylog=${logdir}/history.log

enable_logging=1

log() {
  if [[ ${enable_logging} -eq 1 ]]; then
    dt=`date '+%Y-%m-%d %H:%M:%S'`
    echo "${dt}: ${1}"
  fi
}

logh() {
  log "Web: ${1}" >> ${historylog}
}

startScript() {
    mkdir -p ${logdir}
    logh "=== Start Web Script ==="
}

stopScript() {
    logh "--- Stop Web Script ---"
}

function getTestName() {
	s=${1}
	echo ${s##*/}

	# Later this can be converted to "deciphering" the filename to a Test Name ... for e.g. c => Connection establish for each Run etc.
}

function iterateResults() {
	output_filename=${basedir}/obs/results/index.html
	truncate -s 0 ${output_filename}

	logh "Starting HTML"

	echo "<HTML><BODY>" >> ${output_filename}

	find ${resultdir}/* -name "*.png" | while read -r filepath; do
		testName=`getTestName ${filepath}`
		fileName=${filepath##*/}
		echo "<h2>${testName}</h2><img src=\"${fileName}\" alt=\"${testName}\"><hr>" >> ${output_filename}
	done

	echo "</BODY></HTML>" >> ${output_filename}

	logh "End HTML"
}

startScript

iterateResults

stopScript
