(define-module (color-tests)
  #:export (install-color-runner))

(use-modules (srfi srfi-64))
(use-modules (ice-9 format))

(define red "\x1B[31m")
(define green "\x1B[32m")
(define blue "\x1B[34m")
(define magenta "\x1B[35m")
(define reset "\x1B[0m")

(define (colorize color s)
  (string-append color s reset))

(define (color-runner filename)
  (let ((runner (test-runner-null))
	    (port (open-output-file filename))
        (num-passed 0)
        (num-failed 0))
    (test-runner-on-group-begin! runner
      (lambda (runner suite-name count)
        (format #t "~A ~%" (colorize magenta suite-name))))
    (test-runner-on-test-begin! runner
      (lambda (runner)
        (format #t "~A " (test-runner-test-name runner))))
    (test-runner-on-test-end! runner
      (lambda (runner)
        (case (test-result-kind runner)
          ((pass xpass) (begin
                          (set! num-passed (+ num-passed 1))
                          (format #t "~50t~A~%" (colorize green "OK"))))
          ((fail xfail) (begin
                          (set! num-failed (+ num-failed 1))
                          (format #t "~50t~A~%" (colorize red "FAIL"))))
          (else #t))))
    (test-runner-on-final! runner
      (lambda (runner)
        (format port "Passing tests: ~d.~%Failing tests: ~d.~%"
                num-passed num-failed)
	    (close-output-port port)))
    runner))

(define (install-color-runner)
  (test-runner-factory
   (lambda () (color-runner "tests.log"))))
