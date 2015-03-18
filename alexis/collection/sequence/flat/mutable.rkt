#lang racket/base

(require racket/generic
         racket/list
         racket/function
         racket/contract
         racket/vector
         "../../private/utils.rkt"
         "private/mutable-vector.rkt")

(provide gen:flat-mutable-sequence flat-mutable-sequence? flat-mutable-sequence/c
         prop:flat-mutable-list-allocator prop:flat-mutable-vector-allocator
         flat-mutable-append flat-mutable-reverse flat-mutable-filter flat-mutable-map
         flat-mutable-reverse! flat-mutable-map!
         (contract-out
          [flat-mutable-length (flat-mutable-sequence? . -> . exact-nonnegative-integer?)]
          [flat-mutable-ref (flat-mutable-sequence? exact-nonnegative-integer? . -> . any)]
          [flat-mutable-set! (flat-mutable-sequence? exact-nonnegative-integer? any/c . -> . any)]
          [flat-mutable-copy ([flat-mutable-sequence?]
                              [exact-nonnegative-integer? exact-nonnegative-integer?]
                              . ->* . any)]
          [flat-mutable-empty? (flat-mutable-sequence? . -> . boolean?)]
          [flat-mutable-copy! ([flat-mutable-sequence? exact-nonnegative-integer?
                                                       flat-mutable-sequence?]
                               [exact-nonnegative-integer? exact-nonnegative-integer?]
                               . ->* . any)]
          [flat-mutable->vector (flat-mutable-sequence? . -> . (and/c vector? (not/c immutable?)))]))

;; utility functions
;; ---------------------------------------------------------------------------------------------------

