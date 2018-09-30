basedir=/home/pi/projects/popi
obsdir=${basedir}/obs
repodir=${basedir}/repo
scriptdir=${basedir}/script
resultdir=${basedir}/obs/results

function getTestName() {
	s=${1}
	echo ${s##*/}

	# Later this can be converted to "deciphering" the filename to a Test Name ... for e.g. c => Connection establish for each Run etc.
}

function iterateResults() {
	output_filename=${basedir}/obs/results/index.html
	truncate -s 0 ${output_filename}

	echo "<HTML><BODY>" >> ${output_filename}

	find ${resultdir}/* -name "*.png" | while read -r filepath; do
		testName=`getTestName ${filepath}`
		fileName=${filepath##*/}
		echo "<a href=\"${fileName}\">${testName}</a></br>" >> ${output_filename}
	done

	echo "</BODY></HTML>" >> ${output_filename}
}

iterateResults
