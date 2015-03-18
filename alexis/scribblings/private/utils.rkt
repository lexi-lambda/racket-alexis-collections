#lang racket/base

(require scribble/manual
         scribble/eval)

(provide reftech
         evaluator)

(define (reftech . content)
  (apply tech #:doc '(lib "scribblings/reference/reference.scrbl") content))

(define evaluator
  (make-eval-factory
   '(racket/generic
     alexis/collection)
   #:lang 'racket))
