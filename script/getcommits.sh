#!/bin/bash
#XXX: See if we can keep separate folders for pg installed instead of reinstalling each time

# Abort, if another instance of this program is already running
scriptname=$(basename "$0")
n=`ps -ef | grep "$scriptname"| grep -v grep | grep -v "$$" | wc -l`
[ "$n" -ge 1 ] && echo "$scriptname already running. Aborting" && exit 1

enable_logging=1
actually_make_changes=1

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

catalogdir=${basedir}/catalog
q=${catalogdir}/q
q2=${catalogdir}/q2


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

  logh "Prepending ${1} to Q"
  echo ${1} | cat - ${q} > temp && mv temp ${q}
}

appendCommitToQ() {
  if [ -z ${1} ]; then
    logh "Can't append empty string to Q"
    return 0
  fi

  logh "Appending ${1} to Q"
  echo "${1}" >> ${q}
}

checkIsRepoDirOkay() {
    if [ -f "${srcdir}/README.md" ]; then
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

        if [ ! -f "${srcdir}/README.md" ]; then
                logh "Git Clone failed. Was trying at ${repodir}. Exiting" 1
                exit 1
        fi
}

getCommitBeforeTS() {
  FailIfRepoNotOkay

  logh "Looking for commit before ${1} - `date -d@${1}`"
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

checkIfCommitInQ2() {
  grep -c "${1}" "${q2}"
}

checkIfCommitInQ() {
  grep -c "${1}" "${q}"
}

prepareQDir() {
  qDir=${basedir}/catalog
  mkdir -p ${qDir}

  q="${qDir}/q"
  if [ ! -f ${q} ]; then
    logh "Creating Q, since it didn't exist here ($q)"
    touch ${q}
  fi
}

fillQWithNDaysFromToday() {
  ts=`date +%s`
  n=${1}
  i=1
  while [ $i -le $n ]
    do
      commit=$(getCommitBeforeTS $ts)
      ts=$((ts-86400))

      if [ "$(checkIfCommitInQ ${commit})" -gt 0 ]; then
        logh "Skipping commit ${commit} - already in Q"
        continue
      fi
      
      if [ "$(checkIfCommitInQ2 ${commit})" -gt 0 ]; then
        logh "Skipping commit ${commit} - already processed"
        continue
      fi
      
      if [ $actually_make_changes -eq 1 ]; then
        appendCommitToQ ${commit}
      fi
    
      i=$((i+1))
      echo ${commit}
    done
}

startScript

prepareQDir
prepareRepoDir

UpdateRepo

# XXX: Add an option that defaults to doing get_latest_commit_for_branch
# XXX: Add this script to an hourly run
fillQWithNDaysFromToday ${1:-5}

stopScript
