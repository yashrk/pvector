# A toy implementation of persistent vector for Guile Scheme

## Project status

It's just a toy pet-project written for fun, with no commitment to improve or mantain it at all. The code is poorly tested, contains no important optimizations (e.g. shortcut to tail node, transients) and probably isn't production-ready.

## Motivation

The absence of an efficient Clojue-like purelly functional vector in the Guile Scheme standard library has always been a pain point for me. However, the idea of a _bit-partitioned vector trie_ is very beautiful and relatively simple. So once I decided to implementat it myself.

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