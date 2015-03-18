#lang scribble/manual

@(require racket/require
          (for-label (subtract-in racket/base alexis/collection)
                     (prefix-in base: racket/base)
                     alexis/collection
                     racket/contract
                     racket/generic)
          scribble/eval
          "private/utils.rkt")

@title[#:tag "constructed-sequences"]{Constructed Sequences}

@defmodule[alexis/collection/sequence/constructed]

A @deftech{constructed sequence} is one of the two types of @tech{generic sequences} (the other being
@tech{flat sequences}). A constructed sequence is structurally recursive—the classic example of a
constructed sequence would be the simple @reftech{list}. Other kinds of constructed sequences include
lazy @reftech{streams}.

All constructed sequences are immutable.

@defthing[gen:constructed-sequence any/c]{

The interface for @tech{constructed sequences} includes a set of @italic{primitive functions} and a
set of @italic{derived functions}. User-defined collections must implement the primitive functions at
the bare minimum, and the other functions will work. Specialized implementations of the derived
functions have the potential to be more performant.

The primitive functions are as follows:

@itemlist[
  @item{@racket[cons] — The primitive sequence constructor. Prepends a value onto the sequence.}
  @item{@racket[cons-first] — Retrieves the head of the sequence.}
  @item{@racket[cons-rest] — Retrieves the remainder of the sequence.}
  @item{@racket[cons-empty?] — Tests if a sequence is empty (see also @racket[prop:cons-empty]).}]

The remaining functions are derived:

@itemlist[
  @item{@racket[cons-ref] — Retrieves a value from an arbitrary position in the sequence.}
  @item{@racket[cons-append] — Appends two sequences together.}
  @item{@racket[cons-reverse] — Reverses a sequence.}
  @item{@racket[cons-filter] — Filters elements from a sequence.}
  @item{@racket[cons-map] — Applies a function to all elements in a sequence and returns the resulting
        values in a new sequence.}
  @item{@racket[cons->stream] — Converts a sequence to a @reftech{stream}.}
  @item{@racket[cons->list] — Converts a sequence to a @reftech{list}.}]

The following built-in datatypes have implementations for @racket[gen:constructed-sequence]:

@itemlist[
  @item{@reftech{lists}}
  @item{@reftech{streams}}
  @item{@reftech{sequences}}]

All instances of @racket[gen:constructed-sequence] are also implementations of @racket[gen:sequence].
When interacting with sequences, it is preferable to use the more generic functions that are not
prefixed with @code{cons-}.}

@defproc[(constructed-sequence? [sequence any/c]) boolean?]{

Returns @racket[#t] if @racket[sequence] is a @tech{constructed sequence}, otherwise @racket[#f].}

@section[#:tag "constructed-methods"]{Generic Methods}

@defproc[(cons [value any/c] [sequence constructed-sequence?]) constructed-sequence?]{

@margin-note{
Since this version of @racket[cons] is sequence-specific, it can't be used for constructing arbitrary
pairs. Instead, use @racket[pair].}

Prepends @racket[value] onto the @racket[sequence]. Sequences are @italic{not required} to be
heterogenous, and @reftech{strings}, for example, only accept @reftech{characters} as sequence
elements.}

@deftogether[(@defproc[(cons-rest [sequence constructed-sequence?]) constructed-sequence?]
              @defproc[(rest [sequence constructed-sequence?]) constructed-sequence?])]{

Retrieves the remainder of the sequence without its first element. This is also exported as
@racket[rest] for convenience.}

@defproc[(cons->stream [sequence constructed-sequence?]) stream?]{

Converts @racket[sequence] to a @reftech{stream}.}

@defproc[(cons->list [sequence constructed-sequence?]) list?]{

Converts @racket[sequence] to a @reftech{list}.}

@deftogether[(@defproc[(cons-first [sequence constructed-sequence?]) any]
              @defproc[(cons-empty? [sequence constructed-sequence?]) boolean?]
              @defproc[(cons-ref [sequence constructed-sequence?]) any]
              @defproc[(cons-append [sequence constructed-sequence?] ...+) constructed-sequence?]
              @defproc[(cons-reverse [sequence constructed-sequence?]) constructed-sequence?]
              @defproc[(cons-filter [pred (any/c . -> . any/c)]
                                    [sequence constructed-sequence?])
                       constructed-sequence?]
              @defproc[(cons-map [proc procedure?] [sequence constructed-sequence?] ...+)
                       constructed-sequence?])]{
Currently missing documentation, but basically equivalent to their counterparts in
@racket[gen:sequence].}

@section[#:tag "constructed-extras"]{Other Functions and Forms}

@defthing[prop:cons-empty struct-type-property?]{

A @reftech{structure type property} that is used by certain functions in
@racket[gen:constructed-sequence], if it exists. Since constructed sequences are singly-linked,
finding the terminating value in a sequence is an @italic{O(n)} operation, but it must be performed
before executing certain functions, such as @racket[cons-reverse]. To avoid traversing the sequence
twice, setting a value for @racket[prop:cons-empty] will use the provided value instead of looking it
up each time.}

@defproc[(pair [a any/c] [d any/c]) pair?]{

Identical to @racket[base:cons], re-exported by @racketmodname[alexis/collection/sequence/constructed]
since @racket[cons] is no longer usable for creating @reftech{pairs}.}
