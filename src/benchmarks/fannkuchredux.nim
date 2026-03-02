import ../benchmark

type
  Fannkuchredux* = ref object of Benchmark
    n: int
    resultVal: uint32

proc newFannkuchredux(): Benchmark = Fannkuchredux()
method name(self: Fannkuchredux): string = "CLBG::Fannkuchredux"
method prepare(self: Fannkuchredux) =
  self.n = self.config_val("n").int
  self.resultVal = 0

proc fannkuchredux(n: int): (int, int) =
  var perm1, perm, count: array[16, int]
  for i in 0..<n: perm1[i] = i
  var maxFlipsCount, permCount, checksum = 0
  var r = n
  while true:
    while r > 1:
      count[r-1] = r
      r.dec
    for i in 0..<n: perm[i] = perm1[i]
    var flipsCount = 0
    var k = perm[0]
    while k != 0:
      let k2 = (k + 1) div 2
      for i in 0..<k2:
        let tmp = perm[i]
        perm[i] = perm[k-i]
        perm[k-i] = tmp
      flipsCount.inc
      k = perm[0]
    maxFlipsCount = max(maxFlipsCount, flipsCount)
    if (permCount and 1) == 0: checksum += flipsCount
    else: checksum -= flipsCount
    while true:
      if r == n: return (checksum, maxFlipsCount)
      let p0 = perm1[0]
      for i in 0..<r: perm1[i] = perm1[i+1]
      perm1[r] = p0
      count[r].dec
      if count[r] > 0: break
      r.inc
    permCount.inc

method run(self: Fannkuchredux, iteration_id: int) =
  let (a, b) = fannkuchredux(self.n)
  self.resultVal += (a * 100 + b).uint32

method checksum(self: Fannkuchredux): uint32 = self.resultVal
registerBenchmark("CLBG::Fannkuchredux", newFannkuchredux)
