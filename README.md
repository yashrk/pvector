# A toy implementation of persistent vector for Guile Scheme

[![License](https://img.shields.io/github/license/yashrk/raylib-scm.svg?style=social)](LICENSE)

## Project status

It's just a toy pet-project written for fun, with no commitment to improve or mantain it at all. The code is poorly tested, contains no important optimizations (e.g. shortcut to tail node, transients) and probably isn't production-ready.

## Motivation

The absence of an efficient Clojue-like purelly functional vector in the Guile Scheme standard library and in the Guile ecosystem at all[^1] has always been a pain point for me. However, the idea of a _bit-partitioned vector trie_ is very beautiful and relatively simple. So once I decided to implement it myself.

## Performance

### Access to an element with random index

#### With linked list

[![Random reads, pvector vs. vector, vlist and linked list](https://github.com/yashrk/pvector/blob/main/benchmarks/random-reads-short.png)](https://github.com/yashrk/pvector/blob/main/benchmarks/random-reads-short.png)

This persistent vector, scheme arrays (SRFI-43), vlists, linked lists. Logarithmic scale on both axis.

#### Without linked list

[![Random reads, pvector vs. vlist and vector](https://github.com/yashrk/pvector/blob/main/benchmarks/random-reads.png)](https://github.com/yashrk/pvector/blob/main/benchmarks/random-reads.png)

This persistent vector, scheme arrays (SRFI-43), vlists. Logarithmic scale on data size axis.

## Sources of inspiration

 - Persistent vector implementation in Cloure by Rich Hickey: https://github.com/clojure/clojure/blob/master/test/clojure/test_clojure/vectors.clj
 - Persistent vector implementation in Racket by Alexis King: https://github.com/lexi-lambda/racket-pvector/tree/master
 - Blog post series «Understanding Clojure's Persistent Vectors» by Jean Niklas L'Orange:
   - https://hypirion.com/musings/understanding-persistent-vector-pt-1
   - https://hypirion.com/musings/understanding-persistent-vector-pt-2
   - https://hypirion.com/musings/understanding-persistent-vector-pt-3
   - https://hypirion.com/musings/understanding-clojure-transients
   - https://hypirion.com/musings/persistent-vector-performance
   - https://hypirion.com/musings/persistent-vector-performance-summarised

## License

AGPL v3

## Footnotes

[^1]: Of course, [Lokke vector](https://github.com/lokke-org/lokke/blob/main/lib/lokke-vector.c) from the [Lokke project](https://github.com/lokke-org/lokke/tree/main) and [fectors](https://github.com/ijp/fectors) should be mentioned; but I don't understand how to use Lokke vector outside of Lokke environment (and even is it possible at all or no), and the latter project looks abandoned more than decade ago.
