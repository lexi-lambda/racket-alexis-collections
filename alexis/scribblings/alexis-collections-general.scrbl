#lang scribble/manual

@(require racket/require
          (for-label (subtract-in racket/base alexis/collection)
                     (prefix-in base: racket/base)
                     alexis/collection
                     racket/generic
                     racket/contract)
          scribble/eval
          "private/utils.rkt")

@title{General Interfaces}

The @reftech{generic interfaces} documented on this page have general utility that may extend beyond
collections in addition to their usage in this library.

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

@section{Indexable Collections}

@defmodule[alexis/collection/indexable]

Data structures are @deftech{indexable} if they provide any sort of indexed data.

@defthing[gen:indexable any/c]{

A @reftech{generic interface} that defines exactly one function, @racket[ref], which accepts an
instance of @racket[gen:indexable] and an index.

@margin-note{
Although @reftech{dictionaries} are @tech{indexable}, using @racket[ref] with @reftech{association
lists} will likely not work as you would expect, since they will use @racket[list-ref] instead of
@racket[dict-ref].}

All @tech{generic sequences} are also @tech{indexable}, so implementations of @racket[gen:sequence] do
@italic{not} need to implement @racket[gen:indexable]. Additionally, @reftech{hash tables} and
@reftech{dictionaries} are indexable.

@(examples
  #:eval (evaluator)
  (ref '(a b c) 1)
  (ref (hash 'foo "bar") 'foo))}

@defproc[(indexable? [v any/c]) boolean?]{

A predicate that identifies if @racket[v] is @tech{indexable}.}

@defproc[(ref [collection indexable?] [index any/c]) any]{

Returns the value associated with the provided @racket[index] for the given @racket[collection].}
