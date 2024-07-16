.PHONY: test
.ONESHELL: test
test:
		cd tests
		guile tests.scm
		cd ..
