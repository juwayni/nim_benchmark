import std/[math, os, cpuinfo]
import ../benchmark
import ../helper

proc matgen(n: int): seq[float64] =
  let tmp = 1.0 / float64(n * n)
  result = newSeq[float64](n * n)
  for i in 0..<n:
    for j in 0..<n:
      result[i * n + j] = tmp * float64(i - j) * float64(i + j)

proc matmulSequential(a, b: seq[float64], n: int): seq[float64] =
  result = newSeq[float64](n * n)
  let aPtr = unsafeAddr a[0]
  let bPtr = unsafeAddr b[0]
  let cPtr = addr result[0]

  # Optimization: Use pointer arithmetic and cache-friendly loop ordering
  for i in 0..<n:
    let rowOff = i * n
    for k in 0..<n:
      let kOff = k * n
      let aik = cast[ptr UncheckedArray[float64]](aPtr)[rowOff + k]
      for j in 0..<n:
        cast[ptr UncheckedArray[float64]](cPtr)[rowOff + j] += aik * cast[ptr UncheckedArray[float64]](bPtr)[kOff + j]

type
  ThreadData = object
    a: ptr float64
    b: ptr float64
    c: ptr float64
    startRow: int
    endRow: int
    n: int

proc worker(data: ThreadData) {.thread.} =
  let n = data.n
  let aArr = cast[ptr UncheckedArray[float64]](data.a)
  let bArr = cast[ptr UncheckedArray[float64]](data.b)
  let cArr = cast[ptr UncheckedArray[float64]](data.c)
  for i in data.startRow..<data.endRow:
    let rowOff = i * n
    for k in 0..<n:
      let kOff = k * n
      let aik = aArr[rowOff + k]
      for j in 0..<n:
        cArr[rowOff + j] += aik * bArr[kOff + j]

proc matmulParallel(a, b: seq[float64], n: int, numThreads: int): seq[float64] =
  result = newSeq[float64](n * n)
  var threads: seq[Thread[ThreadData]]
  newSeq(threads, numThreads)
  let rowsPerThread = n div numThreads
  let aPtr = unsafeAddr a[0]
  let bPtr = unsafeAddr b[0]
  let cPtr = addr result[0]

  for i in 0..<numThreads:
    let startRow = i * rowsPerThread
    let endRow = if i == numThreads - 1: n else: (i + 1) * rowsPerThread
    var data = ThreadData(
      a: cast[ptr float64](aPtr),
      b: cast[ptr float64](bPtr),
      c: cast[ptr float64](cPtr),
      startRow: startRow,
      endRow: endRow,
      n: n
    )
    createThread(threads[i], worker, data)
  for thread in threads: joinThread(thread)

type
  BaseMatmul* = ref object of Benchmark
    n: int
    resultVal: uint32
    a: seq[float64]
    b: seq[float64]

method prepare(self: BaseMatmul) =
  self.n = self.config_val("n").int
  self.a = matgen(self.n)
  self.b = matgen(self.n)
  self.resultVal = 0

method checksum(self: BaseMatmul): uint32 = self.resultVal

type
  Matmul1T* = ref object of BaseMatmul
proc newMatmul1T(): Benchmark = Matmul1T()
method name(self: Matmul1T): string = "Matmul::Single"
method run(self: Matmul1T, iteration_id: int) =
  let c = matmulSequential(self.a, self.b, self.n)
  self.resultVal = self.resultVal + checksumF64(c[(self.n div 2) * self.n + (self.n div 2)])

type
  MatmulParallel* = ref object of BaseMatmul
    numThreads: int
method run(self: MatmulParallel, iteration_id: int) =
  let c = matmulParallel(self.a, self.b, self.n, self.numThreads)
  self.resultVal = self.resultVal + checksumF64(c[(self.n div 2) * self.n + (self.n div 2)])

type Matmul4T* = ref object of MatmulParallel
proc newMatmul4T(): Benchmark = (let res = Matmul4T(); res.numThreads = 4; res)
method name(self: Matmul4T): string = "Matmul::T4"

type Matmul8T* = ref object of MatmulParallel
proc newMatmul8T(): Benchmark = (let res = Matmul8T(); res.numThreads = 8; res)
method name(self: Matmul8T): string = "Matmul::T8"

type Matmul16T* = ref object of MatmulParallel
proc newMatmul16T(): Benchmark = (let res = Matmul16T(); res.numThreads = 16; res)
method name(self: Matmul16T): string = "Matmul::T16"

registerBenchmark("Matmul::Single", newMatmul1T)
registerBenchmark("Matmul::T4", newMatmul4T)
registerBenchmark("Matmul::T8", newMatmul8T)
registerBenchmark("Matmul::T16", newMatmul16T)
