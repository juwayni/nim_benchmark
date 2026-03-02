import ../benchmark
import ../helper

var cd64: array[256, int8]
for i in 0..255: cd64[i] = -1
for i, c in "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/":
  cd64[int(c)] = i.int8

proc decode64(src: string): string =
  let len = src.len
  if len == 0: return ""
  var n = (len div 4) * 3
  if src[len-1] == '=': n.dec
  if src[len-2] == '=': n.dec
  result = newString(n)
  var i = 0
  var j = 0
  while i < len:
    let a = cd64[int(src[i])]
    let b = cd64[int(src[i+1])]
    let c = cd64[int(src[i+2])]
    let d = cd64[int(src[i+3])]
    result[j] = char((a shl 2) or (b shr 4))
    if c != -1:
      result[j+1] = char(((b and 15) shl 4) or (c shr 2))
      if d != -1:
        result[j+2] = char(((c and 3) shl 6) or d)
    i += 4
    j += 3

type
  Base64Decode* = ref object of Benchmark
    str2: string
    str3: string
    resultVal: uint32

proc newBase64Decode(): Benchmark =
  Base64Decode()

method name(self: Base64Decode): string = "Base64::Decode"

method prepare(self: Base64Decode) =
  let n = self.config_val("size").int
  var str = newString(n)
  for i in 0..<n: str[i] = 'a'

  # Use a simple encoder for preparation
  proc simpleEncode(s: string): string =
    const cb64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    result = newString((s.len + 2) div 3 * 4)
    var i, j = 0
    while i < s.len - 2:
      let a = s[i].uint8; let b = s[i+1].uint8; let c = s[i+2].uint8
      result[j] = cb64[int(a shr 2)]
      result[j+1] = cb64[int(((a and 3) shl 4) or (b shr 4))]
      result[j+2] = cb64[int(((b and 15) shl 2) or (c shr 6))]
      result[j+3] = cb64[int(c and 63)]
      i += 3; j += 4
    if i < s.len:
      let a = s[i].uint8
      result[j] = cb64[int(a shr 2)]
      if i == s.len - 1:
        result[j+1] = cb64[int((a and 3) shl 4)]; result[j+2] = '='; result[j+3] = '='
      else:
        let b = s[i+1].uint8
        result[j+1] = cb64[int(((a and 3) shl 4) or (b shr 4))]
        result[j+2] = cb64[int((b and 15) shl 2)]; result[j+3] = '='

  self.str2 = simpleEncode(str)
  self.str3 = decode64(self.str2)
  self.resultVal = 0

method run(self: Base64Decode, iteration_id: int) =
  self.str3 = decode64(self.str2)
  self.resultVal = self.resultVal + uint32(self.str3.len)

method checksum(self: Base64Decode): uint32 =
  checksum("Base64Decode " & $self.resultVal)

registerBenchmark("Base64::Decode", newBase64Decode)
