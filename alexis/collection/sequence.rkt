#lang racket/base

(require (prefix-in base: racket/base)
         (prefix-in list: racket/list)
         (prefix-in sequence: racket/sequence)
         racket/generic
         racket/contract
         racket/vector
         racket/stream)

(provide gen:sequence sequence? sequence/c prop:sequence-empty
         cons first rest
         append reverse filter map
         sequence->stream sequence->list
         in
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

;; utility functions
;; ---------------------------------------------------------------------------------------------------

; Lots of Racket functions exist like ‘append’ or ‘vector-append’ that are specialized for certain
; types, but they won't work for arguments of different types of sequences.
; These could be faster, though, so opting to use them when possible is a good idea.
(define (type-switch pred fast slow)
  (λ args (if (andmap pred args)
              (apply fast args)
              (apply slow args))))

; Like type-switch, but passes n arguments through (think map or foldl).
(define (type-switch* n pred fast slow)
  (λ args (if (andmap pred (list:drop args n))
              (apply fast args)
              (apply slow args))))

; See the comment about prop:sequence-empty.
(define (-get-empty sequence)
  (cond
    [(list? sequence) '()]
    [(vector? sequence) #()]
    [(string? sequence) ""]
    [(bytes? sequence) #""]
    [(stream? sequence) empty-stream]
    [(base:sequence? sequence) empty-stream] ; sequences also use streams because sequences are crazy
    [(sequence-empty? sequence)
     (sequence-empty-ref sequence)]
    [else
     (let loop ([seq sequence])
       (if (empty? seq) seq
           (loop (rest seq))))]))

;; fallback implementations
;; ---------------------------------------------------------------------------------------------------

(define (-sequence-ref sequence index)
  (let loop ([seq sequence]
             [n index])
    (cond
      [(empty? seq)
       (raise-arguments-error 'ref "index too large for sequence"
                              "index" index
                              "in" sequence)]
      [(zero? n)
       (first seq)]
      [else
       (loop (rest seq))])))

(define (-append . sequences)
  (define empty (-get-empty (list:first sequences)))
  (reverse
   (let loop ([seq (list:first sequences)]
              [rst (list:rest sequences)]
              [acc empty])
     (if (empty? seq)
         (if (list:empty? rst) acc
             (loop (list:first rst) (list:rest rst) acc))
         (loop (rest seq) rst (cons (first seq) acc))))))

(define (-reverse sequence)
  (define empty (-get-empty sequence))
  (let loop ([seq sequence]
             [acc empty])
    (if (empty? seq) acc
        (loop (rest seq) (cons (first seq) acc)))))

(define (-filter pred sequence)
  (define empty (-get-empty sequence))
  (reverse
   (let loop ([seq sequence]
              [acc empty])
     (if (empty? seq) acc
         (loop (let ([fst (first seq)])
                 (if (pred fst)
                     (cons fst acc)
                     acc)))))))

(define (-map proc . sequences)
  (define empty (-get-empty (list:first sequences)))
  (define num-seqs (base:length sequences))
  (reverse
   (let loop ([seqs sequences]
              [acc empty])
     (define num-empty (list:count empty? seqs))
     (cond
       [(= num-empty num-seqs)
        acc]
       [(zero? num-empty)
        (let ([firsts (base:map first seqs)]
              [rests (base:map rest seqs)])
          (loop rests (cons (apply proc firsts) acc)))]
       [else
        (raise-arguments-error 'map "all sequences must be of the same length"
                               "given" sequences)]))))

(define (-sequence->stream sequence)
  (stream-cons (first sequence) (sequence->stream (rest sequence))))

(define (-sequence->list sequence)
  (base:reverse
   (let loop ([seq sequence]
              [lst '()])
     (if (empty? seq) lst
         (loop (rest seq) (base:cons (first seq) lst))))))

;; generic API
;; ---------------------------------------------------------------------------------------------------

; Unless the ‘empty’ value is known ahead of time, some algorithms will need to traverse sequences
; twice to find out what ‘empty’ is. If a sequence has the prop:sequence-empty property on it, then
; that will be used instead of performing an extra traversal.
(define-values (prop:sequence-empty sequence-empty? sequence-empty-ref)
  (make-struct-type-property 'sequence-empty))

(define-generics sequence
  ; primitives
  (cons value sequence)
  (first sequence)
  (rest sequence)
  (empty? sequence)
  
  ; derived
  (sequence-ref sequence index)
  (append sequence . rest)
  (reverse sequence)
  (filter pred sequence)
  (map proc sequence . rest)
  
  ; low-priority derived
  (sequence->stream sequence)
  (sequence->list sequence)
  
  #:fallbacks
  [(define sequence-ref -sequence-ref)
   (define append -append)
   (define reverse -reverse)
   (define filter -filter)
   (define sequence->stream -sequence->stream)
   (define sequence->list -sequence->list)]
  
  #:fast-defaults
  ([list?
    (define cons base:cons)
    (define first list:first)
    (define rest list:rest)
    (define empty? list:empty?)
    (define sequence-ref list-ref)
    (define append (type-switch list? base:append -append))
    (define reverse base:reverse)
    (define filter base:filter)
    (define map (type-switch* 1 list? base:map -map))
    (define sequence->stream base:sequence->stream)
    (define sequence->list values)]
   
   [vector?
    ; using cons/first/rest with vectors is probably a bad idea, anyway
    (define (cons v s) (vector-append (vector-immutable v) s))
    (define (first s) (vector-ref s 0))
    (define (rest s) (vector-copy s 1))
    (define (empty? s) (zero? (vector-length s)))
    (define sequence-ref vector-ref)
    (define append (type-switch vector? vector-append -append))
    ; is there any performant way to reverse a vector?
    ; (define reverse ...)
    (define filter vector-filter)
    (define map vector-map)
    (define sequence->stream base:sequence->stream)
    (define sequence->list vector->list)]
   
   [string?
    (define (cons v s)
      ; consing strings with anything except characters is a bad idea
      (unless (char? v)
        (raise-argument-error 'cons "char?" 0 v s))
      (string-append (string v) s))
    (define (first s) (string-ref s 0))
    (define (rest s) (substring s 1))
    (define (empty? s) (zero? (string-length s)))
    (define sequence-ref string-ref)
    (define append string-append)
    (define (filter proc s) (list->string (filter proc (string->list s))))
    ; I can't think of a better implementation for map on strings.
    ; (define map -map)
    (define sequence->stream base:sequence->stream)
    (define sequence->list string->list)]
   
   [bytes?
    (define (cons v s)
      ; consing byte strings with anything except bytes is a bad idea
      (unless (byte? v)
        (raise-argument-error 'cons "byte?" 0 v s))
      (bytes-append (bytes v) s))
    (define (first s) (bytes-ref s 0))
    (define (rest s) (subbytes s 1))
    (define (empty? s) (zero? (bytes-length s)))
    (define sequence-ref bytes-ref)
    (define append bytes-append)
    (define (filter proc s) (list->bytes (filter proc (bytes->list s))))
    ; I can't think of a better implementation for map on byte strings.
    ; (define map -map)
    (define sequence->stream base:sequence->stream)
    (define sequence->list bytes->list)]
   
   [stream?
    (define (cons v s) (stream-cons v s))
    (define first stream-first)
    (define rest stream-rest)
    (define empty? stream-empty?)
    (define sequence-ref stream-ref)
    (define append (type-switch stream? stream-append -append))
    (define filter stream-filter)
    (define map (type-switch* 1 stream? stream-map -map))
    (define sequence->stream values)
    (define sequence->list stream->list)]
   
   ; lots of things satisfy the ‘sequence?’ predicate
   [base:sequence?
    ; sequences are weird, so they just get converted to streams for certain operations
    (define (cons v s) (stream-cons v (base:sequence->stream s)))
    (define (first s) (stream-first (base:sequence->stream s)))
    (define (rest s) (stream-rest (base:sequence->stream s)))
    (define (empty? s) (stream-empty? (base:sequence->stream s)))
    (define sequence-ref sequence:sequence-ref)
    (define append (type-switch sequence? sequence:sequence-append -append))
    (define filter sequence:sequence-filter)
    (define map (type-switch* 1 sequence? sequence:sequence-map -map))
    (define sequence->stream base:sequence->stream)
    (define sequence->list sequence:sequence->list)]
   ))

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

(define-syntax-rule (in seq)
  (in-stream (sequence->stream seq)))
