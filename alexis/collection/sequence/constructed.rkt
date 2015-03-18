#lang racket/base

(require (for-syntax racket/base)
         (prefix-in base: racket/base)
         (prefix-in list: racket/list)
         (prefix-in sequence: racket/sequence)
         racket/generic
         racket/contract
         racket/stream
         "../private/utils.rkt")

(provide gen:constructed-sequence constructed-sequence? constructed-sequence/c prop:cons-empty
         cons cons-first cons-rest rest
         cons-append cons-reverse cons-filter cons-map
         cons->stream cons->list
         in-cons
         ; some functions need some aditional contracts
         (contract-out
          [cons-empty? (sequence? . -> . boolean?)]
          [cons-ref (sequence? exact-nonnegative-integer? . -> . any)])
         ; pair is cons from racket/base
         (rename-out [base:cons pair]))

;; utility functions
;; ---------------------------------------------------------------------------------------------------

; See the comment about prop:sequence-empty.
(define (-get-empty sequence)
  (cond
    [(list? sequence) '()]
    [(stream? sequence) empty-stream]
    [(base:sequence? sequence) empty-stream] ; sequences also use streams because sequences are crazy
    [(has-cons-empty? sequence)
     (cons-empty-ref sequence)]
    [else
     (let loop ([seq sequence])
       (if (cons-empty? seq) seq
           (loop (cons-rest seq))))]))

;; fallback implementations
;; ---------------------------------------------------------------------------------------------------

(define (-cons-ref sequence index)
  (let loop ([seq sequence]
             [n index])
    (cond
      [(cons-empty? seq)
       (raise-arguments-error 'ref "index too large for sequence"
                              "index" index
                              "in" sequence)]
      [(zero? n)
       (cons-first seq)]
      [else
       (loop (cons-rest seq))])))

(define (-cons-append . sequences)
  (define empty (-get-empty (list:first sequences)))
  (reverse
   (let loop ([seq (list:first sequences)]
              [rst (list:rest sequences)]
              [acc empty])
     (if (cons-empty? seq)
         (if (list:empty? rst) acc
             (loop (list:first rst) (list:rest rst) acc))
         (loop (cons-rest seq) rst (cons (cons-first seq) acc))))))

(define (-cons-reverse sequence)
  (define empty (-get-empty sequence))
  (let loop ([seq sequence]
             [acc empty])
    (if (cons-empty? seq) acc
        (loop (cons-rest seq) (cons (cons-first seq) acc)))))

(define (-cons-filter pred sequence)
  (define empty (-get-empty sequence))
  (reverse
   (let loop ([seq sequence]
              [acc empty])
     (if (cons-empty? seq) acc
         (loop (let ([fst (cons-first seq)])
                 (if (pred fst)
                     (cons fst acc)
                     acc)))))))

(define (-cons-map proc . sequences)
  (define empty (-get-empty (list:first sequences)))
  (define num-seqs (base:length sequences))
  (reverse
   (let loop ([seqs sequences]
              [acc empty])
     (define num-empty (list:count cons-empty? seqs))
     (cond
       [(= num-empty num-seqs)
        acc]
       [(zero? num-empty)
        (let ([firsts (base:map cons-first seqs)]
              [rests (base:map cons-rest seqs)])
          (loop rests (cons (apply proc firsts) acc)))]
       [else
        (raise-arguments-error 'cons-map "all sequences must be of the same length"
                               "given" sequences)]))))

(define (-cons->stream sequence)
  (stream-cons (cons-first sequence) (sequence->stream (cons-rest sequence))))

(define (-cons->list sequence)
  (base:reverse
   (let loop ([seq sequence]
              [lst '()])
     (if (cons-empty? seq) lst
         (loop (cons-rest seq) (base:cons (cons-first seq) lst))))))

;; generic API
;; ---------------------------------------------------------------------------------------------------

; Unless the ‘empty’ value is known ahead of time, some algorithms will need to traverse sequences
; twice to find out what ‘empty’ is. If a sequence has the prop:cons-empty property on it, then that
; will be used instead of performing an extra traversal.
(define-values (prop:cons-empty has-cons-empty? cons-empty-ref)
  (make-struct-type-property 'cons-empty))

(define-generics constructed-sequence
  ; primitives
  (cons value constructed-sequence)
  (cons-first constructed-sequence)
  (cons-rest constructed-sequence)
  (cons-empty? constructed-sequence)
  
  ; derived
  (cons-ref constructed-sequence index)
  (cons-append constructed-sequence . rest)
  (cons-reverse constructed-sequence)
  (cons-filter pred constructed-sequence)
  (cons-map proc constructed-sequence . rest)
  
  ; low-priority derived
  (cons->stream constructed-sequence)
  (cons->list constructed-sequence)
  
  #:fallbacks
  [(define cons-ref -cons-ref)
   (define cons-append -cons-append)
   (define cons-reverse -cons-reverse)
   (define cons-filter -cons-filter)
   (define cons-map -cons-map)
   (define cons->stream -cons->stream)
   (define cons->list -cons->list)]
  
   #:fast-defaults
  ([list?
    (define cons base:cons)
    (define cons-first list:first)
    (define cons-rest list:rest)
    (define cons-empty? list:empty?)
    (define cons-ref list-ref)
    (define cons-append (type-switch list? base:append -cons-append))
    (define cons-reverse base:reverse)
    (define cons-filter base:filter)
    (define cons-map (type-switch* 1 list? base:map -cons-map))
    (define cons->stream base:sequence->stream)
    (define cons->list values)]
   
   [stream?
    (define (cons v s) (stream-cons v s))
    (define cons-first stream-first)
    (define cons-rest stream-rest)
    (define cons-empty? stream-empty?)
    (define cons-ref stream-ref)
    (define cons-append (type-switch stream? stream-append -cons-append))
    (define cons-filter stream-filter)
    (define cons-map (type-switch* 1 stream? stream-map -cons-map))
    (define cons->stream values)
    (define cons->list stream->list)]
   
   ; lots of things satisfy the ‘sequence?’ predicate
   [base:sequence?
    ; sequences are weird, so they just get converted to streams for certain operations
    (define (cons v s) (stream-cons v (base:sequence->stream s)))
    (define (cons-first s) (stream-first (base:sequence->stream s)))
    (define (cons-rest s) (stream-rest (base:sequence->stream s)))
    (define (cons-empty? s) (stream-empty? (base:sequence->stream s)))
    (define cons-ref sequence:sequence-ref)
    (define cons-append (type-switch base:sequence? sequence:sequence-append -cons-append))
    (define cons-filter sequence:sequence-filter)
    (define cons-map (type-switch* 1 base:sequence? sequence:sequence-map -cons-map))
    (define cons->stream base:sequence->stream)
    (define cons->list sequence:sequence->list)]
   ))

;; additional API
;; ---------------------------------------------------------------------------------------------------

(define rest cons-rest)

(define in-cons/proc
  (procedure-rename
   (λ (seq) (in-stream (sequence->stream seq)))
   'in))

(define-sequence-syntax in-cons
  (λ () #'in-cons/proc)
  (λ (stx)
    (syntax-case stx ()
      [[(e) (_ seq)]
       #'[(e)
          (:do-in
           ([(s) seq])
           (unless (constructed-sequence? s)
             (raise-argument-error 'in-cons "constructed-sequence?" s))
           ([v s])
           (not (cons-empty? v))
           ([(e) (cons-first v)]
            [(r) (cons-rest v)])
           #t #t
           [r])]])))

