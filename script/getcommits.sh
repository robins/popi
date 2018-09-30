#XXX: See if we can keep separate folders for pg installed instead of reinstalling each time

# lock the script so only one runs at a time
exec 200<$0
flock -n 200 || exit 1

enable_logging=1

basedir=/home/pi/projects/popi
scriptdir=${basedir}/script
stagedir=${basedir}/stage
installdir=${stagedir}/${2}/master
bindir=${installdir}/bin
repodir=${basedir}/repo
logdir=${basedir}/log
historylog=${logdir}/history.log

port=9999

#revisions="REL9_2_STABLE REL9_3_STABLE REL9_4_STABLE REL9_5_STABLE REL9_6_STABLE master"
revisions="master"
rev=$(echo ${revisions[@]} | tr " " "\n" | sort -R | tr "\n" " ")

startScript() {
	mkdir -p ${logdir}
	truncate -s 0 ${historylog}
	logh "=== Start GetCommits Script ==="
}

stopScript() {
	logh "--- Stop GetCommits Script ---"
}

log() {
  if [[ ${enable_logging} -eq 1 ]]; then
    dt=`date '+%Y-%m-%d %H:%M:%S'`
    echo "${dt}: ${1}"
  fi
}

logh() {
  log "RunAll: ${1}" >> ${historylog}
}

appendCommitToQ() {
	q=${basedir}/catalog/q
	if [ `grep ${1} ${q}| wc -l` -eq 0 ]; then
		echo ${1} >> ${q}
	else
		logh "Possibly commit ${1} already exists in Q"
	fi
}

get_latest_commit_for_branch() {
  logh "Update git repo"
  cd ${repodir}
  git checkout $1 &>> /dev/null
  git pull &>>/dev/null
  git log -n 1 --pretty=format:"%H"
}

startScript

	for s in $rev
	do
		latest_commit_for_branch=$(get_latest_commit_for_branch ${s})

		appendCommitToQ ${latest_commit_for_branch}
	done

stopScript
