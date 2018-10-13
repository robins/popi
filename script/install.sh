tempdel="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
basedir="$(dirname "$tempdel")"

obsdir=${basedir}/obs
repodir=${basedir}/repo
scriptdir=${basedir}/script
resultdir=${basedir}/obs/results
logdir=${basedir}/log
historylog=${logdir}/history.log

enable_logging=1

log() {
  if [[ ${enable_logging} -eq 1 ]]; then
    dt=`date '+%Y-%m-%d %H:%M:%S'`
    echo "${dt}: ${1}"
  fi
}

logh() {
  log "Web: ${1}" >> ${historylog}
}

startScript() {
    mkdir -p ${logdir}
    logh "=== Start Web Script ==="
}

stopScript() {
    logh "--- Stop Web Script ---"
}

startScript

[ ! -d ${repodir} ] && \
	mkdir -p ${repodir} && \
	cd ${repodir} && \
	git clone https://github.com/postgres/postgres.git . && \
	./configure  && \
	logh "Checked-out Postgres Repo"

stopScript
