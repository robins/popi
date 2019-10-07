Folder for scripts

runall -> run.sh
run.sh -> (git checkout + git install + pg_start + runtests + pg_stop)
runtests -> (pre.sql + test + post.sql)

getcommits.sh | Fetch new Commits that need to be processed
logprefix
misc.sh
parseobs.sh
post.sql      | Post-test SQL Script
pre.sql       | Pre-test SQL Script
README.md     | This ReadMe file
resultplot.gp
runall.sh | Run all tests
run.sh        | Run tests for 1 Commit
runtests.sh   | Run tests for 1 installation
web.sh

Scripts need:
datamash
gnuplot-x11
