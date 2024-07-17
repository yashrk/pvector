.PHONY: test,clean
.ONESHELL: test,benchmark
test:
		cd tests
		guile tests.scm
		cd ..
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
