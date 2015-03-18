#lang racket/base

(provide mutable-vector-copy)

(define (mutable-vector-copy vec [re-use? #f])
  (if (and re-use? (not (immutable? vec)))
      vec
      (let ([new-vec (make-vector (vector-length vec))])
        (vector-copy! new-vec 0 vec))))
