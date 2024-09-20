# autoring
A ring buffer library in zig. This is a port of the go package [eapache/queue](https://github.com/eapache/queue/)

Autoring isn't a true ring buffer since it doesn't have a fixed size. It follows a hybrid approach, upon hitting capacity:
- the tail pointer wraps around
- but the queue also resizes to allocate a bigger space

## Benchmark results
On average the queue can enqueue a million elemetns in around 14ms, in other words around 100 million elements in 1.4 seconds. The cache misses are around 22-24% of all cache references.

```
 perf stat -e cache-misses,cache-references  zig run src/main.zig
enqueue 1_000 iters
  93039 iterations      106545.31ns per iterations
  0 bytes per iteration
  worst: 277738ns       median: 104584ns        stddev: 10604.10ns

enqueue 1_000_000 iters
  706 iterations        14146449.68ns per iterations
  4128768 bytes per iteration
  worst: 25658953ns     median: 13978585ns      stddev: 900961.11ns


 Performance counter stats for 'zig run src/main.zig':

           256,901      cache-misses:u                   #   22.35% of all cache refs         
         1,149,444      cache-references:u                                                    

      22.665147797 seconds time elapsed

      14.170373000 seconds user
       8.455382000 seconds sys
```