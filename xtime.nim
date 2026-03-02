import std/[os, times, monotimes, osproc, strutils, strformat]

proc getPeakRSS(pid: int): int64 =
  let statusPath = &"/proc/{pid}/status"
  if fileExists(statusPath):
    for line in lines(statusPath):
      if line.startsWith("VmHWM:"):
        let parts = line.splitWhitespace()
        if parts.len >= 2:
          # VmHWM: 1234 kB
          try:
            return parts[1].parseInt()
          except ValueError:
            return 0
  return 0

proc main() =
  if paramCount() < 1:
    quit(1)

  let args = commandLineParams()
  let t0 = getMonoTime()

  let p = startProcess(args[0], args = args[1..^1], options = {poParentStreams})
  let pid = p.processID()

  var peakRSS: int64 = 0

  while p.running:
    let currentRSS = getPeakRSS(pid)
    if currentRSS > peakRSS:
      peakRSS = currentRSS
    sleep(30)

  let exitCode = p.waitForExit()
  let t1 = getMonoTime()

  let finalPeak = getPeakRSS(pid)
  if finalPeak > peakRSS:
    peakRSS = finalPeak

  let duration = (t1 - t0).inMilliseconds.float / 1000.0

  stderr.writeLine &"mem_usage: {peakRSS.float / 1024.0:.1f}Mb"
  stderr.writeLine &"duration: {duration:.3f}s"

  if exitCode != 0:
    quit(exitCode)

main()
