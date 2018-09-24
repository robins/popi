#XXX: See if we can keep separate folders for pg installed instead of reinstalling each time

# lock the script so only one runs at a time
#exec 200<$0
#flock -n 200 || exit 1

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

log() {
  if [[ ${enable_logging} -eq 1 ]]; then
    dt=`date '+%Y-%m-%d %H:%M:%S'`
    echo "${dt}: ${1}"
  fi
}

logh() {
  log "RunAll: ${1}" >> ${historylog}
}

get_latest_commit_for_branch() {
  logh "Update git repo"
  cd ${repodir}
  git checkout $1 &>> /dev/null
  git pull &>>/dev/null
  git log -n 1 --pretty=format:"%H"
}


mkdir -p ${logdir}

logh "=== Start  Script ==="

for s in $rev
do
	if [[ ${#s} -eq 'master' ]]; then
		s1=${s}
		# Do nothing
	else
		s1=${s#REL}
		s2=${s1%_STABLE}
		s3=${s2/\_/\.}
		folder=$s3
	fi

	latest_commit_for_branch=$(get_latest_commit_for_branch ${s})

	truncate -s 0 ${historylog}
	logh "Start run for $s branch"
	bash ${scriptdir}/run.sh $s $folder ${latest_commit_for_branch} &>>${historylog}
	logh "Stop  run for $s branch"

done
logh "--- Stop  Script ---"
