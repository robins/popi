bindir=/opt/postgres/${1}

${bindir}/bin/pg_ctl -D ${bindir}/data stop &>/dev/null
rm -rf ${bindir}/data
${bindir}/bin/initdb -D ${bindir}/data
${bindir}/bin/pg_ctl -D ${bindir}/data -l /opt/postgres/log/logfile_${1} start
