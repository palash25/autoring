# autoring
This is inspired from the go package [eapache/queue](https://github.com/eapache/queue/)

Autoring isn't a true ring buffer since it doesn't have a fixed size. It follows a hybrid approach, upon hitting capacity:
- the tail pointer wraps around
- but the queue also resizes to allocate a larger chunk of memory (2x the previous size)

## Benchmark results
On average the queue can enqueue a million elements in around 14ms, in other words around 100 million elements in 1.4 seconds. The cache misses are around 22-24% of all cache references.

```shell
 perf stat -e cache-misses,cache-references  zig run src/main.zig
enqueue 1_000 iters
  43138 iterations      114494.35ns per iterations
  0 bytes per iteration
  worst: 428116ns       median: 106760ns        stddev: 25254.53ns

enqueue 1_000_000 iters
  386 iterations        12946863.82ns per iterations
  4128768 bytes per iteration
  worst: 21153916ns     median: 12722542ns      stddev: 1231726.68ns

Performance counter stats for 'zig run src/main.zig':

  288,342      cache-misses:u                   #   24.52% of all cache refs         
1,176,115      cache-references:u                                                    

12.141968993 seconds time elapsed

7.840296000 seconds user
4.248940000 seconds sys


```

### References
