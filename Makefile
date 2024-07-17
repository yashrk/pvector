.PHONY: test,clean
.ONESHELL: test,benchmark
benchmark:
		cd benchmarks
		guile measure.scm
		gnuplot random-reads.gnuplot
		for i in *.eps; do \
			convert -density 300 $$i -resize 1024x1024 `echo $$i| sed -e 's/.eps//'`.png; \
		done
		rm -f *.eps
		cd ..
clean:
		git restore benchmarks/*
		rm -f doc/api/index.texi
		rm -f doc/*.aux
		rm -f doc/*.fn
		rm -f doc/*.fns
		rm -f doc/*.log
		rm -f doc/*.pdf
		rm -f doc/*.toc
doc: doc/pvector.pdf
doc/pvector.pdf: pvector.scm doc/pvector.texi
		documenta api pvector.scm
		cd doc
		texi2pdf pvector.texi
		cd ..
test:
		cd tests
		guile tests.scm
		cd ..
