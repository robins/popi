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
logprefixfile=${scriptdir}/logprefix

port=9999

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

log() {
  if [[ ${enable_logging} -eq 1 ]]; then
    dt=`date '+%Y-%m-%d %H:%M:%S'`
    echo "${dt}: "`cat ${logprefixfile}`" : ${1}"
  fi
}

logh() {
	log "RunAll: ${1}" >> ${historylog}
}

updateLogPrefix() {
    logh "Generating log prefix"
    head /dev/urandom | tr -dc A-Z0-9 | head -c 5 > ${logprefixfile}
}

removeLogPrefix() {
	echo -n "" > ${logprefixfile}
}

#versions="REL9_2_STABLE REL9_3_STABLE REL9_4_STABLE REL9_5_STABLE REL9_6_STABLE REL_10_STABLE REL_11_STABLE master"
#versions="master"
rev=$(echo ${versions[@]} | tr " " "\n" | sort -R | tr "\n" " ")

startScript() {
	mkdir -p ${logdir}
	removeLogPrefix
	logh "########################################################"
	logh "=== Start RunAll Script ==="
	updateLogPrefix
}

stopScript() {
	logh "--- Stop RunAll Script ---"
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
  logh "Going to update Git repo"
  cd ${srcdir}
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

logh "Versions:  ${versions[@]}"

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
