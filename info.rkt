#lang info

(define collection 'multi)

(define name "alexis-collections")
(define version "0.3")

(define implies '("collections"))

(define deps
  '("alexis-util"
    "base"
    "collections"
    "rackunit-lib"))
(define build-deps
  '("racket-doc"
    "scribble-lib"))
