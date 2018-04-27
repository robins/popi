basedir=/home/pi/projects/popi/stage
bindir=/opt/postgres/master/bin

${bindir}/pg_ctl -D ${basedir}/${1}/data stop
