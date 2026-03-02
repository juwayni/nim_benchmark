import std/[math]
import ../benchmark
import ../helper

type
  Sieve* = ref object of Benchmark
    n: int
    checksumVal: uint32

proc newSieve(): Benchmark = Sieve()
method name(self: Sieve): string = "Etc::Sieve"

method prepare(self: Sieve) =
  self.n = self.config_val("limit").int
  self.checksumVal = 0

method run(self: Sieve, iteration_id: int) =
  let lim = self.n
  # Use bitset if possible, but seq[bool] is also good. uint8 is fine.
  var primes = newSeq[uint8](lim + 1)
  for i in 2..lim: primes[i] = 1
  let sqrtLimit = int(sqrt(float(lim)))
  for p in 2..sqrtLimit:
    if primes[p] == 1:
      var multiple = p * p
      while multiple <= lim:
        primes[multiple] = 0
        multiple += p
  var lastPrime = 0
  var count = 0
  for i in 2..lim:
    if primes[i] == 1:
      lastPrime = i
      count += 1
  self.checksumVal += uint32(lastPrime + count)

method checksum(self: Sieve): uint32 = self.checksumVal
registerBenchmark("Etc::Sieve", newSieve)
