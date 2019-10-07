#generate the tree file
#tree -I 'repo*|install*|tree.txt' .. > ../tree.txt

# Generate the Q to get first commits of all Days ... :) 
# To be run in the repo folder (not in scripts :)
# cd ../repo/postgres
# git log --date=short --pretty=format:"%ad %H" | sort -rk1 | datamash -t" " -g1 first 2 | awk -F " " '{print $2;}' >> ../catalog/q2
# sort -u ../catalog/q2


#crontab entries
#*/10 * * * *  nice bash /home/pi/projects/popi/script/runall.sh 
#* */6 * * * nice -n 19 bash /home/pi/projects/popi/script/getcommits.sh
#0 * * * * nice -n 19 bash /home/pi/projects/popi/script/parseobs.sh
