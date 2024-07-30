# A toy implementation of persistent vector for Guile Scheme

[![License](https://img.shields.io/github/license/yashrk/raylib-scm.svg?style=social)](LICENSE)

## Project status

It's just a toy pet-project written for fun, with no commitment to improve or mantain it at all. The code is poorly tested, contains no important optimizations (e.g. shortcut to tail node, transients) and probably isn't production-ready.

## Motivation

The absence of an efficient Clojure-like purelly functional vector in the Guile Scheme standard library and in the Guile ecosystem at all[^1] has always been a pain point for me. However, the idea of a _bit-partitioned vector trie_ is very beautiful and relatively simple. So once I decided to implement it myself.

## Documentation

See the [manual](https://github.com/yashrk/pvector/blob/main/doc/pvector.pdf) and the documentation strings in [pvector.scm](https://github.com/yashrk/pvector/blob/main/pvector.scm).

## Performance

### Access to an element with random index

#### With linked list

[![Random reads, pvector vs. vector, vlist, vhash and linked list](https://github.com/yashrk/pvector/blob/main/benchmarks/random-reads-short.png)](https://github.com/yashrk/pvector/blob/main/benchmarks/random-reads-short.png)

Reads from a random index, average time in seconds (lesser is better), with various element count. Performance of persistent vector, scheme arrays (SRFI-43), vlists, vhashes, linked lists. Logarithmic scale on both axis. Vlist is slightly better than pvector, but it doesn't have a setter for the random index. Vector is imperative.

#### Without linked list

[![Random reads, pvector vs. vlist and vector](https://github.com/yashrk/pvector/blob/main/benchmarks/random-reads.png)](https://github.com/yashrk/pvector/blob/main/benchmarks/random-reads.png)

Reads from a random index, average time in seconds (lesser is better), with various element count. Performance of persistent vector, scheme arrays (SRFI-43), vlists, vhashes (linked lists are unacceptably slow with element count involved). Logarithmic scale on data size axis. Again, vlists can't update a random element in the middle of the data structure.

### Change of an element at random index

[![Random writes, pvector vs. vhash and vector](https://github.com/yashrk/pvector/blob/main/benchmarks/random-writes.png)](https://github.com/yashrk/pvector/blob/main/benchmarks/random-writes.png)

Vhash is better than pvector, but see the data for random reads.

### `map` and `fold`

[![map, pvector vs vector, vlist, list and vhash](https://github.com/yashrk/pvector/blob/main/benchmarks/maps.png)](https://github.com/yashrk/pvector/blob/main/benchmarks/maps.png)
[![fold, pvector vs vector, vlist, list and vhash](https://github.com/yashrk/pvector/blob/main/benchmarks/folds.png)](https://github.com/yashrk/pvector/blob/main/benchmarks/folds.png)

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
 - A talk «Postmodern immutable data structures» by Juan Pedro Bolivar Puente at CppCon 2017: https://www.youtube.com/watch?v=sPhpelUfu8Q

## License

AGPL v3

## Footnotes

[^1]: Of course, [Lokke vector](https://github.com/lokke-org/lokke/blob/main/lib/lokke-vector.c) from the [Lokke project](https://github.com/lokke-org/lokke/tree/main) and [fectors](https://github.com/ijp/fectors) should be mentioned; but I don't understand how to use Lokke vector outside of Lokke environment (and even is it possible at all or no), and the latter project looks abandoned more than decade ago.
