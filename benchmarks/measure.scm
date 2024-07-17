(use-modules (statprof))
(use-modules (srfi srfi-1))
(use-modules (srfi srfi-43))
(use-modules (ice-9 match))
(add-to-load-path "..")
(use-modules (pvector))

(set! *random-state* (random-state-from-platform))

(define (list-random-reads list-size iteration-count)
  (let ([big-list (iota list-size 0)])
    (statprof-start)
    (do ((i 1 (1+ i)))
        ((> i iteration-count))
      (list-ref big-list (random list-size)))
    (statprof-stop))
  (statprof-accumulated-time))

(define (vector-random-reads vector-size iteration-count)
  (let ([big-vector (list->vector (iota vector-size 0))])
    (statprof-start)
    (do ((i 1 (1+ i)))
        ((> i iteration-count))
      (vector-ref big-vector (random vector-size)))
    (statprof-stop))
  (statprof-accumulated-time))

(define (pvector-random-reads vector-size iteration-count)
  (let ([big-pvector (list->pvector (iota vector-size 0))])
    (statprof-start)
    (do ((i 1 (1+ i)))
        ((> i iteration-count))
      (pvector-ref big-pvector (random vector-size)))
    (statprof-stop))
  (statprof-accumulated-time))

;; Time vs vector size, with list
(define (random-reads-short)
  (let* ([iteration-count 100000]
         [size-list '(10 100 1000 10000 100000)]
         [pvector-results (map
                           (lambda (size)
                             (pvector-random-reads size iteration-count))
                           size-list)]
         [vector-results (map
                          (lambda (size)
                            (vector-random-reads size iteration-count))
                          size-list)]
         [list-results (map (lambda (size)
                              (list-random-reads size iteration-count))
                            size-list)]
         [results (zip size-list pvector-results vector-results list-results)])
    (format #t "size\tpvector\t\tvector\t\tlist~%")
    (map (lambda (result)
           (match result
             ((size pvector vector list)
              (format #t "~d\t~f\t~f\t~f~%" size pvector vector list))))
         results)))


;; Time vs vector size, without list
(define (random-reads)
  (let* ([iteration-count 100000]
         [size-list '(10 100 1000 10000 100000 1000000 10000000)]
         [pvector-results (map
                           (lambda (size)
                             (pvector-random-reads size iteration-count))
                           size-list)]
         [vector-results (map
                          (lambda (size)
                            (vector-random-reads size iteration-count))
                          size-list)]
         [results (zip size-list pvector-results vector-results)])
    (format #t "size\t\tpvector\t\tvector~%")
    (map (lambda (result)
           (match result
             ((size pvector vector)
              (format #t "~d~16t~f~32t~f~%" size pvector vector))))
         results)))

(format #t "Random reads benchmark, small, with linked list...\t")
(with-output-to-file "random-reads-short.data" random-reads-short)
(format #t "\x1B[35mDONE\x1B[0m\n")

(format #t "Random reads benchmark, big...\t\t\t\t")
(with-output-to-file "random-reads.data" random-reads)
(format #t "\x1B[35mDONE\x1B[0m\n")
