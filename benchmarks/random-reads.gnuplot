set terminal postscript eps enhanced color font "32.0" fontscale 1.5
set border lc "#00999999" lw 0.25
set border 31 lw 3.0
set tics scale 3.0
set xlabel '{/:Bold data size}'
set ylabel '{/:Bold time, sec}'
set style data lines
set logscale x 10
set logscale y 10
set output "random-reads-short.eps"
plot "random-reads-short.data" using 1:2 lw 3 title "{/:Bold pvector}",\
                            '' using 1:3 lw 3 title "{/:Bold vector}",\
                            '' using 1:4 lw 3 title "{/:Bold vlist}",\
                            '' using 1:5 lw 3 title "{/:Bold list}",\
                            '' using 1:6 lw 3 title "{/:Bold vhash}"
unset logscale
set logscale x 10
set output "random-reads.eps"
plot "random-reads.data" using 1:2 lw 3 title "{/:Bold pvector}",\
                      '' using 1:3 lw 3 title "{/:Bold vlist}",\
                      '' using 1:4 lw 3 title "{/:Bold vector}",\
                      '' using 1:5 lw 3 title "{/:Bold vhash}"
