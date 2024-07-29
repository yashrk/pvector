;;; Commentary:
;;
;; pvector is a persistent vector library for Guile Scheme
;;
;;; Code:

(define-module (pvector)
  #:use-module (rnrs)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-9 gnu)
  #:use-module (scheme base)
  #:export (;; Predicates
            pvector?
            pvector-empty?
            ;; Constructors
            make-pvector
            pvector
            ;; ;; Access to elements
            pvector-ref
            pvector-set
            ;; Whole vector processing
            pvector-fold
            pvector-foldi
            pvector-map
            ;; Conversions
            pvector->list
            list->pvector
            ;; Length manipulation
            pvector-length
            pvector-push
            pvector-cons
            pvector-append
            pvector-drop-last))

;;; Utils

(define (intlog base n)
  (inexact->exact (floor (/ (log n) (log base)))))

(define (intlog2 n)
  (intlog 2 n))

;;; Internal definitions

(define branching-factor 32) ; Should be power of two

;; index-mask should contain 1 for all bits of index
;; (for example, for branching-factor 32 index-mask is 31,
;; because index in 32-cell array is between 0 and 31, and
;; it is stored in 5 rightmost bits of the number; and 31
;; is literally 1s in 5 rightmost bits: 0b0000_0000_0001_1111
(define index-mask (- branching-factor 1))

;; Number of bits in branching-factor
(define offset-step (intlog2 branching-factor))

;; Calculate trie height
(define (current-height len)
  (cond [(= len 0) 1]
        [(= len 1) 1]
        [else (1+ (intlog branching-factor (1- len)))]))

(define-immutable-record-type <pvector>
  (pvector-internal length offset root)
  pvector?
  (length pvector-length set-pvector-length)
  (offset pvector-offset set-pvector-offset)
  (root   pvector-root   set-pvector-root))

(define (tree-full? length offset)
  (= length (ash branching-factor offset)))

(define (branch-from-index index offset)
  (logand (ash index (- offset))
          index-mask))

(define (make-leaf)
  (make-vector branching-factor))

(define (new-path index value node offset)
  (let ([node (if (unspecified? node)
                  (make-leaf)
                  (vector-copy node))]
        [branch (branch-from-index index offset)])
    (if (= offset 0) ; Are we in a leaf?
        (begin
          (vector-set! node branch value)
          node)
        (begin
          (vector-set!
           node
           branch
           (new-path index
                     value
                     (vector-ref node branch)
                     (- offset offset-step)))
          node))))

(define (drop-path index node offset)
  (let* ([branch (branch-from-index index offset)]
         [new-node (make-leaf)])
    (vector-copy! new-node 0 node 0 branch)
    (cond
     ;; It was a last element in the leaf
     [(and (= offset 0)(= branch 0))
      #f]
     ;; It wasn't a last element in the leaf
     [(= offset 0)
      new-node]
     ;; We are working with the intermediate node
     [else
      (let ([b (drop-path index
                          (vector-ref node branch)
                          (- offset offset-step))])
        (cond
         ;; It was last branch, and it's now empty
         [(and (= index 0)(not b))
          #f]
         ;; Current branch is empty now
         [(not b)
          new-node]
         ;; Current branch still ist't empty
         [else (vector-set! new-node branch b)]))])))

;;;
;;; Public interface
;;;

(define (pvector-empty? pv)
  "(pvector-empty? pv) -> bool

  Checks if @code{pv} is empty"
  (assert (pvector? pv))
  (= (pvector-length pv) 0))

(define (make-pvector)
  "(make-pvector) -> pvector

   Creates empty persistent vector"
  (pvector-internal 0 0 (make-leaf)))

(define (pvector . l)
  "(pvector l) -> pvector

   Creates persistent vector from argument list @code{l}"
  (list->pvector l))

(define (pvector-ref pv index)
  "(pvector-ref pv index) -> value

   Returns element of persistent vector @var{pv}
   with an index @var{index}"
  (define (ref-aux node offset)
    (let* ([cur-branch (branch-from-index index offset)]
           [cur-val (vector-ref node cur-branch)])
      (if (= offset 0)
          cur-val
          (ref-aux cur-val (- offset offset-step)))))
  (let ([length (pvector-length pv)]
        [offset (pvector-offset pv)]
        [root (pvector-root pv)])
    (assert (< index length))
    (assert (>= index 0))
    (ref-aux root offset)))

(define (pvector-set pv index v)
  "(pvector-set pv index v) -> pvector

   Returns a new pvector, like @var{pv}, but with a
   @var{v} at index @var{index}"
  (let ([length (pvector-length pv)]
        [offset (pvector-offset pv)]
        [root (pvector-root pv)])
    (assert (< index length))
    (assert (>= index 0))
    (pvector-internal
     length
     offset
     (new-path index v root offset))))

(define (pvector-foldi f acc pv)
  "(pvector-fold f acc pv) -> pvector

  Accepts function @code{f}, accumulator @code{acc}
  and pvector @code{pv}. Function @code{f} accepts
  an index of the current element, the currnet element
  of @code{pvector} and an accumulator
  value and returns a new accumulator value.
  @code{pvector-fold} returns a result of a sequential
  application of @code{f} to all the values of
  @code{pvector}, with accumulating intermediate
  results in @code{acc}"
  (assert (pvector? pv))
  (let* ([length (pvector-length pv)]
         [root (pvector-root pv)]
         [cur-index 0]
         [cur-acc acc]
         [height (current-height length)])
    (define (process-leaf l)
      (do ((i 0 (1+ i)))
          ((or (= i branching-factor)
               (= cur-index length)))
        (set! cur-acc
              (f cur-index
                 (vector-ref l i)
                 cur-acc))
        (set! cur-index (1+ cur-index))))
    (define (process-node n level)
      (if (= level height)
          (process-leaf n)
          (do ((i 0 (1+ i)))
              ((or (= i branching-factor)
                   (= cur-index length)))
            (process-node (vector-ref n i)
                          (1+ level)))))
    (process-node root 1)
    cur-acc))

(define (pvector-fold f acc pv)
  "(pvector-fold f acc pv) -> pvector

  Accepts function @code{f}, accumulator @code{acc}
  and pvector @code{pv}. Function @code{f} accepts
  an accumulator value and the element of @code{pvector}
  and returns a new accumulator value.
  @code{pvector-fold} returns a result of a sequential
  application of @code{f} to all the values of
  @code{pvector}, with accumulating intermediate
  results in @code{acc}"
  (assert (pvector? pv))
  (let* ([length (pvector-length pv)])
    (define (apply-to-element i v acc)
      (f v acc))
    (pvector-foldi apply-to-element acc pv)))

(define (pvector-map f pv)
  (define (apply-to-element i v acc)
    (pvector-push acc (f v)))
  (assert (pvector? pv))
  (pvector-foldi apply-to-element (make-pvector) pv))

(define (pvector->list pv)
  "(pvector->list pv) -> list

   Converts values of pvector to list"
  (let ([rev-l (pvector-fold cons '() pv)])
    (reverse rev-l)))

(define (list->pvector l)
  "(list->pvector l) -> pvector

   Converts elements of list to pvector"
  (fold pvector-cons (make-pvector) l))

(define (pvector-push pv v)
  "(pvector-push pv v) -> pvector

  Adds @var{v} to the end of persistent vector @var{pv}"
  ;; We have 3 possible cases:
  ;; 1)the tree is full, we need a new root
  ;; 2)the rightmost leaf is full
  ;; 3)we have some space in the rightmost leaf
  ;; Cases 2 and 3 can be processed by
  ;; the same code.
  (let ([length (pvector-length pv)]
        [offset (pvector-offset pv)]
        [old-root (pvector-root pv)])
    (if (tree-full? length offset)
        ;; the tree is full, the new root is needed
        (let ([new-root (make-leaf)])
          (vector-set! new-root 0 old-root)
          (vector-set! new-root 1 (new-path length v (vector-ref new-root 1) offset))
          (pvector-internal
           (1+ length)
           (+ offset offset-step)
           new-root))
        ;; We have some space in the current tree
        (pvector-internal
         (1+ length)
         offset
         (new-path length v old-root offset)))))

(define (pvector-cons v pv)
  "(pvector-cons v pv) -> pvector

  Adds @var{v} to the end of persistent vector @var{pv}"
  (pvector-push pv v))

(define (pvector-append pv other)
  "(pvector-append pv other) -> vector

   Adds of element of persistent vector @var{other} to the
   end of the persistent vector @var{pv}"
  (assert (pvector? pv))
  (assert (pvector? other))
  (pvector-fold pvector-cons pv other))

(define (pvector-drop-last pv)
  "Returns a copy of persistent vector @var{pv}, but
   without a last element"
  ;; Here we also have 3 possible cases:
  ;; 1)we have more elements in rightmost leaf;
  ;; 2)we are going to delete the last element
  ;; from the current leaf, but we still need
  ;; the current number of levels to store the
  ;; vector of the current size;
  ;; 3)we should kill the root and make a tree
  ;; with smaller number of levels.
  ;;
  ;; Also we have one additional corner case:
  ;; we want never have in a tree empty nodes
  ;; _expect the root node_.
  (let ([length (pvector-length pv)]
        [offset (pvector-offset pv)]
        [old-root (pvector-root pv)])
    (assert (> length 0))
    (cond
     ;; Special case for root: it is never unspecified
     [(= length 1)
      (pvector-internal
       0
       0
       (make-leaf))]
     ;; We can use a smaller tree
     [(and (tree-full? (1- length) (- offset offset-step))
           (> offset 0))
      (pvector-internal
       (1- length)
       (1- offset)
       (vector-ref old-root 0))]
     ;; We should delete only the path with
     ;; the last element
     [else
      (pvector-internal
       (1- length)
       offset
       (drop-path (1- length) old-root offset))])))
