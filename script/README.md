/test folder contains tests (which can be added at any time). A test is selected if one is not provided, but the idea is that the
tool ensures that when complete, the test selected has performance numbers across the history of the project.
====

Folder for scripts

Libraries / software requirements:
- datamash
- gnuplot-x11
- curl

Sequence:
- getcommits.sh -> clones / git pull and then populate catalog/q for commits to be tested
- runall.sh

====

getcommits.sh | Fetch new Commits that need to be processed
logprefix
misc.sh
parseobs.sh
post.sql      | Post-test SQL Script
pre.sql       | Pre-test SQL Script
README.md     | This ReadMe file
resultplot.gp
runall.sh     | Run all tests
run.sh        | Run tests for 1 Commit (triggered by runall.sh) - Essentially (git checkout + git install + pg_start + runtests + pg_stop)
runtests.sh   | Run tests for 1 installation (triggered by run.sh) - Essentially (pre.sql + test + post.sql)
web.sh

====


smith@dell:~/proj/popi/obs/master$ for f in `find /home/smith/proj/popi/obs/master -name c2j1MST100`; do echo -n "${f}: "; grep connection ${f} | grep tps; echo; done | grep tps
/home/smith/proj/popi/obs/master/7e6fb5da41d8ee1bddcd5058b7204018ef68d193/c2j1MST100: tps = 33533.459537 (without initial connection time)
/home/smith/proj/popi/obs/master/e557db106ef69413edb75c362191084ee73a0f55/c2j1MST100: tps = 32718.220935 (without initial connection time)
/home/smith/proj/popi/obs/master/231ff70f98e389dd510db86d3971b87e92c65d39/c2j1MST100: tps = 33328.150489 (without initial connection time)
/home/smith/proj/popi/obs/master/8a7cbfce13d476a3e9782111c45a7b3335646ee4/c2j1MST100: tps = 32883.686064 (without initial connection time)
/home/smith/proj/popi/obs/master/b485ad7f07c80efbfd47329f138f0fe3a5acf013/c2j1MST100: tps = 33411.418878 (without initial connection time)
/home/smith/proj/popi/obs/master/0e917508b89dd21c5bcd9183e77585f01055a20d/c2j1MST100: tps = 33630.966349 (without initial connection time)
