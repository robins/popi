#XXX: See if we can keep separate folders for pg installed instead of reinstalling each time

# lock the script so only one runs at a time
exec 200<$0
flock -n 200 || exit 1

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
		s1=$s3
	fi

	echo "RunAll: Triggering $s" >> /home/robins/projects/popi/log/history.log
	date                         >> /home/robins/projects/popi/log/history.log
	bash /home/robins/projects/popi/script/run.sh $s $s1 $port &>/home/robins/projects/popi/log/run.log
done

