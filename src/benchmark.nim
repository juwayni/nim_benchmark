import std/[json, times, monotimes, math, tables, strutils, os]
import config, helper

type
  Benchmark* = ref object of RootObj
    timeDelta*: float

method name*(self: Benchmark): string {.base.} =
  raise newException(ValueError, "Not implemented")

method run*(self: Benchmark, iteration_id: int) {.base.} =
  raise newException(ValueError, "Not implemented")

method checksum*(self: Benchmark): uint32 {.base.} =
  raise newException(ValueError, "Not implemented")

method prepare*(self: Benchmark) {.base.} =
  discard

method config_val*(self: Benchmark, field_name: string): int64 {.base.} =
  config_i64(self.name, field_name)

method iterations*(self: Benchmark): int64 {.base.} =
  self.config_val("iterations")

method expected_checksum*(self: Benchmark): int64 {.base.} =
  self.config_val("checksum")

method warmup_iterations*(self: Benchmark): int64 {.base.} =
  if CONFIG.hasKey(self.name) and CONFIG{self.name}.hasKey("warmup_iterations"):
    return CONFIG{self.name}{"warmup_iterations"}.getBiggestInt()
  else:
    let iters = self.iterations
    return max(int64(float(iters) * 0.2), 1'i64)

method warmup*(self: Benchmark) {.base.} =
  let prepare_iters = self.warmup_iterations
  for i in 0..<prepare_iters:
    self.run(i)

proc run_all*(self: Benchmark) =
  let iters = self.iterations
  for i in 0..<iters:
    self.run(i)

proc set_time_delta*(self: Benchmark, delta: float) =
  self.timeDelta = delta

proc toLower*(str: string): string =
  result = newString(str.len)
  for i, c in str:
    result[i] = toLowerAscii(c)

type
  BenchmarkFactory* = proc(): Benchmark

var registeredBenchmarks*: seq[tuple[name: string, factory: BenchmarkFactory]]

proc registerBenchmark*(name: string, factory: BenchmarkFactory) =
  registeredBenchmarks.add((name, factory))

proc all*(singleBench = "") =
  var results: Table[string, float]
  var summaryTime = 0.0
  var ok = 0
  var fails = 0

  for benchInfo in registeredBenchmarks:
    let name = benchInfo.name
    let createBenchmark = benchInfo.factory

    if singleBench.len > 0 and name.toLower.find(singleBench.toLower) == -1:
      continue

    stdout.write(name, ": ")
    stdout.flushFile()

    let bench = createBenchmark()
    reset()
    bench.prepare()

    bench.warmup
    GC_fullCollect()
    reset()

    let start = getMonoTime()
    bench.run_all
    let duration = (getMonoTime() - start).inMicroseconds.float / 1000000.0

    bench.set_time_delta(duration)
    results[name] = duration

    let actual = bench.checksum
    let expected = bench.expected_checksum.uint32
    if actual == expected:
      stdout.write("OK ")
      inc ok
    else:
      stdout.write("ERR[actual=", $actual, ", expected=",
          $expected, "] ")
      inc fails

    echo "in ", formatFloat(duration, ffDecimal, 3), "s"
    summaryTime += duration

    GC_fullCollect()

  if ok + fails > 0:
    echo "Summary: ", formatFloat(summaryTime, ffDecimal, 4), "s, ", ok+fails,
        ", ", ok, ", ", fails

  if fails > 0:
    quit(1)
