
# alexis-collections

This package provides **generic collections** for Racket. Despite Racket's relatively complete library of collections, working with them can be a pain since each data structure comes with its own set of functions for interacting with it. There's `length` for lists, `string-length` for strings, `bytes-length` for bytestrings, etc.

Now, however, Racket has *generics*, and this aims to provide a nicer front-end to the existing collections library in a way that makes use of that functionality.

[**See the docs for more information.**](pkg-build.racket-lang.org/doc/alexis-collections/)

## Examples

Some simple examples of generic `length` with `gen:countable`:

```racket
> (length (range 20))
20
> (length #(λ))
1
> (length "Hello!")
6
> (length (set 1 2 3 4 5))
5
```

Using generic functions with different types of sequences:

```racket
> (append "Hello," " " "world!")
"Hello, world!"
> (ref #"abc" 1)
98
> (reverse #(1 2 3 4))
'#(4 3 2 1)
```

Defining a custom sequence type:

```racket
(struct my-sequence () #:transparent
  #:methods gen:sequence
  [(define (cons a d) (my-pair a d))
   (define (first p) (my-pair-car p))
   (define (rest p) (my-pair-cdr p))
   (define (empty? p) (eq? p my-null))])

(struct my-pair my-sequence (car cdr) #:transparent)
(define my-null (my-sequence))

> (define my-list (cons 'a (cons 'b (cons 'c my-null))))
> (reverse my-list))
(my-pair 'c (my-pair 'b (my-pair 'a (my-sequence))))
```
