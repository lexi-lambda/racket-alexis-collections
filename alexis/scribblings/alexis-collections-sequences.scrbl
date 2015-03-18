#lang scribble/manual

@(require racket/require
          (for-label (subtract-in racket/base alexis/collection)
                     (prefix-in base: racket/base)
                     alexis/collection
                     racket/contract
                     racket/generic)
          scribble/eval
          "private/utils.rkt")

@title[#:style '(toc) #:tag "sequences"]{Generic Sequences}

@defmodule[alexis/collection/sequence]

@deftech{Generic sequences} are the bulk of this library, and they are one of the more complicated
aspects of it. Sequences are distinct from Racket @reftech{sequences}, which are a different, much
more ad-hoc system.

Sequences are @italic{ordered collections}, and they may be finite or infinite. They are divided into
two primary categories, @tech{constructed sequences} and @tech{flat sequences}.

@; TODO: include pict-y thing demonstrating the sequence interface hierarchy

@local-table-of-contents[]

@section[#:tag "high-level-sequences"]{The High-Level Sequence API}

The @racket[gen:sequence] @reftech{generic interface} provides an interface for interacting with all
@tech{generic sequences}.

@defthing[gen:sequence any/c]{

A @reftech{generic interface} that represents @italic{ordered} collections of values (finite or
infinite). It is a superinterface for @racket[gen:constructed-sequence] and
@racket[gen:flat-sequence]. User-defined collections should almost certainly @italic{not} implement
this interface, but should implement a sub-interface instead.

The general sequence interface provides the following functions:

@itemlist[
  @item{@racket[first] — Fetches the first element in a sequence.}
  @item{@racket[empty?] — Tests if a sequence is empty.}
  @item{@racket[sequence-ref] — Gets a value from an arbitrary position in a sequence.}
  @item{@racket[append] — Appends two sequences together.}
  @item{@racket[reverse] — Reverses a sequence.}
  @item{@racket[filter] — Filters elements from a sequence.}
  @item{@racket[map] — Applies a function to all values in a sequence and returns the result.}]

The following built-in datatypes have implementations for @racket[gen:sequence]:

@itemlist[
  @item{@reftech{lists} (via @racket[gen:constructed-sequence])}
  @item{@reftech{vectors} (via @racket[gen:flat-sequence])}
  @item{@reftech{strings} (via @racket[gen:flat-sequence])}
  @item{@reftech{byte strings} (via @racket[gen:flat-sequence])}
  @item{@reftech{streams} (via @racket[gen:constructed-sequence])}
  @item{@reftech{sequences} (via @racket[gen:constructed-sequence])}]

@(examples
  #:eval (evaluator)
  (append "Hello," " " "world!")
  (ref #"abc" 1)
  (reverse #(1 2 3 4)))}

@defproc[(sequence? [v any/c]) boolean?]{

A predicate that identifies if @racket[v] is a @tech{generic sequence}.}

@subsection[#:tag "sequence-methods"]{Generic Methods}

@defproc[(first [sequence sequence?]) any]{

Gets the first element in @racket[sequence].}

@defproc[(empty? [sequence sequence?]) boolean?]{

Returns @racket[#t] if @racket[sequence] contains no elements, otherwise @racket[#f].}

@defproc[(sequence-ref [sequence sequence?] [index exact-nonnegative-integer?]) any]{

@margin-note{
All @tech{generic sequences} are also @tech{indexable}, so @racket[ref] can be used in place of
@racket[sequence-ref] when performing indexing on sequences.}

Gets the element at @racket[index] in @racket[sequence]. @tech{Generic sequences} are strictly
@italic{ordered}, so @racket[index] must be numeric.}

@defproc[(append [sequence sequence?] ...+) sequence?]{

Appends the provided sequences together, in order.}

@defproc[(reverse [sequence sequence?]) sequence?]{

Returns a new sequence that is the reverse of @racket[sequence]. If @racket[sequence] is infinite,
this function will not terminate.}

@defproc[(filter [pred (any/c . -> . any/c)] [sequence sequence?]) sequence?]{

Returns a new sequence that contains all the elements from @racket[sequence] for which @racket[pred]
produces a non-@racket[#f] value when applied, in order.}

@defproc[(map [proc procedure?] [sequence sequence?] ...+) sequence?]{

Applies @racket[proc] to the values from each @racket[sequence]. The @racket[proc] must accept the
name number of arguments as sequences are supplied, and all sequences must be the same length. The
result is a new sequence with the results of @racket[proc], in order.}

@subsection{Additional General Sequence Functions}

These functions operate on sequences, but are not part of the generic interface and cannot be
overridden. They are implemented in terms of the methods of @racket[gen:sequence].

@deftogether[(@defproc[(second [sequence sequence?]) any]
              @defproc[(third [sequence sequence?]) any]
              @defproc[(fourth [sequence sequence?]) any]
              @defproc[(fifth [sequence sequence?]) any]
              @defproc[(sixth [sequence sequence?]) any]
              @defproc[(seventh [sequence sequence?]) any]
              @defproc[(eight [sequence sequence?]) any]
              @defproc[(ninth [sequence sequence?]) any]
              @defproc[(tenth [sequence sequence?]) any])]{

These access various elements of @racket[sequence], as would be expected. These are implemented using
@racket[sequence-ref], so a random-access implementation of @racket[sequence-ref] will make these
random-access as well.}

@include-section["alexis-collections-sequences-constructed.scrbl"]
@include-section["alexis-collections-sequences-flat.scrbl"]
