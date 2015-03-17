#lang racket/base

(require (prefix-in base: racket/base)
         racket/generic
         racket/contract
         racket/set
         racket/dict
         racket/sequence
         racket/stream)

(provide gen:countable countable? countable/c
         (contract-out
          [length (countable? . -> . exact-nonnegative-integer?)]))

(define-generics countable
  (length countable)
  #:fast-defaults
  ([list? (define length base:length)]
   [vector? (define length vector-length)]
   [string? (define length string-length)]
   [bytes? (define length bytes-length)]
   [hash? (define length hash-count)]
   [set? (define length set-count)]
   [dict? (define length dict-count)]
   [stream? (define length stream-length)]
   ; lots of things satisfy the ‘sequence?’ predicate
   [sequence? (define length sequence-length)]))
