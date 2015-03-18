#lang racket/base

(require (for-syntax racket/base)
         (prefix-in base: racket/base)
         (prefix-in list: racket/list)
         (prefix-in sequence: racket/sequence)
         racket/generic
         racket/contract
         racket/vector
         racket/stream
         alexis/collection/sequence/constructed
         alexis/collection/sequence/flat)

(provide (all-from-out alexis/collection/sequence/constructed
                       alexis/collection/sequence/flat)
         gen:sequence sequence? sequence/c
         first append reverse filter map
         ; some functions need some aditional contracts
         (contract-out
          [empty? (sequence? . -> . boolean?)]
          [sequence-ref (sequence? exact-nonnegative-integer? . -> . any)]
          [second (sequence? . -> . any)]
          [third (sequence? . -> . any)]
          [fourth (sequence? . -> . any)]
          [fifth (sequence? . -> . any)]
          [sixth (sequence? . -> . any)]
          [seventh (sequence? . -> . any)]
          [eighth (sequence? . -> . any)]
          [ninth (sequence? . -> . any)]
          [tenth (sequence? . -> . any)])
         ; pair is cons from racket/base
         (rename-out [base:cons pair]))

;; generic API
;; ---------------------------------------------------------------------------------------------------

(define-generics sequence
  (first sequence)
  (empty? sequence)
  (sequence-ref sequence index)
  (append sequence . rest)
  (reverse sequence)
  (filter pred sequence)
  (map proc sequence . rest)
  
  #:defaults
  ([flat-sequence?
    (define (first seq) (flat-ref seq 0))
    (define empty? flat-empty?)
    (define sequence-ref flat-ref)
    (define append flat-append)
    (define reverse flat-reverse)
    (define filter flat-filter)
    (define map flat-map)]
   [constructed-sequence?
    (define first cons-first)
    (define empty? cons-empty?)
    (define sequence-ref cons-ref)
    (define append cons-append)
    (define reverse cons-reverse)
    (define filter cons-filter)
    (define map cons-map)]))

;; additional API
;; ---------------------------------------------------------------------------------------------------

(define (second seq) (sequence-ref seq 1))
(define (third seq) (sequence-ref seq 2))
(define (fourth seq) (sequence-ref seq 3))
(define (fifth seq) (sequence-ref seq 4))
(define (sixth seq) (sequence-ref seq 5))
(define (seventh seq) (sequence-ref seq 6))
(define (eighth seq) (sequence-ref seq 7))
(define (ninth seq) (sequence-ref seq 8))
(define (tenth seq) (sequence-ref seq 9))