; Fallback functions may need access to the structure allocators. Since passing a list to the
; allocator would likely be unnecessarily expensive, a vector-based allocator can be provided
; instead.
(define (-get-allocators seq)
  (cond
    [(vector? seq)
     (values #f (curryr mutable-vector-copy #t))]
    [(string? seq)
     (values list->string #f)]
    [(bytes? seq)
     (values list->bytes #f)]
    [else
     (let ([list-allocator (and (has-list-allocator? seq) (get-list-allocator seq))]
           [vector-allocator (and (has-vector-allocator? seq) (get-vector-allocator seq))])
       (if (or list-allocator vector-allocator)
           (values list-allocator vector-allocator)
           (raise (exn:fail:contract
                   "gen:flat-mutable-sequence: a list allocator or vector allocator must be present"
                   (current-continuation-marks)))))]))

;; ---------------------------------------------------------------------------------------------------

(define (-flat-mutable-copy seq [s 0] [e (flat-mutable-length seq)])
  (let-values ([(lst-a vec-a) (-get-allocators seq)])
    (if vec-a
        (let ([vec (make-vector (- e s))])
          (for ([i (in-range s e)]
                [d (in-naturals)])
            (vector-set! vec d (flat-mutable-ref seq i)))
          (vec-a vec))
        (lst-a (for/list ([i (in-range s e)])
                 (flat-mutable-ref seq i))))))

(define (-flat-mutable-append . seqs)
  (let-values ([(len) (apply + (map flat-mutable-length seqs))]
               [(lst-a vec-a) (-get-allocators (first seqs))])
    (if vec-a
        (let ([vec (make-vector len)]
              [c 0])
          (for* ([seq (in-list seqs)]
                 [i (in-range (flat-mutable-length seq))])
            (vector-set! vec c (flat-mutable-ref seq i))
            (set! c (add1 c)))
          (vec-a vec))
        (lst-a (for*/list ([seq (in-list seqs)]
                           [i (in-range (flat-mutable-length seq))])
                 (flat-mutable-ref seq i))))))

(define (-flat-mutable-reverse seq)
  (let-values ([(lst-a vec-a) (-get-allocators seq)]
               [(len) (flat-mutable-length seq)])
    (if vec-a
        (let ([vec (make-vector len)])
          (for* ([i (in-range len)]
                 [j (in-value (- len i 1))])
            (vector-set! vec i (flat-mutable-ref seq j)))
          (vec-a vec))
        (lst-a (for/fold ([lst '()])
                         ([i (in-range len)])
                 (cons (flat-mutable-ref seq i) lst))))))

(define (-flat-mutable-filter pred seq)
  (let-values ([(lst-a vec-a) (-get-allocators seq)]
               [(len) (flat-mutable-length seq)])
    (if vec-a
        (let ([vec (make-vector len)]
              [out-len 0])
          (for* ([i (in-range len)]
                 [e (in-value (flat-mutable-ref seq i))])
            (when (pred e)
              (vector-set! vec out-len e)
              (set! out-len (add1 out-len))))
          (vec-a (vector-copy vec 0 out-len)))
        (lst-a (for*/list ([i (in-range len)]
                           [e (in-value (flat-mutable-ref seq i))]
                           #:when (pred e))
                 e)))))

(define (-flat-mutable-map proc . seqs)
  (let-values ([(lst-a vec-a) (-get-allocators (first seqs))]
               [(lens) (map flat-mutable-length seqs)])
    (unless (andmap (λ (v) (= v (first lens))) (rest lens))
      (raise-arguments-error 'flat-mutable-map "all sequences must be of the same length"
                             "given" seqs))
    (if vec-a
        (let ([vec (make-vector (first lens))])
          (for ([i (in-range (first lens))])
            (vector-set! vec i
                         (apply proc (map (λ (seq) (flat-mutable-ref seq i)) seqs))))
          (vec-a vec))
        (lst-a (for/list ([i (in-range (first lens))])
                 (apply proc (map (λ (seq) (flat-mutable-ref seq i)) seqs)))))))

(define (-flat-mutable-copy! dest d-s src [s-s 0] [s-e (flat-mutable-length src)])
  (for ([i (in-range s-s s-e)])
    (flat-mutable-set! dest (+ d-s i) (flat-mutable-ref src i))))

(define (-flat-mutable-reverse! seq)
  (let ([len (flat-mutable-length seq)])
    (for* ([i (in-range (quotient len 2))]
           [j (in-value (- len i 1))])
      (let ([a (flat-mutable-ref seq i)]
            [b (flat-mutable-ref seq j)])
        (vector-set! seq i b)
        (vector-set! seq j a)))))

(define (-flat-mutable-map! proc . seqs)
  (let-values ([(lens) (map flat-mutable-length seqs)])
    (unless (andmap (λ (v) (= v (first lens))) (rest lens))
      (raise-arguments-error 'flat-mutable-map! "all sequences must be of the same length"
                             "given" seqs))
    (let ([seq (first seqs)])
      (for ([i (in-range (first lens))])
        (flat-mutable-set! seq i
                           (apply proc (map (λ (seq) (flat-mutable-ref seq i)) seqs)))))))

(define (-flat-mutable-empty? seq)
  (zero? (flat-mutable-length seq)))

(define (-flat-mutable->vector seq)
  (let* ([len (flat-mutable-length seq)]
         [vec (make-vector len)])
    (for ([i (in-range len)])
      (vector-set! vec i (flat-mutable-ref seq i)))
    vec))

;; ---------------------------------------------------------------------------------------------------

(define-values (prop:flat-mutable-list-allocator has-list-allocator? get-list-allocator)
  (make-struct-type-property 'flat-mutable-list-allocator))

(define-values (prop:flat-mutable-vector-allocator has-vector-allocator? get-vector-allocator)
  (make-struct-type-property 'flat-mutable-vector-allocator))

(define-generics flat-mutable-sequence
  ; primitives
  (flat-mutable-length flat-mutable-sequence)
  (flat-mutable-ref flat-mutable-sequence index)
  (flat-mutable-set! flat-mutable-sequence index value)
  
  ; allocator-based
  (flat-mutable-copy flat-mutable-sequence [start] [end])
  (flat-mutable-append flat-mutable-sequence . rest)
  (flat-mutable-reverse flat-mutable-sequence)
  (flat-mutable-filter pred flat-mutable-sequence)
  (flat-mutable-map proc flat-mutable-sequence . rest)
  
  ; derived
  (flat-mutable-empty? flat-mutable-sequence)
  (flat-mutable-copy! flat-mutable-sequence start src [src-start] [src-end])
  (flat-mutable-reverse! flat-mutable-sequence)
  (flat-mutable-map! proc flat-mutable-sequence . rest)
  
  ; low-priority derived
  (flat-mutable->vector flat-mutable-sequence)
  
  #:fallbacks
  [(define flat-mutable-append -flat-mutable-append)
   (define flat-mutable-reverse -flat-mutable-reverse)
   (define flat-mutable-filter -flat-mutable-filter)
   (define flat-mutable-map -flat-mutable-map)
   (define flat-mutable-empty? -flat-mutable-empty?)
   (define flat-mutable-copy! -flat-mutable-copy!)
   (define flat-mutable-reverse! -flat-mutable-reverse!)
   (define flat-mutable-map! -flat-mutable-map!)
   (define flat-mutable->vector -flat-mutable->vector)]
  
  #:fast-defaults
  ([(and/c vector? (not/c immutable?))
    (define flat-mutable-length vector-length)
    (define flat-mutable-ref vector-ref)
    (define flat-mutable-set! vector-set!)
    (define flat-mutable-copy mutable-vector-copy)
    (define flat-mutable-append (type-switch vector?
                                             (compose mutable-vector-copy vector-append)
                                             -flat-mutable-append))
    ; just use the fallback for reverse(!)
    ; (define flat-mutable-reverse ...)
    (define flat-mutable-filter (compose mutable-vector-copy vector-filter))
    (define flat-mutable-map (type-switch* 1 vector?
                                           (compose mutable-vector-copy vector-map)
                                           -flat-mutable-map))
    (define (flat-mutable-empty? seq) (zero? (vector-length seq)))
    (define flat-mutable-copy! vector-copy!)
    (define flat-mutable-map! (type-switch* 1 vector? vector-map! -flat-mutable-map!))
    (define flat-mutable->vector mutable-vector-copy)]
   [(and/c string? (not/c immutable?))
    (define flat-mutable-length string-length)
    (define flat-mutable-ref string-ref)
    (define flat-mutable-set! string-set!)
    (define (flat-mutable-copy seq [s 0] [e (string-length seq)])
      (substring seq s e))
    (define flat-mutable-append (type-switch string? string-append -flat-mutable-append))
    ; just use the fallback for these
    ; (define flat-mutable-reverse(!) ...)
    ; (define flat-mutable-filter ...)
    ; (define flat-mutable-map(!) ...)
    (define (flat-mutable-empty? seq) (zero? (string-length seq)))
    (define flat-mutable-copy! string-copy!)]
   [(and/c bytes? (not/c immutable?))
    (define flat-mutable-length bytes-length)
    (define flat-mutable-ref bytes-ref)
    (define flat-mutable-set! bytes-set!)
    (define (flat-mutable-copy seq [s 0] [e (bytes-length seq)])
      (subbytes seq s e))
    (define flat-mutable-append (type-switch bytes? bytes-append -flat-mutable-append))
    ; just use the fallback for these
    ; (define flat-mutable-reverse(!) ...)
    ; (define flat-mutable-filter ...)
    ; (define flat-mutable-map(!) ...)
    (define (flat-mutable-empty? seq) (zero? (bytes-length seq)))
    (define flat-mutable-copy! bytes-copy!)]))
