#lang racket/base

(require racket/generic
         racket/contract
         alexis/collection/sequence/flat/immutable
         alexis/collection/sequence/flat/mutable)

(provide (all-from-out alexis/collection/sequence/flat/immutable
                       alexis/collection/sequence/flat/mutable)
         gen:flat-sequence flat-sequence? flat-sequence/c
         flat-append flat-reverse flat-filter flat-map
         flat-reverse! flat-map!
         (contract-out
          [flat-length (flat-sequence? . -> . exact-nonnegative-integer?)]
          [flat-ref (flat-sequence? exact-nonnegative-integer? . -> . any)]
          [flat-set! (flat-sequence? exact-nonnegative-integer? any/c . -> . any)]
          [flat-copy ([flat-sequence?]
                              [exact-nonnegative-integer? exact-nonnegative-integer?]
                              . ->* . any)]
          [flat-empty? (flat-sequence? . -> . boolean?)]
          [flat-copy! ([flat-sequence? exact-nonnegative-integer?
                                                       flat-sequence?]
                               [exact-nonnegative-integer? exact-nonnegative-integer?]
                               . ->* . any)]
          [flat->vector (flat-sequence? . -> . (and/c vector?))]))

(define-generics flat-sequence
  ; primitives
  (flat-length flat-sequence)
  (flat-ref flat-sequence index)
  (flat-set! flat-sequence index value)
  
  ; allocator-based
  (flat-copy flat-sequence [start] [end])
  (flat-append flat-sequence . rest)
  (flat-reverse flat-sequence)
  (flat-filter pred flat-sequence)
  (flat-map proc flat-sequence . rest)
  
  ; derived
  (flat-empty? flat-sequence)
  (flat-copy! flat-sequence start src [src-start] [src-end])
  (flat-reverse! flat-sequence)
  (flat-map! proc flat-sequence . rest)
  
  ; low-priority derived
  (flat->vector flat-sequence)
  
  #:defaults
  ([flat-immutable-sequence?
    (define flat-length flat-immutable-length)
    (define flat-ref flat-immutable-ref)
    (define flat-copy flat-immutable-copy)
    (define flat-append flat-immutable-append)
    (define flat-reverse flat-immutable-reverse)
    (define flat-filter flat-immutable-filter)
    (define flat-map flat-immutable-map)
    (define flat-empty? flat-immutable-empty?)
    (define flat->vector flat-immutable->vector)]
   [flat-mutable-sequence?
    (define flat-length flat-mutable-length)
    (define flat-ref flat-mutable-ref)
    (define flat-set! flat-mutable-set!)
    (define flat-copy flat-mutable-copy)
    (define flat-append flat-mutable-append)
    (define flat-reverse flat-mutable-reverse)
    (define flat-filter flat-mutable-filter)
    (define flat-map flat-mutable-map)
    (define flat-empty? flat-mutable-empty?)
    (define flat-copy! flat-mutable-copy!)
    (define flat-reverse! flat-mutable-reverse!)
    (define flat-map! flat-mutable-map!)
    (define flat->vector flat-mutable->vector)]))
