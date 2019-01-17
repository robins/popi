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
srcdir=${repodir}/postgres
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
	if [[ ${2} -eq 1 ]]; then
		echo "GetCommits: ${1}"
	fi
}

startScript() {
	mkdir -p ${logdir}
	logh "=== Start GetCommits Script ==="
}

stopScript() {
	logh "--- Stop GetCommits Script ---"
}

prependCommitToQ() {
	if [ -z ${1} ]; then
		logh "Can't prepend empty string to Q"
		return 0
	fi

    q=${basedir}/catalog/q
    if ! grep -Fxq ${1} ${q} ; then
        sed -i "1s;^;${1}\n;" ${q}
		logh "Prepending ${1} to Q"
    else
        logh "Commit ${1} already exists in Q"
    fi
}

checkIsRepoDirOkay() {
    if [ -f ${srcdir}/README ]; then
        #Postgres repo already exists
        return 0
    fi
	return 1
}

prepareRepoDir() {
	if ! $(checkIsRepoDirOkay) ; then
		logh "Repo dir already exists. Nothing to do"
		return
	fi

	logh "Looks like a new installation. Creating Repo directory"
	mkdir -p ${repodir}

	cd ${repodir}
	logh "Checking out Postgres code"
	git clone ${postgresGitCloneURL} &>> /dev/null

	if [ ! -f ${srcdir}/README ]; then
		logh "Git Clone failed. Was trying at ${repodir}. Exiting" 1
		exit 1
	fi
}

get_latest_commit_for_branch() {
    if ! $(checkIsRepoDirOkay) ; then
        logh "Something wrong with Repodir" &>> /dev/null
        return 1
    fi

	logh "Update git repo"
	cd ${srcdir} && \
		git reset --hard &>> /dev/null && \
		git checkout $1 &>> /dev/null && \
		git pull &>>/dev/null && \
		git log -n 1 --pretty=format:"%H" && \
		logh "Git repo updated" &>> /dev/null
}


prepareRepoDir

startScript

	for s in $rev
	do
		latest_commit_for_branch=$(get_latest_commit_for_branch ${s})

		prependCommitToQ ${latest_commit_for_branch}
	done

stopScript
