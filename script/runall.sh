#XXX: See if we can keep separate folders for pg installed instead of reinstalling each time

# lock the script so only one runs at a time
exec 200<$0
flock -n 200 || exit 1

basedir=/home/pi/projects/popi
scriptdir=${basedir}/script
bindir=${basedir}/stage/${2}

port=9999
#revisions="REL9_2_STABLE REL9_3_STABLE REL9_4_STABLE REL9_5_STABLE REL9_6_STABLE master"
revisions="master"
rev=$(echo ${revisions[@]} | tr " " "\n" | sort -R | tr "\n" " ")

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

	logdir=${basedir}/log/${folder}
	mkdir -p ${logdir}

	echo "RunAll: Start run for $s branch" >> ${logdir}/history.log
	date                         >> ${logdir}/history.log
	bash ${scriptdir}/run.sh $s $folder $port &>${logdir}/run.log
	echo "RunAll: Stop  run for $s branch" >> ${logdir}/history.log

done
