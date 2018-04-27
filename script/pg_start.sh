basedir=/home/pi/projects/popi/stage
repobasedir=${basedir}/${1}

bindir=/opt/postgres/master/bin

${bindir}/pg_ctl -D ${repobasedir}/data stop &>/dev/null
rm -rf ${repobasedir}/data/*
mkdir -p ${basedir}/log/
mkdir -p ${repobasedir}

${bindir}/initdb -D ${repobasedir}/data
${bindir}/pg_ctl -D ${repobasedir}/data -l ${basedir}/log/logfile_${1} start
