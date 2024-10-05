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

################################################
# XXX The WHOLE CONCEPT OF BRANCH is BROKEN... Q can't take branches :((
################################################
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
  if [[ $1 -ne 0 ]]; then
    echo Check Logs. Quitting.
    exit 1
  fi

  exit 0
}

prependCommitToQ() {
        if [ -z ${1} ]; then
                logh "Can't prepend empty string to Q"
                return 0
        fi

    qDir=${basedir}/catalog
    mkdir -p ${qDir}

    q="${qDir}/q"
    if [ ! -f ${q} ]; then
                logh "Creating Q, since it didn't exist here ($q)"
                touch ${q}
    fi

    if ! grep -Fxq ${1} ${q} ; then
                logh "Prepending ${1} to Q"
        echo ${1} | cat - ${q} > temp && mv temp ${q}
    else
        logh "Commit ${1} already exists in Q"
    fi
}

checkIsRepoDirOkay() {
    if [ -f ${srcdir}/README.md ]; then
        #Postgres repo already exists
        return 0
    fi
        return 1
}

FailIfRepoNotOkay() {
  if ! $(checkIsRepoDirOkay) ; then
    logh "Something is wrong with Repodir" &>> /dev/null
    stopScript 1
  fi
}

prepareRepoDir() {
        if $(checkIsRepoDirOkay) ; then
                logh "Repo dir already exists. Nothing to do"
                return 1
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

getCommitBeforeTS() {
  FailIfRepoNotOkay

  cd ${srcdir} && \
    git log -n 1 --before="${1}" --pretty=format:"%H"
}


UpdateRepo() {
  FailIfRepoNotOkay

  logh "Update git repo"
  cd ${srcdir} && \
    git reset --hard &>> /dev/null && \
    git checkout $1 &>> /dev/null && \
    git pull &>>/dev/null && \
    logh "Git repo updated" &>> /dev/null
}

get_latest_commit_for_branch() {
  FailIfRepoNotOkay

  cd ${srcdir} && \
    git log -n 1 --pretty=format:"%H"
}

fillQWithNDaysFromToday() {
  ts=`date +%s`
  for i in `seq 1 ${1}`
    do
      commit=$(getCommitBeforeTS $ts)
      echo ${commit}
      prependCommitToQ ${commit}
      ts=$((ts-86400))
    done
}

startScript

prepareRepoDir

UpdateRepo

# XXX: Add an option that defaults to doing get_latest_commit_for_branch
# XXX: Add this script to an hourly run
fillQWithNDaysFromToday 100

stopScript
