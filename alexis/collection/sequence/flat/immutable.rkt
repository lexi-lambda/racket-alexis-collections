#lang racket/base

(require racket/generic
         racket/list
         racket/function
         racket/contract
         racket/vector
         "../../private/utils.rkt")

(provide gen:flat-immutable-sequence flat-immutable-sequence? flat-immutable-sequence/c
         prop:flat-immutable-list-allocator prop:flat-immutable-vector-allocator
         flat-immutable-append flat-immutable-reverse flat-immutable-filter flat-immutable-map
         (contract-out
          [flat-immutable-length (flat-immutable-sequence? . -> . exact-nonnegative-integer?)]
          [flat-immutable-ref (flat-immutable-sequence? exact-nonnegative-integer? . -> . any)]
          [flat-immutable-copy ([flat-immutable-sequence?]
                                [exact-nonnegative-integer? exact-nonnegative-integer?]
                                . ->* . any)]
          [flat-immutable-empty? (flat-immutable-sequence? . -> . boolean?)]
          [flat-immutable->vector (flat-immutable-sequence? . -> . (and/c vector? immutable?))]))

;; utility functions
;; ---------------------------------------------------------------------------------------------------

; Fallback functions may need access to the structure allocators. Since passing a list to the
; allocator would likely be unnecessarily expensive, a vector-based allocator can be provided
; instead.
(define (-get-allocators seq)
  (cond
    [(vector? seq)
     (values #f vector->immutable-vector)]
    [(string? seq)
     (values (compose string->immutable-string list->string) #f)]
    [(bytes? seq)
     (values (compose bytes->immutable-bytes list->bytes) #f)]
    [else
     (let ([list-allocator (and (has-list-allocator? seq) (get-list-allocator seq))]
           [vector-allocator (and (has-vector-allocator? seq) (get-vector-allocator seq))])
       (if (or list-allocator vector-allocator)
           (values list-allocator vector-allocator)
           (raise (exn:fail:contract
                   "gen:flat-immutable-sequence: a list allocator or vector allocator must be present"
                   (current-continuation-marks)))))]))

;; fallback functions
;; ---------------------------------------------------------------------------------------------------

(define (-flat-immutable-copy seq [s 0] [e (flat-immutable-length seq)])
  (let-values ([(lst-a vec-a) (-get-allocators seq)])
    (if vec-a
        (let ([vec (make-vector (- e s))])
          (for ([i (in-range s e)]
                [d (in-naturals)])
            (vector-set! vec d (flat-immutable-ref seq i)))
          (vec-a vec))
        (lst-a (for/list ([i (in-range s e)])
                 (flat-immutable-ref seq i))))))

(define (-flat-immutable-append . seqs)
  (let-values ([(len) (apply + (map flat-immutable-length seqs))]
               [(lst-a vec-a) (-get-allocators (first seqs))])
    (if vec-a
        (let ([vec (make-vector len)]
              [c 0])
          (for* ([seq (in-list seqs)]
                 [i (in-range (flat-immutable-length seq))])
            (vector-set! vec c (flat-immutable-ref seq i))
            (set! c (add1 c)))
          (vec-a vec))
        (lst-a (for*/list ([seq (in-list seqs)]
                           [i (in-range (flat-immutable-length seq))])
                 (flat-immutable-ref seq i))))))

(define (-flat-immutable-reverse seq)
  (let-values ([(lst-a vec-a) (-get-allocators seq)]
               [(len) (flat-immutable-length seq)])
    (if vec-a
        (let ([vec (make-vector len)])
          (for* ([i (in-range len)]
                 [j (in-value (- len i 1))])
            (vector-set! vec i (flat-immutable-ref seq j)))
          (vec-a vec))
        (lst-a (for/fold ([lst '()])
                         ([i (in-range len)])
                 (cons (flat-immutable-ref seq i) lst))))))

(define (-flat-immutable-filter pred seq)
  (let-values ([(lst-a vec-a) (-get-allocators seq)]
               [(len) (flat-immutable-length seq)])
    (if vec-a
        (let ([vec (make-vector len)]
              [out-len 0])
          (for* ([i (in-range len)]
                 [e (in-value (flat-immutable-ref seq i))])
            (when (pred e)
              (vector-set! vec out-len e)
              (set! out-len (add1 out-len))))
          (vec-a (vector-copy vec 0 out-len)))
        (lst-a (for*/list ([i (in-range len)]
                           [e (in-value (flat-immutable-ref seq i))]
                           #:when (pred e))
                 e)))))

(define (-flat-immutable-map proc . seqs)
  (let-values ([(lst-a vec-a) (-get-allocators (first seqs))]
               [(lens) (map flat-immutable-length seqs)])
    (unless (andmap (λ (v) (= v (first lens))) (rest lens))
      (raise-arguments-error 'flat-immutable-map "all sequences must be of the same length"
                             "given" seqs))
    (if vec-a
        (let ([vec (make-vector (first lens))])
          (for ([i (in-range (first lens))])
            (vector-set! vec i
                         (apply proc (map (λ (seq) (flat-immutable-ref seq i)) seqs))))
          (vec-a vec))
        (lst-a (for/list ([i (in-range (first lens))])
                 (apply proc (map (λ (seq) (flat-immutable-ref seq i)) seqs)))))))

(define (-flat-immutable-empty? seq)
  (zero? (flat-immutable-length seq)))

(define (-flat-immutable->vector seq)
  (let* ([len (flat-immutable-length seq)]
         [vec (make-vector len)])
    (for ([i (in-range len)])
      (vector-set! vec i (flat-immutable-ref seq i)))
    (vector->immutable-vector vec)))

;; generic API
;; ---------------------------------------------------------------------------------------------------

(define-values (prop:flat-immutable-list-allocator has-list-allocator? get-list-allocator)
  (make-struct-type-property 'flat-immutable-list-allocator))

(define-values (prop:flat-immutable-vector-allocator has-vector-allocator? get-vector-allocator)
  (make-struct-type-property 'flat-immutable-vector-allocator))

(define-generics flat-immutable-sequence
  ; primitives
  (flat-immutable-length flat-immutable-sequence)
  (flat-immutable-ref flat-immutable-sequence index)
  
  ; allocator-based
  (flat-immutable-copy flat-immutable-sequence [start] [end])
  (flat-immutable-append flat-immutable-sequence . rest)
  (flat-immutable-reverse flat-immutable-sequence)
  (flat-immutable-filter pred flat-immutable-sequence)
  (flat-immutable-map proc flat-immutable-sequence . rest)
  
  ; derived
  (flat-immutable-empty? flat-immutable-sequence)
  
  ; low-priority derived
  (flat-immutable->vector flat-immutable-sequence)
  
  #:fallbacks
  [(define flat-immutable-append -flat-immutable-append)
   (define flat-immutable-reverse -flat-immutable-reverse)
   (define flat-immutable-filter -flat-immutable-filter)
   (define flat-immutable-map -flat-immutable-map)
   (define flat-immutable-empty? -flat-immutable-empty?)
   (define flat-immutable->vector -flat-immutable->vector)]
  
  #:fast-defaults
  ([(and/c vector? immutable?)
    (define flat-immutable-length vector-length)
    (define flat-immutable-ref vector-ref)
    (define flat-immutable-copy vector-copy)
    (define flat-immutable-append (type-switch vector? vector-append -flat-immutable-append))
    ; just use the fallback for reverse
    ; (define flat-immutable-reverse ...)
    (define flat-immutable-filter vector-filter)
    (define flat-immutable-map (type-switch* 1 vector? vector-map -flat-immutable-map))
    (define (flat-immutable-empty? seq) (zero? (vector-length seq)))
    (define flat-immutable->vector values)]
   [(and/c string? immutable?)
    (define flat-immutable-length string-length)
    (define flat-immutable-ref string-ref)
    (define (flat-immutable-copy seq [s 0] [e (string-length seq)])
      (string->immutable-string (substring seq s e)))
    (define flat-immutable-append (type-switch string?
                                               (compose string->immutable-string string-append)
                                               -flat-immutable-append))
    ; just use the fallback for these
    ; (define flat-immutable-reverse ...)
    ; (define flat-immutable-filter ...)
    ; (define flat-immutable-map ...)
    (define (flat-immutable-empty? seq) (zero? (string-length seq)))]
   [(and/c bytes? immutable?)
    (define flat-immutable-length bytes-length)
    (define flat-immutable-ref bytes-ref)
    (define (flat-immutable-copy seq [s 0] [e (bytes-length seq)])
      (bytes->immutable-bytes (subbytes seq s e)))
    (define flat-immutable-append (type-switch bytes?
                                               (compose bytes->immutable-bytes bytes-append)
                                               -flat-immutable-append))
    ; just use the fallback for these
    ; (define flat-immutable-reverse ...)
    ; (define flat-immutable-filter ...)
    ; (define flat-immutable-map ...)
    (define (flat-immutable-empty? seq) (zero? (bytes-length seq)))]))
