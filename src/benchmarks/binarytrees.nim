import ../benchmark

type
  TreeNode = object
    item: int
    left, right: ptr TreeNode

proc newTreeNode(item: int, depth: int, arena: var seq[TreeNode]): ptr TreeNode =
  let idx = arena.len
  arena.add(TreeNode(item: item))
  result = addr arena[idx]
  if depth > 0:
    let shift = 1 shl (depth - 1)
    result.left = newTreeNode(item - shift, depth - 1, arena)
    result.right = newTreeNode(item + shift, depth - 1, arena)

proc sum(node: ptr TreeNode): uint32 =
  result = uint32(node.item) + 1'u32
  if not node.left.isNil: result += sum(node.left)
  if not node.right.isNil: result += sum(node.right)

type
  BinarytreesObj* = ref object of Benchmark
    n: int
    resultVal: uint32
    arena: seq[TreeNode]

proc newBinarytreesObj(): Benchmark = BinarytreesObj()
method name(self: BinarytreesObj): string = "Binarytrees::Obj"
method prepare(self: BinarytreesObj) =
  self.n = self.config_val("depth").int
  self.resultVal = 0

method run(self: BinarytreesObj, iteration_id: int) =
  self.arena = newSeqOfCap[TreeNode]((1 shl (self.n + 1)) - 1)
  let tree = newTreeNode(0, self.n, self.arena)
  self.resultVal += tree.sum()
  self.arena = @[]

method checksum(self: BinarytreesObj): uint32 = self.resultVal
registerBenchmark("Binarytrees::Obj", newBinarytreesObj)

# Binarytrees::Arena optimization is already using a seq-based arena.
# We'll make it even faster by using a more efficient structure.
type
  TreeNodeArena = object
    item: int
    left: int32
    right: int32

  BinarytreesArena* = ref object of Benchmark
    n: int
    resultVal: uint32
    nodes: seq[TreeNodeArena]

proc build(nodes: var seq[TreeNodeArena], item: int, depth: int): int32 =
  let idx = nodes.len.int32
  nodes.add(TreeNodeArena(item: item, left: -1, right: -1))
  if depth > 0:
    let shift = 1 shl (depth - 1)
    let l = build(nodes, item - shift, depth - 1)
    let r = build(nodes, item + shift, depth - 1)
    nodes[idx].left = l
    nodes[idx].right = r
  return idx

proc sum(nodes: seq[TreeNodeArena], idx: int32): uint32 =
  let node = nodes[idx]
  result = uint32(node.item) + 1'u32
  if node.left != -1: result += sum(nodes, node.left)
  if node.right != -1: result += sum(nodes, node.right)

proc newBinarytreesArena(): Benchmark = BinarytreesArena()
method name(self: BinarytreesArena): string = "Binarytrees::Arena"
method prepare(self: BinarytreesArena) =
  self.n = self.config_val("depth").int
  self.resultVal = 0

method run(self: BinarytreesArena, iteration_id: int) =
  self.nodes = newSeqOfCap[TreeNodeArena]((1 shl (self.n + 1)) - 1)
  let root = build(self.nodes, 0, self.n)
  self.resultVal += sum(self.nodes, root)
  self.nodes = @[]

method checksum(self: BinarytreesArena): uint32 = self.resultVal
registerBenchmark("Binarytrees::Arena", newBinarytreesArena)
