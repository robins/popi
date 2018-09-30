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
	logh "=== Start RunAll Script ==="
}

stopScript() {
	logh "--- Stop RunAll Script ---"
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

getFirstCommitFromQ() {
	q=${basedir}/catalog/q

	hash=$(head -n 1 ${q})

	echo ${hash}
}


# XXX: We need to check if the first line is in fact ${1}
removeFirstCommitFromQ() {
	q=${basedir}/catalog/q

	sed -i '1d' ${q}
}

get_latest_commit_for_branch() {
  logh "Update git repo"
  cd ${repodir}
  git checkout $1 &>> /dev/null
  git log -n 1 --pretty=format:"%H"
}

# XXX: This obviously needs work. git branch --contains e8fe426baa9c242d8dbd4eab1d963e952c9172f4 doesn't work always
getBranchForCommit() {
	echo "master"
}

getFolderForBranch() {
	s=${1}
	if [[ ${#s} -eq 'master' ]]; then
		folder='master'
	else
		s1=${s#REL}
		s2=${s1%_STABLE}
		s3=${s2/\_/\.}
		folder=$s3
	fi

	echo ${folder}
}

startScript

hash=`getFirstCommitFromQ`

if [ ${#hash} -gt 0 ]; then

	branch=`getBranchForCommit ${hash}`
	folder=`getFolderForBranch ${branch}`

    logh "Start run for ${branch} branch for Commit ${hash}"
    bash ${scriptdir}/run.sh $branch $folder ${hash} &>>${historylog}
    logh "Stop run for ${branch} branch for Commit ${hash}"

	removeFirstCommitFromQ ${hash}
else
	logh "Didn't find commit in Q"
fi

stopScript
