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
  (pvector-internal length offset root tail tail-length)
  pvector?
  (length      pvector-length      set-pvector-length)
  (offset      pvector-offset      set-pvector-offset)
  (root        pvector-root        set-pvector-root)
  (tail        pvector-tail        set-pvector-tail)
  (tail-length pvector-tail-length set-pvector-tail-length))

(define (tree-capacity offset)
  (ash branching-factor offset))

;; tree-full? is a predicate to determine whether
;; a tree with "length" elements is full (with no
;; free leaves)
;; The answer is calculated from the arithmetic left
;; bit shift of branching factor (wich is number of
;; bits in the branching-factor, multiplied by tree
;; level number) compared with current length of the
;; elements in the tree (not in tail).
;; A tree will be full for offset=0 and
;; length=branching-factor, for ofsset=offset-step
;; and branching-factor^2 elements and so on.
(define (tree-full? length offset)
  (= length (tree-capacity offset)))

(define (branch-from-index index offset)
  (logand (ash index (- offset))
          index-mask))

(define (pvector-tail-offset pv)
  (- (pvector-length pv)
     (pvector-tail-length pv)))

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

(define (new-leaf start-index leaf node offset)
  (let ([node (if (unspecified? node)
                  (make-leaf)
                  (vector-copy node))]
        [branch (branch-from-index start-index offset)])
    (if (= offset 0) ; Are we in a leaf?
        leaf
        (begin
          (vector-set!
           node
           branch
           (new-leaf start-index
                     leaf
                     (vector-ref node branch)
                     (- offset offset-step)))
          node))))

(define (pvector-tree-ref pv index)
  (define (ref-aux node offset)
    (let* ([cur-branch (branch-from-index index offset)]
           [cur-val (vector-ref node cur-branch)])
      (if (= offset 0)
          cur-val
          (ref-aux cur-val (- offset offset-step)))))
  (let ([length (pvector-length pv)]
        [offset (pvector-offset pv)]
        [root (pvector-root pv)])
    (ref-aux root offset)))

(define (pvector-push-leaf pv start-index leaf)
 (let ([length (pvector-length pv)]
       [offset (pvector-offset pv)]
       [old-root (pvector-root pv)]
       [tail (pvector-tail pv)]
       [tail-length (pvector-tail-length pv)]
       [tail-offset (pvector-tail-offset pv)])
   (if (tree-full? tail-offset offset)
       ;; the tree is full, the new root is needed
       (let ([new-root (make-leaf)])
         (vector-set! new-root 0 old-root)
         (vector-set! new-root 1 (new-leaf start-index leaf (vector-ref new-root 1) offset))
         (pvector-internal
          length
          (+ offset offset-step)
          new-root
          tail
          tail-length))
       ;; We have some space in the current tree
       (pvector-internal
        length
        offset
        (new-leaf start-index leaf old-root offset)
        tail
        tail-length))))

(define (drop-path start-index node offset)
  (let* ([branch (branch-from-index start-index offset)]
         [new-node (make-leaf)])
    (vector-copy! new-node 0 node 0 branch)
    (if ; It was a leaf
     (= offset 0)
     #f
     ;; We are working with the intermediate node
     (let ([b (drop-path start-index
                         (vector-ref node branch)
                         (- offset offset-step))])
       (cond
        ;; It was last branch, and it's now empty
        [(and (= start-index 0)(not b))
         #f]
        ;; Current branch is empty now
        [(not b)
         new-node]
        ;; Current branch still ist't empty
        [else (begin
                (vector-set! new-node branch b)
                new-node)])))))

(define (pvector-drop-leaf pv)
  (let* ([length (pvector-length pv)]
         [offset (pvector-offset pv)]
         [old-root (pvector-root pv)]
         [tail-offset (pvector-tail-offset pv)]
         [start-index (- tail-offset branching-factor)])
    (define (last-leaf node cur-offset)
      (if (= cur-offset 0)
          node
          (last-leaf (vector-ref node
                                 (branch-from-index
                                  start-index
                                  cur-offset))
                     (- cur-offset offset-step))))
    (assert (> length 0))
    (if (tree-full? (- tail-offset branching-factor) ; We can use a smaller tree
                    (- offset offset-step))
        (pvector-internal
         (1- length)
         (- offset offset-step)
         (vector-ref old-root 0)
         (last-leaf old-root offset)
         branching-factor)
        ;; We should delete only the path with
        ;; the last element
        (pvector-internal
         (1- length)
         offset
         (drop-path start-index old-root offset)
         (last-leaf old-root offset)
         branching-factor))))

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
  (pvector-internal 0 0 #f (make-leaf) 0))

(define (pvector . l)
  "(pvector l) -> pvector

   Creates persistent vector from argument list @code{l}"
  (list->pvector l))

(define (pvector-ref pv index)
  "(pvector-ref pv index) -> value

   Returns element of persistent vector @var{pv}
   with an index @var{index}"
  (assert (>= index 0))
  (assert (< index (pvector-length pv)))
  (let ([tail-offset (pvector-tail-offset pv)])
    (if (>= index tail-offset)
        (vector-ref (pvector-tail pv) (- index tail-offset))
        (pvector-tree-ref pv index))))

(define (pvector-set pv index v)
  "(pvector-set pv index v) -> pvector

   Returns a new pvector, like @var{pv}, but with a
   @var{v} at index @var{index}"
  (let ([length (pvector-length pv)]
        [offset (pvector-offset pv)]
        [root (pvector-root pv)]
        [tail (pvector-tail pv)]
        [tail-length (pvector-tail-length pv)]
        [tail-offset (pvector-tail-offset pv)])
    (assert (< index length))
    (assert (>= index 0))
    (if (>= index tail-offset)
        (let* ([new-tail (vector-copy tail)]
               [_ (vector-set!
                   new-tail
                   (- index tail-offset)
                   v)])
          (pvector-internal
           length
           offset
           root
           new-tail
           tail-length))
        (pvector-internal
         length
         offset
         (new-path index v root offset)
         tail
         tail-length))))

(define (pvector-foldi f acc pv)
  "(pvector-fold f acc pv) -> pvector

  Accepts function @code{f}, accumulator @code{acc}
  and pvector @code{pv}. Function @code{f} accepts
  an index of the current element, the current element
  of @code{pvector} and an accumulator
  value and returns a new accumulator value.
  @code{pvector-fold} returns a result of a sequential
  application of @code{f} to all the values of
  @code{pvector}, with accumulating intermediate
  results in @code{acc}"
  (assert (pvector? pv))
  (let* ([length (pvector-length pv)]
         [root (pvector-root pv)]
         [tail (pvector-tail pv)]
         [tail-offset (pvector-tail-offset pv)]
         [cur-index 0]
         [cur-acc acc]
         [height (current-height tail-offset)])
    (define (process-leaf l)
      (do ((i 0 (1+ i)))
          ((= i branching-factor))
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
                   (= cur-index tail-offset)))
            (process-node (vector-ref n i)
                          (1+ level)))))
    (when root
      (process-node root 1))
    (do ((i 0 (1+ i)))
        ((or (= i branching-factor)
             (= cur-index length)))
      (set! cur-acc
            (f cur-index
               (vector-ref tail i)
               cur-acc))
      (set! cur-index (1+ cur-index)))
    cur-acc))

