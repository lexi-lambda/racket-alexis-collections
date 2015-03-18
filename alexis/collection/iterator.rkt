#lang racket/base

(require (for-syntax racket/base)
         racket/generic)

(provide gen:iterator iterator? iterator/c
         gen:iterable iterable? iterable/c
         in)

(define-generics iterator
  (iterator-empty? iterator)
  (iterator-value iterator)
  (iterator-next iterator))

(define-generics iterable
  (iterator iterable)
  #:defaults
  ; calling iterator on an iterator just returns itself
  ([iterator? (define iterator values)]))

(define-sequence-syntax in
  (λ () #'iterator)
  (λ (stx)
    (syntax-case stx ()
      [[(e) (_ seq)]
       #'[(e)
          (:do-in
           ([(s) seq])
           (unless (iterable? s)
             (raise-argument-error 'in "iterable?" s))
           ([v s])
           (not (iterator-empty? v))
           ([(e) (iterator-value v)]
            [(r) (iterator-next v)])
           #t #t
           [r])]])))
