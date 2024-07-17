(use-modules (statprof)
             (srfi srfi-1)
             (srfi srfi-43)
             (ice-9 match)
             (ice-9 vlist))
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
  (/ (statprof-accumulated-time) iteration-count))

(define (vector-random-reads vector-size iteration-count)
  (let ([big-vector (list->vector (iota vector-size 0))])
    (statprof-start)
    (do ((i 1 (1+ i)))
        ((> i iteration-count))
      (vector-ref big-vector (random vector-size)))
    (statprof-stop))
  (/ (statprof-accumulated-time) iteration-count))

(define (vlist-random-reads vlist-size iteration-count)
  (let ([big-vlist (list->vlist (iota vlist-size 0))])
    (statprof-start)
    (do ((i 1 (1+ i)))
        ((> i iteration-count))
      (vlist-ref big-vlist (random vlist-size)))
    (statprof-stop))
  (/ (statprof-accumulated-time) iteration-count))

(define (pvector-random-reads vector-size iteration-count)
  (let ([big-pvector (list->pvector (iota vector-size 0))])
    (statprof-start)
    (do ((i 1 (1+ i)))
        ((> i iteration-count))
      (pvector-ref big-pvector (random vector-size)))
    (statprof-stop))
  (/ (statprof-accumulated-time) iteration-count))

;; Time vs vector size, with list
(define (random-reads-short)
  (let* ([iteration-count 100000]
         [size-list '(10 100 1000 10000 100000)]
         [_ (statprof-reset 0 0 #t)]
         [vector-results (map
                          (lambda (size)
                            (vector-random-reads size iteration-count))
                          size-list)]
         [_ (statprof-reset 0 0 #t)]
         [vlist-results (map
                         (lambda (size)
                           (vlist-random-reads size iteration-count))
                         size-list)]
         [_ (statprof-reset 0 0 #t)]
         [list-results (map (lambda (size)
                              (list-random-reads size iteration-count))
                            size-list)]
         [_ (statprof-reset 0 0 #t)]
         [pvector-results (map
                           (lambda (size)
                             (pvector-random-reads size iteration-count))
                           size-list)]
         [_ (statprof-reset 0 0 #t)]
         [results (zip size-list pvector-results vector-results vlist-results list-results)])
    (format #t "size~16tpvector~32tvector~48tvlist~64tlist~%")
    (map (lambda (result)
           (match result
             ((size pvector vector vlist list)
              (format #t "~d~16t~12f~32t~12f~48t~12f~64t~12f~%" size pvector vector vlist list))))
         results)))


;; Time vs vector size, without list
(define (random-reads)
  (let* ([iteration-count 100000]
         [size-list '(10 100 1000 10000 100000 1000000 10000000)]
         [_ (statprof-reset 0 0 #t)]
         [vlist-results (map
                         (lambda (size)
                           (vlist-random-reads size iteration-count))
                         size-list)]
         [_ (statprof-reset 0 0 #t)]
         [vector-results (map
                          (lambda (size)
                            (vector-random-reads size iteration-count))
                          size-list)]
         [_ (statprof-reset 0 0 #t)]
         [pvector-results (map
                           (lambda (size)
                             (pvector-random-reads size iteration-count))
                           size-list)]
         [_ (statprof-reset 0 0 #t)]
         [results (zip size-list pvector-results vlist-results vector-results)])
    (format #t "size~16tpvector~32tvlist~48tvector~%")
    (map (lambda (result)
           (match result
             ((size pvector vlist vector)
              (format #t "~d~16t~12f~32t~12f~48t~12f~%" size pvector vlist vector))))
         results)))

(format #t "Random reads benchmark, small, with linked list...\t")
(with-output-to-file "random-reads-short.data" random-reads-short)
(format #t "\x1B[35mDONE\x1B[0m\n")

(format #t "Random reads benchmark, big...\t\t\t\t")
(with-output-to-file "random-reads.data" random-reads)
(format #t "\x1B[35mDONE\x1B[0m\n")
