bindir=/opt/postgres/${1}

${bindir}/bin/pg_ctl -D ${bindir}/data stop

