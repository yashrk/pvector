(use-modules ((srfi srfi-1)))
(use-modules (srfi srfi-64))
(add-to-load-path (dirname (current-filename)))
(use-modules (color-tests))
(add-to-load-path "..")
(use-modules (pvector))

(install-color-runner)

(test-begin "predicates")
(let ([empty (make-pvector)]
      [not-empty (list->pvector (iota 100 0))]
      [not-a-vector '()]
      [also-not-a-vector '(1 2 3 4 5)])
  (test-eqv "pvector? is true for pvector" (pvector? empty) #t)
  (test-eqv "pvector? is really true for pvector" (pvector? not-empty) #t)
  (test-eqv "pvector? is false for #f" (pvector? not-a-vector) #f)
  (test-eqv "pvector? is false for list" (pvector? also-not-a-vector) #f)
  (test-eqv "pvector-empty? is true for empty pvector" (pvector-empty? empty) #t)
  (test-eqv "pvector-empty? is false for non-empty pvector" (pvector-empty? not-empty) #f)
  (test-error "pvector-empty? is for pvectors" #t (pvector-empty? not-a-vector))
  (test-error "pvector-empty? is only for pvectors" #t (pvector-empty? also-not-a-vector)))
(test-end "predicates")

(test-begin "vector-create")
(let* ([v1 (make-pvector)]
       [v2 (pvector 0 0)]
       [v3 (list->pvector '(0 1 2 3 4 5 6 7 8 9))])
  (test-eqv "Empty pvector size" (pvector-length v1) 0)
  (test-eqv "Pvector emptyness check" (pvector-empty? v1) #t)
  (test-eqv "Two-element pvector size" (pvector-length v2) 2)
  (test-eqv "10-element pvector size" (pvector-length v3) 10)
  (test-eqv "Getting element from pvector (begin)" (pvector-ref v3 0) 0)
  (test-eqv "Getting element from pvector (middle)" (pvector-ref v3 3) 3)
  (test-eqv "Getting element from pvector (end)" (pvector-ref v3 5) 5))
(test-end "vector-create")

(test-begin "vector-ref")
(let ([v (list->pvector '(0 1 2 3 4 5 6 7 8 9))])
  (test-eqv "Getting element from pvector (begin)" (pvector-ref v 0) 0)
  (test-eqv "Getting element from pvector (middle)" (pvector-ref v 5) 5)
  (test-eqv "Getting element from pvector (end)" (pvector-ref v 9) 9)
  (test-error "Index out of range check" #t (pvector-ref v (pvector-length v)))
  (test-error "Another index out of range check" #t (pvector-ref v 100500))
  (test-error "Negative index check" #t (pvector-ref v 100500)))
(test-end "vector-ref")

(test-begin "vector-set")
(let* ([v1 (list->pvector (iota 8192))]
       [v2 (pvector-set v1 0 100500)]
       [v3 (pvector-set v2 8191 100501)]
       [v4 (pvector-push v3 -1000000)]
       [v5 (pvector-set v4 8192 100502)])
  (test-eqv "Purity check 1" (pvector-ref v1 0) 0)
  (test-eqv "Purity check 2" (pvector-ref v2 8191) 8191)
  (test-eqv "Purity check 3" (pvector-length v1) 8192)
  (test-eqv "Purity check 4" (pvector-length v2) 8192)
  (test-eqv "Purity check 5" (pvector-length v3) 8192)
  (test-eqv "Purity check 6" (pvector-ref v4 8192) -1000000)
  (test-error "Purity check 7" #t (pvector-ref v3 8192))
  (test-eqv "Setter check 1" (pvector-ref v2 0) 100500)
  (test-eqv "Setter check 2" (pvector-ref v3 8191) 100501)
  (test-eqv "Setter check 3" (pvector-ref v5 8192) 100502))
(test-end "vector-set")

(test-begin "vector-fold")
(let* ([l (iota 10)]
       [v1 (list->pvector l)]
       [v2 (list->pvector (reverse l))])
  (test-eqv "Fold check" (pvector-fold + 0 v1) 45)
  (test-eqv "Fold check" (pvector-fold + 0 v2) 45)
  (test-eqv "Fold check" (pvector-fold - 0 v1) 5)
  (test-eqv "Fold check" (pvector-fold - 0 v2) (- 5))
  (test-equal "Fold check" (pvector-fold cons '() v2) l))
(test-end "vector-fold")

(test-begin "vector-append")
(let* ([v (make-pvector)]
       [v1 (pvector-append v (pvector 100500))]
       [v2 (pvector 1 2 3 4 5)]
       [v3 (pvector-append v1 v2)])
  (test-eqv "Appended value check" (pvector-ref v1 0) 100500)
  (test-eqv "Initial pvector size check" (pvector-length v) 0)
  (test-eqv "Initial pvector emptyness check" (pvector-empty? v) #t)
  (test-eqv "Is extended pvector non-empty?" (pvector-empty? v) #t)
  (test-eqv "Extended pvector size check" (pvector-length v1) 1)
  (test-eqv "Other extended pvector size check" (pvector-length v2) 5)
  (test-eqv "Yet another extended pvector size check" (pvector-length v3) 6)
  (test-eqv "Order in append result (begin)" (pvector-ref v3 0) 100500)
  (test-eqv "Order in append result (middle)" (pvector-ref v3 1) 1)
  (test-eqv "Order in append result (end)" (pvector-ref v3 5) 5)
  (test-equal "Append result to list" (pvector->list v3) '(100500 1 2 3 4 5)))
(test-end "vector-append")

(test-begin "vector-of-strings")
(let ([v (pvector "aaa" "bbb" "ccc")])
  (test-eqv "String pvector element" (pvector-ref v 1) "bbb")
  (test-eqv "String from pvector element" (string-ref (pvector-ref v 0) 2) #\a))
(test-end "vector-of-strings")

(test-begin "big-vector")
(let* ([v1 (list->pvector (iota 256 0))]
       [v2 (pvector-append v1 v1)]
       [v3 (pvector-append v2 v2)]
       [v4 (pvector-append v3 v3)]
       [v5 (pvector-append v4 v4)]
       [v6 (pvector-append v5 v5)])
  (test-eqv "Vector of 256 elements" (pvector-length v1) 256)
  (test-eqv "Vector of 512 elements" (pvector-length v2) 512)
  (test-eqv "Vector of 1024 elements" (pvector-length v3) 1024)
  (test-eqv "Vector of 2048 elements" (pvector-length v4) 2048)
  (test-eqv "Vector of 4096 elements" (pvector-length v5) 4096)
  (test-eqv "Vector of 8192 elements" (pvector-length v6) 8192)
  (test-eqv "Big vector content 1" (pvector-ref v6 0) 0)
  (test-eqv "Big vector content 2" (pvector-ref v6 255) 255)
  (test-eqv "Big vector content 3" (pvector-ref v6 256) 0)
  (test-eqv "Big vector content 4" (pvector-ref v6 511) 255)
  (test-eqv "Big vector content 5" (pvector-ref v6 7936) 0)
  (test-eqv "Big vector content 6" (pvector-ref v6 8191) 255)
  (test-error "Index out of range check 1" #t (pvector-ref v (pvector-length v)))
  (test-error "Index out of range check 2" #t (pvector-ref v 8192)))
(test-end "big-vector")
