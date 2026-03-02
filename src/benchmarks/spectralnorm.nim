import std/[math]
import ../benchmark
import ../helper

type
  Spectralnorm* = ref object of Benchmark
    sizeVal: int
    u: seq[float]
    v: seq[float]
    tmp: seq[float]

proc newSpectralnorm(): Benchmark = Spectralnorm()
method name(self: Spectralnorm): string = "CLBG::Spectralnorm"

method prepare(self: Spectralnorm) =
  self.sizeVal = self.config_val("size").int
  self.u = newSeq[float](self.sizeVal)
  self.v = newSeq[float](self.sizeVal)
  self.tmp = newSeq[float](self.sizeVal)
  for i in 0..<self.sizeVal: self.u[i] = 1.0

template evalA(i, j: int): float =
  1.0 / float((i + j) * (i + j + 1) div 2 + i + 1)

proc evalATimesU(u: seq[float], res: var seq[float]) =
  let n = u.len
  let uPtr = cast[ptr UncheckedArray[float]](unsafeAddr u[0])
  let resPtr = cast[ptr UncheckedArray[float]](addr res[0])
  for i in 0..<n:
    var sum = 0.0
    for j in 0..<n: sum += evalA(i, j) * uPtr[j]
    resPtr[i] = sum

proc evalAtTimesU(u: seq[float], res: var seq[float]) =
  let n = u.len
  let uPtr = cast[ptr UncheckedArray[float]](unsafeAddr u[0])
  let resPtr = cast[ptr UncheckedArray[float]](addr res[0])
  for i in 0..<n:
    var sum = 0.0
    for j in 0..<n: sum += evalA(j, i) * uPtr[j]
    resPtr[i] = sum

proc evalAtATimesU(u: seq[float], v, tmp: var seq[float]) =
  evalATimesU(u, tmp)
  evalAtTimesU(tmp, v)

method run(self: Spectralnorm, iteration_id: int) =
  evalAtATimesU(self.u, self.v, self.tmp)
  evalAtATimesU(self.v, self.u, self.tmp)

method checksum(self: Spectralnorm): uint32 =
  var vBv, vv = 0.0
  for i in 0..<self.sizeVal:
    vBv += self.u[i] * self.v[i]
    vv += self.v[i] * self.v[i]
  checksumF64(sqrt(vBv / vv))

registerBenchmark("CLBG::Spectralnorm", newSpectralnorm)
