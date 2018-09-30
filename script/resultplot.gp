# gnuplot script file for plotting TPS Performance over time
#!/usr/bin/gnuplot
reset
set terminal png

set xdata time
set timefmt "%s"
set format x "%d"

set xlabel "Date (day of month)"
set ylabel "TPS as on that Commit"

set title "TPS over time"
set key below
set grid

plot "/home/pi/projects/popi/obs/results/XXXXXX" using 1:2 title "TPS"
