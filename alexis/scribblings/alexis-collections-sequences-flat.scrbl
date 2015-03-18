#lang scribble/manual

@(require racket/require
          (for-label (subtract-in racket/base alexis/collection)
                     (prefix-in base: racket/base)
                     alexis/collection
                     racket/contract
                     racket/generic)
          scribble/eval
          "private/utils.rkt")

@title[#:tag "flat-sequences"]{Flat Sequences}

@defmodule*[(alexis/collection/sequence/flat
             alexis/collection/sequence/flat/immutable
             alexis/collection/sequence/flat/mutable)]

A @deftech{flat sequence} is one of the two types of @tech{generic sequences} (the other being
@tech{constructed sequences}). A flat sequence is a random-access data structure, and unlike
@tech{constructed sequences}, which are always immutable, flat sequences may be mutable.

Flat sequences are represented via the @racket[gen:flat-sequence] @reftech{generic interface}, which
is further subdivided into @racket[gen:flat-immutable-sequence] and
@racket[gen:flat-mutable-sequence]. When implementing user-defined types, it is recommended that you
implement one of the subtypes instead of implementing @racket[gen:flat-sequence] directly.

@deftogether[(@defthing[gen:flat-sequence any/c]
              @defthing[gen:flat-immutable-sequence any/c]
              @defthing[gen:flat-mutable-sequence any/c])]{

Together, these three @reftech{generic interfaces} provide implementations for mutable and immutable
ordered, random-access data structures. The method names follow a predictable pattern:
@racket[flat-ref] corresponds to @racket[flat-immutable-ref] and @racket[flat-mutable-ref]. Functions
that have side effects, such as @racket[flat-set!], only have counterparts in
@racket[gen:flat-mutable-sequence].

The primitive functions for @racket[gen:flat-sequence] are as follows:

@itemlist[
  @item{@racket[flat-length] — Gets the length of a sequence.}
  @item{@racket[flat-ref] — Gets an element within the sequence.}
  @item{@racket[flat-set!] — Sets an element within the sequence (mutable sequences only).}]

Some functions in @racket[gen:flat-sequence] can be derived, but only if the implementation provides a
@tech{flat sequence allocator}. These functions include the following:

@itemlist[
  @item{@racket[flat-copy] — Copies a sequence.}
  @item{@racket[flat-append] — Appends sequences together.}
  @item{@racket[flat-reverse] — Reverses a sequence.}
  @item{@racket[flat-filter] — Filters elements from a sequence.}
  @item{@racket[flat-map] — Applies a procedure to each element in a sequence and collects the results
        into a new sequence.}]

Finally, the remaining functions can always be derived and do not require an allocator:

@itemlist[
  @item{@racket[flat-empty?] — Checks if a sequence is empty.}
  @item{@racket[flat-copy!] — Copies a sequence into another sequence, modifying it (mutable sequences
        only).}
  @item{@racket[flat-reverse!] — Reverses a sequence in-place (mutable sequences only).}
  @item{@racket[flat-map!] — Applies a procedure to each element in a sequence and stores the results
        in the original sequence, modifying it (mutable sequences only).}
  @item{@racket[flat->vector] — Converts a sequence to a vector.}]

All instances of @racket[gen:flat-sequence] are also implementations of @racket[gen:sequence]. When
interacting with sequences, it is preferable to use the more generic functions that are not prefixed
with @code{flat-}.}
