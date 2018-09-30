tree -I 'repo*|install*|tree.txt' .. > ../tree.txt

# Generate the Q to get first commits of all Days ... :) 
# git log --date=short --pretty=format:"%ad %H" | sort -rk1 | datamash -t" " -g1 first 2 | awk -F " " '{print $2;}' > ../catalog/q
