(define-module (color-tests)
  #:export (install-color-runner))

(use-modules (srfi srfi-64)
             (ice-9 format))

(define red "\x1B[31m")
(define green "\x1B[32m")
(define blue "\x1B[34m")
(define magenta "\x1B[35m")
(define reset "\x1B[0m")

(define (colorize color s)
  (string-append color s reset))

(define (color-runner filename)
  (let ((runner (test-runner-null))
	    (port (open-file filename "a"))
        (num-passed 0)
        (num-failed 0)
        (last-test "")
        (last-suite ""))
    (test-runner-on-group-begin! runner
      (lambda (runner suite-name count)
        (set! last-suite suite-name)
        (format #t "~A ~%" (colorize magenta suite-name))))
    (test-runner-on-test-begin! runner
      (lambda (runner)
        (let ([test-name (test-runner-test-name runner)])
          (set! last-test test-name)
          (format #t "~A " test-name))))
    (test-runner-on-test-end! runner
      (lambda (runner)
        (case (test-result-kind runner)
          ((pass xpass) (begin
                          (set! num-passed (1+ num-passed))
                          (format #t "~50t~A~%" (colorize green "OK"))))
          ((fail xfail) (begin
                          (set! num-failed (1+ num-failed))
                          (format port "~5t~A failed~%" last-test)
                          (format #t "~50t~A~%" (colorize red "FAIL"))))
          (else #t))))
    (test-runner-on-final! runner
      (lambda (runner)
        (format port
                "~A:~50t~d passed~70t~d failed~%"
                last-suite
                num-passed
                num-failed)
	    (close-output-port port)))
    runner))

(define (install-color-runner)
  (delete-file "tests.log")
  (test-runner-factory
   (lambda () (color-runner "tests.log"))))
