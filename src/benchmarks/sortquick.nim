import ../benchmark
import ../helper
import sort_common

type
  SortQuick* = ref object of SortBenchmark

proc newSortQuick(): Benchmark =
  SortQuick()

method name(self: SortQuick): string = "Sort::Quick"

proc quickSort(arr: var seq[int32], low, high: int) =
  var stack: seq[tuple[l, h: int]] = @[(low, high)]
  while stack.len > 0:
    let (l, h) = stack.pop()
    if l >= h: continue

    let pivot = arr[l + (h - l) div 2]
    var i = l
    var j = h
    while i <= j:
      while arr[i] < pivot: inc i
      while arr[j] > pivot: dec j
      if i <= j:
        let tmp = arr[i]
        arr[i] = arr[j]
        arr[j] = tmp
        inc i; dec j

    if l < j: stack.add((l, j))
    if i < h: stack.add((i, h))

method test(self: SortQuick): seq[int32] =
  var arr = self.data
  if arr.len > 0:
    quickSort(arr, 0, arr.len - 1)
  arr

registerBenchmark("Sort::Quick", newSortQuick)
