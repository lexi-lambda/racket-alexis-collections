#lang racket/base

(require racket/list)

(provide type-switch type-switch*)

; Lots of Racket functions exist like ‘append’ or ‘vector-append’ that are specialized for certain
; types, but they won't work for arguments of different types of sequences.
; These could be faster, though, so opting to use them when possible is a good idea.
(define (type-switch pred fast slow)
  (λ args (if (andmap pred args)
              (apply fast args)
              (apply slow args))))

; Like type-switch, but passes n arguments through (think map or foldl).
(define (type-switch* n pred fast slow)
  (λ args (if (andmap pred (drop args n))
              (apply fast args)
              (apply slow args))))
