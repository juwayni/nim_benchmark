import std/[math]
import ../benchmark
import ../helper

type
  Vector = object
    x, y, z: float
  Ray = object
    orig, dir: Vector
  Color = object
    r, g, b: float
  Sphere = object
    center: Vector
    radius: float
    color: Color

proc scale(v: Vector, s: float): Vector {.inline.} = Vector(x: v.x * s, y: v.y * s, z: v.z * s)
proc add(a, b: Vector): Vector {.inline.} = Vector(x: a.x + b.x, y: a.y + b.y, z: a.z + b.z)
proc sub(a, b: Vector): Vector {.inline.} = Vector(x: a.x - b.x, y: a.y - b.y, z: a.z - b.z)
proc dot(a, b: Vector): float {.inline.} = a.x * b.x + a.y * b.y + a.z * b.z
proc magnitude(v: Vector): float {.inline.} = sqrt(v.dot(v))
proc normalize(v: Vector): Vector {.inline.} =
  let mag = v.magnitude(); if mag == 0.0: return v
  v.scale(1.0 / mag)
proc scale(c: Color, s: float): Color {.inline.} = Color(r: c.r * s, g: c.g * s, b: c.b * s)
proc add(a, b: Color): Color {.inline.} = Color(r: a.r + b.r, g: a.g + b.g, b: a.b + b.b)

type
  TextRaytracer* = ref object of Benchmark
    w, h: int32
    resultVal: uint32

proc newTextRaytracer(): Benchmark = TextRaytracer()
method name(self: TextRaytracer): string = "Etc::TextRaytracer"

const
  WHITE = Color(r: 1.0, g: 1.0, b: 1.0)
  RED = Color(r: 1.0, g: 0.0, b: 0.0)
  GREEN = Color(r: 0.0, g: 1.0, b: 0.0)
  BLUE = Color(r: 0.0, g: 0.0, b: 1.0)
  LIGHT_POS = Vector(x: 0.7, y: -1.0, z: 1.7)
  LUT = ['.', '-', '+', '*', 'X', 'M']
  SCENE = [
    Sphere(center: Vector(x: -1.0, y: 0.0, z: 3.0), radius: 0.3, color: RED),
    Sphere(center: Vector(x: 0.0, y: 0.0, z: 3.0), radius: 0.8, color: GREEN),
    Sphere(center: Vector(x: 1.0, y: 0.0, z: 3.0), radius: 0.4, color: BLUE)
  ]

method prepare(self: TextRaytracer) =
  self.w = int32(self.config_val("w"))
  self.h = int32(self.config_val("h"))
  self.resultVal = 0

proc intersectSphere(ray: Ray, center: Vector, radius: float): float {.inline.} =
  let l = center.sub(ray.orig)
  let tca = l.dot(ray.dir)
  if tca < 0.0: return -1.0
  let d2 = l.dot(l) - tca * tca
  let r2 = radius * radius
  if d2 > r2: return -1.0
  let thc = sqrt(r2 - d2)
  tca - thc

method run(self: TextRaytracer, iteration_id: int) =
  for j in 0..<self.h:
    let fj = float(j); let fh = float(self.h)
    for i in 0..<self.w:
      let fi = float(i); let fw = float(self.w)
      let dir = normalize(Vector(x: (fi - fw/2.0)/fw, y: (fj - fh/2.0)/fh, z: 1.0))
      let ray = Ray(orig: Vector(x: 0, y: 0, z: 0), dir: dir)
      var tval = -1.0; var hitIdx = -1
      for k in 0..<SCENE.len:
        let t = intersectSphere(ray, SCENE[k].center, SCENE[k].radius)
        if t >= 0.0: (tval = t; hitIdx = k; break)
      var pixel = ' '
      if hitIdx != -1:
        let pi = ray.dir.scale(tval)
        let n = pi.sub(SCENE[hitIdx].center).normalize()
        let lightDir = LIGHT_POS.sub(pi).normalize()
        let lam = max(0.0, lightDir.dot(n))
        let color = WHITE.scale(lam * 0.5).add(SCENE[hitIdx].color.scale(0.3))
        let col = (color.r + color.g + color.b) / 3.0
        let idx = clamp(int(col * 6.0), 0, 5)
        pixel = LUT[idx]
      self.resultVal += uint8(pixel)

method checksum(self: TextRaytracer): uint32 = self.resultVal
registerBenchmark("Etc::TextRaytracer", newTextRaytracer)
