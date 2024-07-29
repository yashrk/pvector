(use-modules (statprof)
             (srfi srfi-1)
             (srfi srfi-43)
             (ice-9 match)
             (ice-9 vlist))
(add-to-load-path "..")
(use-modules (pvector))

(set! *random-state* (random-state-from-platform))

;;; Random reads

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

(define (vhash-random-reads vhash-size iteration-count)
  (let ([big-vhash (alist->vhash (fold (lambda (v l)
                                         (cons (cons v v) l))
                                       '()
                                       (iota vhash-size)))])
    (statprof-start)
    (do ((i 1 (1+ i)))
        ((> i iteration-count))
      (vhash-assoc (random vhash-size) big-vhash))
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

;;; Random writes

(define (pvector-random-writes vector-size iteration-count)
  (let ([big-pvector (list->pvector (iota vector-size))]
        [indices (map (lambda (_) (random vector-size)) (iota vector-size))]
        [values (map (lambda (_) (random 100)) (iota vector-size))])
    (statprof-start)
    (fold (lambda (iv pv)
            (match iv
              ((index value)
               (pvector-set pv index value))))
          big-pvector
          (zip indices values))
    (statprof-stop))
  (/ (statprof-accumulated-time) iteration-count))

(define (vector-random-writes vector-size iteration-count)
  (let ([big-vector (list->vector (iota vector-size))]
        [indices (map (lambda (_) (random vector-size)) (iota vector-size))]
        [values (map (lambda (_) (random 100)) (iota vector-size))])
    (statprof-start)
    (map (lambda (iv)
           (match iv
             ((index value)
              (vector-set! big-vector index value))))
          (zip indices values))
    (statprof-stop))
  (/ (statprof-accumulated-time) iteration-count))

(define (vhash-random-writes vhash-size iteration-count)
  (let ([big-vhash (alist->vhash (fold (lambda (v l)
                                         (cons (cons v v) l))
                                       '()
                                       (iota vhash-size)))]
        [indices (map (lambda (_) (random vhash-size)) (iota vhash-size))]
        [values (map (lambda (_) (random 100)) (iota vhash-size))])
    (statprof-start)
    (fold (lambda (iv vh)
            (match iv
              ((index value)
               (vhash-cons index value vh))))
          big-vhash
          (zip indices values))
    (statprof-stop))
  (/ (statprof-accumulated-time) iteration-count))

;;; Maps and folds

;; Maps

(define (pvector-maps vector-size iteration-count)
  (let ([big-pvector (list->pvector (iota vector-size))])
    (statprof-start)
    (pvector-map (lambda (v)
                   (1+ v))
                 big-pvector)
    (statprof-stop))
  (/ (statprof-accumulated-time) iteration-count))

(define (vector-maps vector-size iteration-count)
  (let ([big-vector (list->vector (iota vector-size))])
    (statprof-start)
    (vector-map (lambda (i v)
                   (1+ v))
                 big-vector)
    (statprof-stop))
  (/ (statprof-accumulated-time) iteration-count))

(define (vlist-maps vlist-size iteration-count)
  (let ([big-vlist (list->vlist (iota vlist-size))])
    (statprof-start)
    (vlist-map (lambda (v)
                 (1+ v))
               big-vlist)
    (statprof-stop))
  (/ (statprof-accumulated-time) iteration-count))

(define (list-maps list-size iteration-count)
  (let ([big-list (iota list-size)])
    (statprof-start)
    (map (lambda (v)
           (1+ v))
         big-list)
    (statprof-stop))
  (/ (statprof-accumulated-time) iteration-count))

(define (vhash-maps vhash-size iteration-count)
  (let ([big-vhash (alist->vhash (fold (lambda (v l)
                                         (cons (cons v v) l))
                                       '()
                                       (iota vhash-size)))])
    (statprof-start)
    (vhash-fold (lambda (k v acc)
                  (vhash-cons k (1+ v) acc))
                big-vhash
                big-vhash)
    (statprof-stop))
  (/ (statprof-accumulated-time) iteration-count))

;; Folds

(define (pvector-folds vector-size iteration-count)
  (let ([big-pvector (list->pvector (iota vector-size))])
    (statprof-start)
    (pvector-fold (lambda (v sum)
                    (+ v sum))
                  0
                  big-pvector)
    (statprof-stop))
  (/ (statprof-accumulated-time) iteration-count))

(define (vector-folds vector-size iteration-count)
  (let ([big-vector (list->vector (iota vector-size))])
    (statprof-start)
    (vector-fold (lambda (i sum v)
                    (+ v sum))
                  0
                  big-vector)
    (statprof-stop))
  (/ (statprof-accumulated-time) iteration-count))

(define (list-folds list-size iteration-count)
  (let ([big-list (iota list-size)])
    (statprof-start)
    (fold (lambda (v sum)
            (+ v sum))
          0
          big-list)
    (statprof-stop))
  (/ (statprof-accumulated-time) iteration-count))

(define (vlist-folds vector-size iteration-count)
  (let ([big-vlist (list->vlist (iota vector-size))])
    (statprof-start)
    (vlist-fold (lambda (v sum)
                  (+ v sum))
                0
                big-vlist)
    (statprof-stop))
  (/ (statprof-accumulated-time) iteration-count))

(define (vhash-folds vhash-size iteration-count)
  (let ([big-vhash (alist->vhash (fold (lambda (v l)
                                         (cons (cons v v) l))
                                       '()
                                       (iota vhash-size)))])
    (statprof-start)
    (vhash-fold (lambda (k v sum)
                  (+ v sum))
                0
                big-vhash)
    (statprof-stop))
  (/ (statprof-accumulated-time) iteration-count))

;;; Benchmarks

;; Reads. Time vs vector size, with list
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
         [vhash-results (map
                         (lambda (size)
                           (vhash-random-reads size iteration-count))
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
         [results (zip size-list
                       pvector-results
                       vector-results
                       vlist-results
                       list-results
                       vhash-results)])
    (format #t "size~16tpvector~32tvector~48tvlist~64tlist~80tvhash~%")
    (map (lambda (result)
           (match result
             ((size pvector vector vlist list vhash)
              (format #t "~d~16t~12,10f~32t~12,10f~48t~12,10f~64t~12,10f~80t~12,10f~%" size pvector vector vlist list vhash))))
         results)))

;; Reads. Time vs vector size, without list
(define (random-reads)
  (let* ([iteration-count 100000]
         [size-list '(10 100 1000 10000 100000 1000000 10000000)]
         [_ (statprof-reset 0 0 #t)]
         [vlist-results (map
                         (lambda (size)
                           (vlist-random-reads size iteration-count))
                         size-list)]
         [_ (statprof-reset 0 0 #t)]
         [vhash-results (map
                         (lambda (size)
                           (vhash-random-reads size iteration-count))
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
         [results (zip size-list pvector-results vlist-results vector-results vhash-results)])
    (format #t "size~16tpvector~32tvlist~48tvector~64tvhash~%")
    (map (lambda (result)
           (match result
             ((size pvector vlist vector vhash)
              (format #t "~d~16t~12,10f~32t~12,10f~48t~12,10f~64t~12,10f~%" size pvector vlist vector vhash))))
         results)))

;; Writes
(define (random-writes)
  (let* ([iteration-count 100000]
         [size-list '(10 100 1000 10000 100000 1000000)]
         [_ (statprof-reset 0 0 #t)]
         [pvector-results (map
                           (lambda (size)
                             (pvector-random-writes size iteration-count))
                           size-list)]
         [_ (statprof-reset 0 0 #t)]
         [vector-results (map
                           (lambda (size)
                             (vector-random-writes size iteration-count))
                           size-list)]
         [_ (statprof-reset 0 0 #t)]
         [vhash-results (map
                         (lambda (size)
                           (vhash-random-writes size iteration-count))
                           size-list)]
         [_ (statprof-reset 0 0 #t)]
         [results (zip size-list pvector-results vector-results vhash-results)])
    (format #t "size~16tpvector~32tvector~48tvhash~%")
    (map (lambda (result)
           (match result
             ((size pvector vector vhash)
              (format #t "~d~16t~12,10f~32t~12,10f~48t~12,10f~%" size pvector vector vhash))))
         results)))

;; Maps
(define (maps)
    (let* ([iteration-count 100000]
         [size-list '(10 100 1000 10000 100000 1000000 10000000)]
         [_ (statprof-reset 0 0 #t)]
         [pvector-results (map
                          (lambda (size)
                            (pvector-maps size iteration-count))
                          size-list)]
         [_ (statprof-reset 0 0 #t)]
         [vector-results (map
                          (lambda (size)
                            (vector-maps size iteration-count))
                          size-list)]
         [_ (statprof-reset 0 0 #t)]
         [vlist-results (map
                          (lambda (size)
                            (vlist-maps size iteration-count))
                          size-list)]
         [_ (statprof-reset 0 0 #t)]
         [list-results (map
                        (lambda (size)
                          (list-maps size iteration-count))
                        size-list)]
         [_ (statprof-reset 0 0 #t)]
         [vhash-results (map
                         (lambda (size)
                           (vhash-maps size iteration-count))
                         size-list)]
         [_ (statprof-reset 0 0 #t)]
         [results (zip size-list
                       pvector-results
                       vector-results
                       vlist-results
                       list-results
                       vhash-results)])
      (format #t "size~16tpvector~32tvector~48tvlist~64tlist~80tvhash~%")
      (map (lambda (result)
             (match result
               ((size pvector vector vlist list vhash)
                (format #t "~d~16t~12,10f~32t~12,10f~48t~12,10f~64t~12,10f~80t~12,10f~%" size pvector vector vlist list vhash))))
         results)))

;; Folds
(define (folds)
    (let* ([iteration-count 100000]
         [size-list '(10 100 1000 10000 100000 10000000)]
         [_ (statprof-reset 0 0 #t)]
         [pvector-results (map
                          (lambda (size)
                            (pvector-folds size iteration-count))
                          size-list)]
         [_ (statprof-reset 0 0 #t)]
         [vector-results (map
                          (lambda (size)
                            (vector-folds size iteration-count))
                          size-list)]
         [_ (statprof-reset 0 0 #t)]
         [vlist-results (map
                          (lambda (size)
                            (vlist-folds size iteration-count))
                          size-list)]
         [_ (statprof-reset 0 0 #t)]
         [list-results (map
                        (lambda (size)
                          (list-folds size iteration-count))
                        size-list)]
         [_ (statprof-reset 0 0 #t)]
         [vhash-results (map
                         (lambda (size)
                           (vhash-folds size iteration-count))
                         size-list)]
         [_ (statprof-reset 0 0 #t)]
         [results (zip size-list
                       pvector-results
                       vector-results
                       vlist-results
                       list-results
                       vhash-results)])
      (format #t "size~16tpvector~32tvector~48tvlist~64tlist~80tvhash~%")
      (map (lambda (result)
             (match result
               ((size pvector vector vlist list vhash)
                (format #t "~d~16t~12,10f~32t~12,10f~48t~12,10f~64t~12,10f~80t~12,10f~%" size pvector vector vlist list vhash))))
         results)))

;;; Benchmarks. Plots

(format #t "Random reads benchmark, small, with linked list...\t")
(with-output-to-file "random-reads-short.data" random-reads-short)
(format #t "\x1B[35mDONE\x1B[0m\n")

(format #t "Random reads benchmark, big...\t\t\t\t")
(with-output-to-file "random-reads.data" random-reads)
(format #t "\x1B[35mDONE\x1B[0m\n")

(format #t "Random writes benchmark...\t\t\t\t")
(with-output-to-file "random-writes.data" random-writes)
(format #t "\x1B[35mDONE\x1B[0m\n")

(format #t "Maps over collections...\t\t\t\t")
(with-output-to-file "maps.data" maps)
(format #t "\x1B[35mDONE\x1B[0m\n")

(format #t "Folds over collections...\t\t\t\t")
(with-output-to-file "folds.data" folds)
(format #t "\x1B[35mDONE\x1B[0m\n")
