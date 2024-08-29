.PHONY: test,clean
.ONESHELL: doc,benchmark,test
benchmark:
		cd benchmarks
		guile measure.scm
		gnuplot random-reads.gnuplot
		gnuplot random-writes.gnuplot
		gnuplot pushes.gnuplot
		gnuplot maps.gnuplot
		gnuplot folds.gnuplot
		for i in *.eps; do \
			convert -density 300 \
                    $$i \
                    -alpha off \
                    -resize 1024x1024 \
                    `echo $$i| sed -e 's/.eps//'`.png; \
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
		dot -Tpng index-7-digit-number-system.dot -o index-7-digit-number-system.png
		dot -Tpng index-binary-system.dot -o index-binary-system.png
		dot -Tpng index-binary-system-flowchart.dot -o index-binary-system-flowchart.png
		texi2pdf pvector.texi
		cd ..
test:
		cd tests
		guile tests.scm
		cd ..
