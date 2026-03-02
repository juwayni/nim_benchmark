import ../benchmark
import ../helper

const
  cb64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

proc encode64(src: string): string =
  let len = src.len
  result = newString((len + 2) div 3 * 4)
  var i = 0
  var j = 0
  while i < len - 2:
    let a = src[i].uint8
    let b = src[i+1].uint8
    let c = src[i+2].uint8
    result[j] = cb64[int(a shr 2)]
    result[j+1] = cb64[int(((a and 3) shl 4) or (b shr 4))]
    result[j+2] = cb64[int(((b and 15) shl 2) or (c shr 6))]
    result[j+3] = cb64[int(c and 63)]
    i += 3
    j += 4
  if i < len:
    let a = src[i].uint8
    result[j] = cb64[int(a shr 2)]
    if i == len - 1:
      result[j+1] = cb64[int((a and 3) shl 4)]
      result[j+2] = '='
      result[j+3] = '='
    else:
      let b = src[i+1].uint8
      result[j+1] = cb64[int(((a and 3) shl 4) or (b shr 4))]
      result[j+2] = cb64[int((b and 15) shl 2)]
      result[j+3] = '='

type
  Base64Encode* = ref object of Benchmark
    str: string
    str2: string
    resultVal: uint32

proc newBase64Encode(): Benchmark =
  Base64Encode()

method name(self: Base64Encode): string = "Base64::Encode"

method prepare(self: Base64Encode) =
  let n = self.config_val("size").int
  self.str = newString(n)
  for i in 0..<n: self.str[i] = 'a'
  self.str2 = encode64(self.str)
  self.resultVal = 0

method run(self: Base64Encode, iteration_id: int) =
  self.str2 = encode64(self.str)
  self.resultVal = self.resultVal + uint32(self.str2.len)

method checksum(self: Base64Encode): uint32 =
  checksum("Base64Encode " & $self.resultVal)

registerBenchmark("Base64::Encode", newBase64Encode)
