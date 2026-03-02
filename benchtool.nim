import std/[os, osproc, strutils, strformat]

const
  SrcDir = "src"
  TargetDir = "target"
  MainFile = "src/benchmarks.nim"
  BinaryName = "bin_benchmarks"

proc runCommand(cmd: string) =
  echo &"Running: {cmd}"
  let res = execShellCmd(cmd)
  if res != 0:
    quit(&"Command failed with exit code {res}: {cmd}", res)

proc build(release = true, cpp = false) =
  createDir(TargetDir)
  let backend = if cpp: "cpp" else: "c"
  var cmd = &"nim {backend} --threads:on "
  if release:
    cmd &= "-d:release -d:danger "

  let suffix = if cpp: "_cpp" else: ""
  let outName = if release: BinaryName & "_release" & suffix else: BinaryName & suffix
  cmd &= &"--out:{TargetDir}/{outName} {MainFile}"

  runCommand(cmd)

proc run(release = true, configFile = "test.js", benchName = "", cpp = false) =
  let suffix = if cpp: "_cpp" else: ""
  let outName = if release: BinaryName & "_release" & suffix else: BinaryName & suffix
  let binary = TargetDir / outName
  if not fileExists(binary):
    build(release)

  let xtimeBin = TargetDir / "xtime"
  if not fileExists(xtimeBin):
    runCommand(&"nim c -o:{xtimeBin} xtime.nim")

  var cmd = &"{xtimeBin} {binary} {configFile} {benchName}"
  runCommand(cmd)

proc fmt() =
  runCommand(&"find {SrcDir} -name \"*.nim\" -exec nimpretty {{}} \\;")

proc main() =
  if paramCount() < 1:
    echo "Usage: benchtool <command> [args...]"
    echo "Commands: build, run, fmt, test"
    quit(1)

  let cmd = paramStr(1)
  case cmd
  of "build":
    let release = if paramCount() >= 2: (paramStr(2) == "release") else: true
    let cpp = if paramCount() >= 3: (paramStr(3) == "cpp") else: false
    build(release, cpp)
  of "run":
    let configFile = if paramCount() >= 2: paramStr(2) else: "test.js"
    let benchName = if paramCount() >= 3: paramStr(3) else: ""
    let cpp = if paramCount() >= 4: (paramStr(4) == "cpp") else: false
    run(true, configFile, benchName, cpp)
  of "fmt":
    fmt()
  of "test":
    run(false, "test.js", "")
  else:
    echo "Unknown command: ", cmd
    quit(1)

main()
