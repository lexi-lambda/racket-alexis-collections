#lang racket/base

(require racket/generic
         racket/contract
         racket/dict
         alexis/collection/sequence)

(provide gen:indexable indexable? indexable/c
         ref)

(define-generics indexable
  (ref indexable index)
  #:fast-defaults
  ([hash? (define ref hash-ref)]
   [(and/c dict? (not/c list?)) (define ref dict-ref)]
   [sequence? (define ref sequence-ref)]))
