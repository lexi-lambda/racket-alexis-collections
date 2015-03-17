#lang scribble/manual

@(require (for-label alexis/collection+base
                     (prefix-in base: racket/base)
                     (only-in racket/stream in-stream)
                     racket/contract
                     racket/generic)
          scribble/eval)

@(define (reftech . content)
   (apply tech #:doc '(lib "scribblings/reference/reference.scrbl") content))

@(define evaluator
   (make-eval-factory
    '(racket/generic
      alexis/collection)
    #:lang 'racket))

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
@tt{#lang}, you can use @racketmodname[alexis/collection+base] instead.

Also, @racketmodname[alexis/collection] exports the bindings from both
@racketmodname[alexis/collection/countable] and @racketmodname[alexis/collection/sequence].

@section{Countable Collections}

@defmodule[alexis/collection/countable]

Lots of data structures may be considered @deftech{countable}—that is, they have a discrete number of
elements. The @racket[gen:countable] interface only provides a single function, @racket[length].

@defthing[gen:countable any/c]{

A @reftech{generic interface} that defines exactly one function, @racket[length], which accepts a
single argument and returns the number of elements contained within the collection.

The following built-in datatypes have implementations for @racket[gen:countable]:

@itemlist[
  @item{@reftech{lists}}
  @item{@reftech{vectors}}
  @item{@reftech{strings}}
  @item{@reftech{byte strings}}
  @item{@reftech{hash tables}}
  @item{@reftech{sets}}
  @item{@reftech{dictionaries}}
  @item{@reftech{streams}}
  @item{@reftech{sequences}}]

For @reftech{streams} and @reftech{sequences}, if the argument is infinite, then @racket[length] does
not terminate.

@(examples
  #:eval (evaluator)
  (length (range 20))
  (length #(λ))
  (length "Hello!")
  (length (set 1 2 3 4 5))
  (struct wrapped-collection (value)
    #:methods gen:countable
    [(define/generic gen-length length)
     (define (length w)
       (gen-length (wrapped-collection-value w)))])
  (length (wrapped-collection (hash 'a "b" 'c "d"))))}

@defproc[(countable? [v any/c]) boolean?]{

A predicate that identifies if @racket[v] is @tech{countable}.}

@defproc[(length [collection countable?]) exact-nonnegative-integer?]{

Returns the number of discrete elements contained by @racket[collection]. If @racket[collection] is
infinite, then this function does not terminate.}

@section{Generic Sequences}

@defmodule[alexis/collection/sequence]

Racket has it's own idea of what a @reftech{sequence} is, but it is different from a @deftech{generic
sequence}. Racket's "sequence" is actually just a collection of hardcoded datatypes, but @tech{generic
sequences} are implementations of a well-defined API, @racket[gen:sequence].

@defthing[gen:sequence any/c]{

A @reftech{generic interface} that represents @italic{ordered} collections of values (finite or
infinite). The interface includes a small set of @italic{required methods} and a larger set of
@italic{derived methods}. All the derived methods have existing implementations implemented purely in
terms of the required ones, but provided manual implementations of the derived methods may provide
better performance.

The required methods are the following four functions:

@itemlist[
  @item{@racket[cons] — The primitive sequence constructor. Prepends a new value onto the sequence.}
  @item{@racket[first] — Fetches the first element in a sequence.}
  @item{@racket[rest] — Fetches the rest of a sequence.}
  @item{@racket[empty?] — Tests if a sequence is empty (see also @racket[prop:sequence-empty]).}]

The derived methods are as follows:

@itemlist[
  @item{@racket[ref] — Gets a value from an arbitrary position in a sequence.}
  @item{@racket[append] — Appends two sequences together.}
  @item{@racket[reverse] — Reverses a sequence.}
  @item{@racket[filter] — Filters elements from a sequence.}
  @item{@racket[map] — Applies a function to all values in a sequence and returns the result.}
  @item{@racket[sequence->stream] — Converts any type of sequence to a @reftech{stream} (which is
        itself a sequence).}
  @item{@racket[sequence->list] — Converts any type of sequence to a @reftech{list}.}]

The following built-in datatypes have implementations for @racket[gen:sequence]:

@itemlist[
  @item{@reftech{lists}}
  @item{@reftech{vectors}}
  @item{@reftech{strings}}
  @item{@reftech{byte strings}}
  @item{@reftech{streams}}
  @item{@reftech{sequences}}]

@(examples
  #:eval (evaluator)
  (append "Hello," " " "world!")
  (ref #"abc" 1)
  (reverse #(1 2 3 4))
  (let ()
    (struct my-sequence () #:transparent
      #:methods gen:sequence
      [(define (cons a d) (my-pair a d))
       (define (first p) (my-pair-car p))
       (define (rest p) (my-pair-cdr p))
       (define (empty? p) (eq? p my-null))])
    (struct my-pair my-sequence (car cdr) #:transparent)
    (define my-null (my-sequence))
    (define my-list (cons 'a (cons 'b (cons 'c my-null))))
    (reverse my-list)))}

@defproc[(sequence? [v any/c]) boolean?]{

A predicate that identifies if @racket[v] is a @tech{generic sequence}.}

@subsection{Primitive Functions}

@defproc[(cons [value any/c] [sequence sequence?]) sequence?]{

@margin-note{
Since this version of @racket[cons] is sequence-specific, it can't be used for constructing arbitrary
pairs. Instead, use @racket[pair].}

Prepends @racket[value] onto the @racket[sequence]. Sequences are not @italic{required} to be
heterogenous, and @reftech{strings}, for example, only accept @reftech{characters} as sequence
elements.}

@defproc[(first [sequence sequence?]) any]{

Gets the first element in @racket[sequence].}

@defproc[(rest [sequence sequence?]) any]{

Gets the remainder of @racket[sequence] with its first element removed.}

@defproc[(empty? [sequence sequence?]) boolean?]{

Returns @racket[#t] if @racket[sequence] contains no elements, otherwise @racket[#f].}

@subsection{Derived Functions}

@defproc[(ref [sequence sequence?] [index exact-nonnegative-integer?]) any]{

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

@defproc[(sequence->stream [sequence sequence?]) stream?]{

Converts a @tech{generic sequence} to a @reftech{stream}. Note that streams are, in fact,
@italic{also} generic sequences, but this function will convert sequences to the same underlying
representation.}

@defproc[(sequence->list [sequence sequence?]) list?]{

Converts a @tech{generic sequence} to a @reftech{list}. This may be more eager than using
@racket[sequence->stream].}

@subsection{Sequence API Functions}

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

Access various elements of @racket[sequence], as would be expected. These are implemented using
@racket[ref], so a random-access implementation of @racket[ref] will make these random-access as
well.}

@subsection{Other Functions and Forms}

@defthing[prop:sequence-empty structure-type-property?]{

A @reftech{structure type property} that is used by certain functions in @racket[gen:sequence], if it
exists. Since sequences are singly-linked, finding the terminating value in a sequence is an
@italic{O(n)} operation, but it must be performed before executing certain functions, such as
@racket[reverse]. To avoid traversing the sequence twice, setting a value for
@racket[prop:sequence-empty] will use the provided value instead of looking it up each time.

Obviously, specifying an incorrect value for this property cannot be checked by @racket[gen:sequence],
so behavior is undefined if the value of @racket[prop:sequence-empty] is inconsistent with the
implementation of @racket[empty?].}

@defproc[(in [sequence sequence?]) base:sequence?]{

Identical to @racket[(in-stream (sequence->stream sequence))]. Provided as a convenience for iterating
through @tech{generic sequences} in @racket[for] forms.}

@defproc[(pair [a any/c] [d any/c]) pair?]{

Identical to @racket[base:cons], re-exported by @racketmodname[alexis/collection/sequence] since
@racket[cons] is no longer usable for creating @reftech{pairs}.}

@section{Convenience Module}

@defmodule[alexis/collection+base]

Exports all the bindings from @racketmodname[alexis/collection] and @racketmodname[racket/base], but
uses the bindings from @racketmodname[alexis/collection] when the two conflict.
