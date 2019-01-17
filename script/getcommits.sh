#XXX: See if we can keep separate folders for pg installed instead of reinstalling each time

# lock the script so only one runs at a time
exec 200<$0
flock -n 200 || exit 1

enable_logging=1

tempdel="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
basedir="$(dirname "$tempdel")"

scriptdir=${basedir}/script
stagedir=${basedir}/stage
installdir=${stagedir}/${2}/master
bindir=${installdir}/bin
repodir=${basedir}/repo
logdir=${basedir}/log
historylog=${logdir}/history.log
postgresGitCloneURL=https://github.com/postgres/postgres.git

port=9999

#revisions="REL9_4_STABLE REL9_5_STABLE REL9_6_STABLE REL_10_STABLE REL_11_STABLE master"
revisions="master"
rev=$(echo ${revisions[@]} | tr " " "\n" | sort -R | tr "\n" " ")

log() {
  if [[ ${enable_logging} -eq 1 ]]; then
    dt=`date '+%Y-%m-%d %H:%M:%S'`
    echo "${dt}: ${1}"
  fi
}

logh() {
  log "GetCommits: ${1}" >> ${historylog}
}

startScript() {
	mkdir -p ${logdir}
	logh "=== Start GetCommits Script ==="
}

stopScript() {
	logh "--- Stop GetCommits Script ---"
}

appendCommitToQ() {
	q=${basedir}/catalog/q
	if [ `grep ${1} ${q}| wc -l` -eq 0 ]; then
		echo ${1} >> ${q}
	else
		logh "Commit ${1} already exists in Q"
	fi
}

prependCommitToQ() {
    q=${basedir}/catalog/q
    if [ `grep ${1} ${q}| wc -l` -eq 0 ]; then
        sed -i "1s;^;${1}\n;" ${q}
    else
        logh "Commit ${1} already exists in Q"
    fi
}

prepareRepoDir() {
	if [ -f ${repodir}/postgres/README ]; then
		echo "Looks like Postgres repo already exists"
		return
	fi

	echo "Looks like a new installation. Creating Repo directory"
	mkdir -p ${repodir}

	cd ${repodir}
	echo "Checking out Postgres code"
	git clone ${postgresGitCloneURL} &>> /dev/null

	if [ ! -f ${repodir}/postgres/README ]; then
		echo "Git Clone failed. Was trying at ${repodir}. Exiting"
		exit 1
	fi
}

get_latest_commit_for_branch() {
	logh "Update git repo"
	cd ${repodir} && \
		git reset --hard &>> /dev/null && \
		git checkout $1 &>> /dev/null && \
		git pull &>>/dev/null && \
		git log -n 1 --pretty=format:"%H" && \
		logh "git repo Updated" &>> /dev/null
}


prepareRepoDir

startScript

	for s in $rev
	do
		latest_commit_for_branch=$(get_latest_commit_for_branch ${s})

		prependCommitToQ ${latest_commit_for_branch}
	done

stopScript
