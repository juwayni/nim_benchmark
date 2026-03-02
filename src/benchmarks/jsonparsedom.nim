import std/[math, json]
import ../benchmark
import ../helper
import jsonbench_common

type
  JsonParseDom* = ref object of Benchmark
    text: string
    resultVal: uint32

proc newJsonParseDom(): Benchmark =
  JsonParseDom()

method name(self: JsonParseDom): string = "Json::ParseDom"

method prepare(self: JsonParseDom) =
  let n = self.config_val("coords")
  self.text = getJsonText(n)
  self.resultVal = 0

method run(self: JsonParseDom, iteration_id: int) =
  # Revert to DOM parsing as requested (don't change logic),
  # but use std/json with minimal overhead where possible.
  let parsed = parseJson(self.text)

  var xSum, ySum, zSum: float
  let coordinates = parsed["coordinates"]
  let len = coordinates.len

  for coordNode in coordinates:
    xSum += coordNode["x"].getFloat()
    ySum += coordNode["y"].getFloat()
    zSum += coordNode["z"].getFloat()

  if len > 0:
    let flen = float(len)
    let x = xSum / flen
    let y = ySum / flen
    let z = zSum / flen
    self.resultVal = self.resultVal + checksumF64(x) + checksumF64(y) +
        checksumF64(z)

method checksum(self: JsonParseDom): uint32 =
  self.resultVal

registerBenchmark("Json::ParseDom", newJsonParseDom)
