#lang scribble/manual

@(require racket/require
          (for-label (subtract-in racket/base alexis/collection)
                     (prefix-in base: racket/base)
                     alexis/collection
                     racket/contract
                     racket/generic
                     racket/require)
          scribble/eval
          "private/utils.rkt")

@title{Generic Collections}

@defmodule[alexis/collection]

This provides a set of @tech[#:doc '(lib "scribblings/reference/reference.scrbl")]{generic interfaces}
for built-in Racket collections to create a unified interface for working with Racket data structures.
@seclink["structures" #:doc '(lib "scribblings/reference/reference.scrbl")]{User-defined structures}
may also implement the collections API to provide implementations for additional datatypes.

This collection provides certain bindings that conflict with @racketmodname[racket/base]. Most of the
time, this is not a problem. Overriding bindings imported via @tt{#lang} is fine, and almost all
of the new bindings will still work if used like their original counterparts.

One notable exception to this rule is @racket[cons], which is overriden by
@racketmodname[alexis/collection/sequence] and does not work for constructing pairs. Instead, use
@racket[pair]. Also, if you for some reason aren't including @racketmodname[racket/base] via
@tt{#lang}, you can use @racket[subtract-in] to hide the bindings manually.

Also, @racketmodname[alexis/collection] exports the bindings from
@racketmodname[alexis/collection/countable], @racketmodname[alexis/collection/indexable],
and @racketmodname[alexis/collection/sequence].

@local-table-of-contents[]

@include-section["alexis-collections-general.scrbl"]
@include-section["alexis-collections-sequences.scrbl"]
