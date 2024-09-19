# autoring
A ring buffer library in zig. This is a port of the go package [eapache/queue](https://github.com/eapache/queue/)

Autoring isn't a true ring buffer since it doesn't have a fixed size. It follows a hybrid approach, upon hitting capacity:
- the tail pointer wraps around
- but the queue also resizes to allocate a bigger space

## Benchmark results
It seems that with lesser iterations of the benchmark we get slower results.
Does this have to do with cache warm up or something?

- 1 thousand enqueue iterations
```
simpleBenchmark
  197 iterations        15188249.32ns per iterations
  4190208 bytes per iteration
  worst: 17702154ns     median: 15160169ns      stddev: 1126814.16ns
```

- 1 million enqueue iterations
```
zig run src/main.zig
simpleBenchmark
  27655 iterations      107903.74ns per iterations
  0 bytes per iteration
  worst: 261545ns       median: 105873ns        stddev: 10676.51ns
```

- both together

```
enqueue 1_000 iters
  27832 iterations	107547.50ns per iterations
  0 bytes per iteration
  worst: 275526ns	median: 105768ns	stddev: 10462.72ns

enqueue 1_000_000 iters
  201 iterations	14893385.96ns per iterations
  4190208 bytes per iteration
  worst: 19306108ns	median: 14821342ns	stddev: 1185330.34ns

```