(define (pvector-fold f acc pv)
  "(pvector-fold f acc pv) -> pvector

  Accepts function @code{f}, accumulator @code{acc}
  and pvector @code{pv}. Function @code{f} accepts
  the element of @code{pvector} and an accumulator value
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
  "(pvector-map f pv) -> pvector

  Apply @code{f} to all values of @code{pv}.
  Accepts function @code{f} and pvector @code{pv}. Function
  @code{f} accepts the element of @code{pv} and returns
  the respective value for the new @code{pvector}."
  (assert (pvector? pv))
  (let* ([length (pvector-length pv)]
         [offset (pvector-offset pv)]
         [root (pvector-root pv)]
         [new-tail (vector-copy (pvector-tail pv))]
         [tail-length (pvector-tail-length pv)]
         [tail-offset (pvector-tail-offset pv)]
         [cur-index 0]
         [height (current-height tail-offset)])
    (define (process-leaf l)
      (let ([leaf-copy (vector-copy l)])
        (do ((i 0 (1+ i)))
            ((= i branching-factor))
          (vector-set! leaf-copy
                       i
                       (f (vector-ref l i)))
          (set! cur-index (1+ cur-index)))
        leaf-copy))
    (define (process-node n level)
      (if (= level height)
          (process-leaf n)
          (let ([new-node (make-leaf)])
            (do ((i 0 (1+ i)))
                ((or (= i branching-factor)
                     (= cur-index tail-offset)))
              (vector-set! new-node
                           i
                           (process-node (vector-ref n i)
                                         (1+ level))))
            new-node)))
    (let ([new-root (if root
                        (process-node root 1)
                        #f)])
      (do ((i 0 (1+ i)))
          ((or (= i branching-factor)
               (= cur-index length)))
        (vector-set! new-tail
                     i
                     (f (vector-ref new-tail i)))
        (set! cur-index (1+ cur-index)))
      (pvector-internal length offset new-root new-tail tail-length))))

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
  (let ([length (pvector-length pv)]
        [offset (pvector-offset pv)]
        [root (pvector-root pv)]
        [tail (pvector-tail pv)]
        [tail-length (pvector-tail-length pv)])
    (if (= tail-length branching-factor) ; Is the tail full?
        (let ([new-pv (if root
                          (pvector-push-leaf pv
                                             (pvector-tail-offset pv)
                                             tail)
                          (pvector-internal length
                                            offset
                                            tail
                                            #f
                                            #f))]
              [new-tail (make-leaf)])
          (vector-set! new-tail 0 v)
          (pvector-internal
           (1+ length)
           (pvector-offset new-pv)
           (pvector-root new-pv)
           new-tail
           1))
        (let ([new-tail (vector-copy tail)])
          (vector-set! new-tail tail-length v)
          (pvector-internal
           (1+ length)
           offset
           root
           new-tail
           (1+ tail-length))))))

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
  (assert (pvector? pv))
  (let ([length (pvector-length pv)]
        [offset (pvector-offset pv)]
        [root (pvector-root pv)]
        [tail (pvector-tail pv)]
        [tail-length (pvector-tail-length pv)])
    (assert (> length 0))
    ;; Invariant: tail can't be empty
    ;; (except the special case of the
    ;; empty vector)
    (cond [(= length 1)
           (make-pvector)]
          [(> tail-length 1)
           (pvector-internal
            (1- length)
            offset
            root
            (vector-copy tail)
            (1- tail-length))]
          [else
           (pvector-drop-leaf pv)])))
