# vmath_raylib.nim
# ============================================================================
# vmath ↔ raylib 类型自动转换绑定
#
# 提供 vmath（行优先、泛型数学库）与 raylib（C 绑定、列优先）之间的
# 函数式转换和可选的隐式转换器。所有向量/四元数转换均为零拷贝 cast。
#
# 类型对应:
#   vmath          raylib
#   ────────────   ────────────
#   Vec2      ←→   Vector2      (零拷贝 · 同布局)
#   Vec3      ←→   Vector3      (零拷贝 · 同布局)
#   Vec4      ←→   Vector4      (零拷贝 · 同布局)
#   Quat      ←→   Quaternion   (零拷贝 · 同布局)
#   Vec4      ←→   Rectangle    (零拷贝 · x/y/width/height)
#   Mat4      ←→   Matrix       (显式转置 · 行优先↔列优先)
#   DMat4      →   Matrix       (显式转置 · float64→float32)
#   Color      →   uint32/Vec4  (便捷辅助)
#
# 用法:
#   import vmath_raylib
#   let rv: Vector3 = myVec3.toRaylib()
#   let vv: Vec3     = myVector3.toVmath()
#
# 启用隐式转换器（谨慎使用，可能引发歧义错误）:
#   默认启用。禁用: -d:vmrayNoConverters
# ============================================================================
import vmath except Vec2, Vec3, Vec4
import raylib

# 将 vmath 类型重新导出（避免与 raylib ShaderUniformDataType 的 Vec2 冲突）
export vmath except Vec2, Vec3, Vec4
export raylib
export vmath.Vec2, vmath.Vec3, vmath.Vec4

# ============================================================================
# 编译时验证内存布局兼容性
# ============================================================================
static:
  # 所有 vmath 模式（array/object/objArray）都应该兼容 raylib 的 {.bycopy.} object
  # 只要内存布局一致即可安全 cast

  # --- float32 向量 ---
  assert sizeof(vmath.Vec2) == sizeof(Vector2), "Vec2 ↔ Vector2 size mismatch"
  assert alignof(vmath.Vec2) == alignof(Vector2), "Vec2 ↔ Vector2 alignment mismatch"

  assert sizeof(vmath.Vec3) == sizeof(Vector3), "Vec3 ↔ Vector3 size mismatch"
  assert alignof(vmath.Vec3) == alignof(Vector3), "Vec3 ↔ Vector3 alignment mismatch"

  assert sizeof(vmath.Vec4) == sizeof(Vector4), "Vec4 ↔ Vector4 size mismatch"
  assert alignof(vmath.Vec4) == alignof(Vector4), "Vec4 ↔ Vector4 alignment mismatch"

  # --- 四元数 ---
  assert sizeof(Quat) == sizeof(Quaternion), "Quat ↔ Quaternion size mismatch"
  assert alignof(Quat) == alignof(Quaternion), "Quat ↔ Quaternion alignment mismatch"

  # --- Rectangle vs Vec4（均为 4 × float32） ---
  assert sizeof(vmath.Vec4) == sizeof(Rectangle), "Vec4 ↔ Rectangle size mismatch"

  # --- 双精度向量大小验证 ---
  assert sizeof(DVec2) == sizeof(Vector2)*2, "DVec2 size unexpected"
  assert sizeof(DVec3) == sizeof(Vector3)*2, "DVec3 size unexpected"
  assert sizeof(DVec4) == sizeof(Vector4)*2, "DVec4 size unexpected"

# ============================================================================
# 零拷贝转换模板（减少重复代码）
# ============================================================================

template defZeroCopyPair(vmType, rayType, suffix: untyped) =
  func toRaylib*(v: vmType): rayType {.inline, noinit.} = cast[rayType](v)
  func toVmath*(v: rayType): vmType {.inline, noinit.} = cast[vmType](v)

  when not defined(vmrayNoConverters):
    converter `toRay suffix`*(v: vmType): rayType {.inline, noinit.} = cast[rayType](v)
    converter `toVmath suffix`*(v: rayType): vmType {.inline, noinit.} = cast[vmType](v)

defZeroCopyPair(vmath.Vec2, Vector2, Vec2)
defZeroCopyPair(vmath.Vec3, Vector3, Vec3)

# Vec4 和 Quat 同为 GVec4[float32]，toRaylib 方向不能重载（toVmath 方向可区分 Quaternion/distinct）
func toRaylib*(v: vmath.Vec4): Vector4 {.inline, noinit.} = cast[Vector4](v)
func toRaylibQuat*(q: Quat): Quaternion {.inline, noinit.} = cast[Quaternion](q)
func toVmath*(v: Vector4): vmath.Vec4 {.inline, noinit.} = cast[vmath.Vec4](v)
func toVmath*(q: Quaternion): Quat {.inline, noinit.} = cast[Quat](q)

when not defined(vmrayNoConverters):
  converter toRayVec4*(v: vmath.Vec4): Vector4 {.inline, noinit.} = cast[Vector4](v)
  converter toRayQuat*(q: Quat): Quaternion {.inline, noinit.} = cast[Quaternion](q)
  converter toVmathVec4*(v: Vector4): vmath.Vec4 {.inline, noinit.} = cast[vmath.Vec4](v)
  converter toVmathQuat*(q: Quaternion): Quat {.inline, noinit.} = cast[Quat](q)

# ============================================================================
# 双精度 → 单精度转换（需要显式值转换）
# ============================================================================

func toRaylibDVec2*(v: DVec2): Vector2 {.inline.} =
  Vector2(x: v.x.float32, y: v.y.float32)

func toRaylibDVec3*(v: DVec3): Vector3 {.inline.} =
  Vector3(x: v.x.float32, y: v.y.float32, z: v.z.float32)

func toRaylibDVec4*(v: DVec4): Vector4 {.inline.} =
  Vector4(x: v.x.float32, y: v.y.float32, z: v.z.float32, w: v.w.float32)

# 别名：统一命名风格
func toRaylib*(v: DVec2): Vector2 {.inline.} = toRaylibDVec2(v)
func toRaylib*(v: DVec3): Vector3 {.inline.} = toRaylibDVec3(v)
func toRaylib*(v: DVec4): Vector4 {.inline.} = toRaylibDVec4(v)

# ============================================================================
# 单精度 → 双精度转换
# ============================================================================

func toVmathDVec2*(v: Vector2): DVec2 {.inline.} =
  dvec2(v.x.float64, v.y.float64)

func toVmathDVec3*(v: Vector3): DVec3 {.inline.} =
  dvec3(v.x.float64, v.y.float64, v.z.float64)

func toVmathDVec4*(v: Vector4): DVec4 {.inline.} =
  dvec4(v.x.float64, v.y.float64, v.z.float64, v.w.float64)

func toVmathDQuat*(q: Quaternion): DQuat {.inline.} =
  dquat(q.x.float64, q.y.float64, q.z.float64, q.w.float64)

# 别名：统一命名风格
func toVmathD*(v: Vector2): DVec2 {.inline.} = toVmathDVec2(v)
func toVmathD*(v: Vector3): DVec3 {.inline.} = toVmathDVec3(v)
func toVmathD*(v: Vector4): DVec4 {.inline.} = toVmathDVec4(v)
func toVmathD*(q: Quaternion): DQuat {.inline.} = toVmathDQuat(q)

# ============================================================================
# 矩阵转换（注意列优先 vs 行优先）
# ============================================================================

# --- vmath Mat4 (行优先) → raylib Matrix (列优先) ---
func toRaylib*(m: Mat4): Matrix {.inline.} =
  ## 将 vmath 行优先 Mat4 转置为 raylib 列优先 Matrix
  Matrix(
    m0: m[0,0], m4: m[1,0], m8:  m[2,0], m12: m[3,0],
    m1: m[0,1], m5: m[1,1], m9:  m[2,1], m13: m[3,1],
    m2: m[0,2], m6: m[1,2], m10: m[2,2], m14: m[3,2],
    m3: m[0,3], m7: m[1,3], m11: m[2,3], m15: m[3,3]
  )

# --- raylib Matrix (列优先) → vmath Mat4 (行优先) ---
func toVmath*(m: Matrix): Mat4 {.inline.} =
  ## 将 raylib 列优先 Matrix 转置为 vmath 行优先 Mat4
  mat4(
    m.m0, m.m1, m.m2, m.m3,
    m.m4, m.m5, m.m6, m.m7,
    m.m8, m.m9, m.m10, m.m11,
    m.m12, m.m13, m.m14, m.m15
  )

func toVmathD*(m: Matrix): DMat4 {.inline.} =
  ## 将 raylib 列优先 Matrix 转为 vmath 双精度行优先 DMat4
  dmat4(
    m.m0.float64, m.m1.float64, m.m2.float64, m.m3.float64,
    m.m4.float64, m.m5.float64, m.m6.float64, m.m7.float64,
    m.m8.float64, m.m9.float64, m.m10.float64, m.m11.float64,
    m.m12.float64, m.m13.float64, m.m14.float64, m.m15.float64
  )

# --- vmath DMat4 (double, 行优先) → raylib Matrix (float32, 列优先) ---
func toRaylib*(m: DMat4): Matrix {.inline.} =
  ## 将 vmath 双精度行优先 DMat4 转为 raylib 单精度列优先 Matrix
  Matrix(
    m0: m[0,0].float32, m4: m[1,0].float32, m8:  m[2,0].float32, m12: m[3,0].float32,
    m1: m[0,1].float32, m5: m[1,1].float32, m9:  m[2,1].float32, m13: m[3,1].float32,
    m2: m[0,2].float32, m6: m[1,2].float32, m10: m[2,2].float32, m14: m[3,2].float32,
    m3: m[0,3].float32, m7: m[1,3].float32, m11: m[2,3].float32, m15: m[3,3].float32
  )

# ============================================================================
# Color 相关便捷转换
# ============================================================================

func toColor*(hex: uint32): Color {.inline.} =
  ## uint32 hex 颜色 (0xRRGGBBAA) → raylib Color
  Color(
    r: ((hex shr 24) and 0xFF).uint8,
    g: ((hex shr 16) and 0xFF).uint8,
    b: ((hex shr  8) and 0xFF).uint8,
    a: ( hex        and 0xFF).uint8
  )

func toUint32*(c: Color): uint32 {.inline.} =
  ## raylib Color → uint32 hex (0xRRGGBBAA)
  (c.r.uint32 shl 24) or (c.g.uint32 shl 16) or (c.b.uint32 shl 8) or c.a.uint32

func toColor*(v: vmath.Vec4): Color {.inline.} =
  ## Vec4 (0..1 归一化) → raylib Color (0..255)
  Color(
    r: (v.x * 255).clamp(0, 255).uint8,
    g: (v.y * 255).clamp(0, 255).uint8,
    b: (v.z * 255).clamp(0, 255).uint8,
    a: (v.w * 255).clamp(0, 255).uint8
  )

func toVec4*(c: Color): vmath.Vec4 {.inline.} =
  ## raylib Color (0..255) → Vec4 (0..1 归一化)
  vec4(
    c.r.float32 / 255.0,
    c.g.float32 / 255.0,
    c.b.float32 / 255.0,
    c.a.float32 / 255.0
  )

# ============================================================================
# Rectangle 便捷函数
# ============================================================================

func toRect*(x, y, w, h: float32): Rectangle {.inline.} =
  Rectangle(x: x, y: y, width: w, height: h)

func toRect*(v: vmath.Vec4): Rectangle {.inline.} =
  Rectangle(x: v.x, y: v.y, width: v.z, height: v.w)

func toVec4*(r: Rectangle): vmath.Vec4 {.inline.} =
  vec4(r.x, r.y, r.width, r.height)

# ============================================================================
# vmath Mat3 ↔ raylib Matrix
# ============================================================================

func toRaylib*(m: Mat3): Matrix {.inline.} =
  ## vmath Mat3 → raylib Matrix（补齐为单位矩阵）
  Matrix(
    m0: m[0,0], m4: m[1,0], m8:  m[2,0], m12: 0,
    m1: m[0,1], m5: m[1,1], m9:  m[2,1], m13: 0,
    m2: m[0,2], m6: m[1,2], m10: m[2,2], m14: 0,
    m3: 0,      m7: 0,      m11: 0,       m15: 1
  )

func toVmathMat3*(m: Matrix): Mat3 {.inline.} =
  ## raylib Matrix → vmath Mat3（提取左上 3×3 子矩阵）
  mat3(
    m.m0, m.m1, m.m2,
    m.m4, m.m5, m.m6,
    m.m8, m.m9, m.m10
  )

# ============================================================================
# 验证转换正确性
# ============================================================================

when isMainModule:
  import std/math

  # --- 向量转换 ---
  block:
    let v1 = vec3(1, 2, 3)
    let v2 = v1.toRaylib()
    let v3 = v2.toVmath()
    assert v1 == v3, "Vec3 roundtrip failed"

  block:
    let v1 = vec4(1, 2, 3, 4)
    let v2 = v1.toRaylib()
    let v3 = v2.toVmath()
    assert v1 == v3, "Vec4 roundtrip failed"

  # --- 四元数转换 ---
  block:
    let q1 = quat(0, 0, 0, 1)
    let q2 = q1.toRaylibQuat()
    let q3 = q2.toVmath()
    assert q1 == q3, "Quat roundtrip failed"

  # --- 矩阵转换 ---
  block:
    let m1 = mat4(
      1, 2, 3, 4,
      5, 6, 7, 8,
      9, 10, 11, 12,
      13, 14, 15, 16
    )
    let m2 = m1.toRaylib()
    let m3 = m2.toVmath()
    assert m1 == m3, "Mat4 roundtrip failed"

  # --- 单位矩阵 ---
  block:
    let m1 = mat4()  # identity
    let m = m1.toRaylib()
    assert m.m0 == 1 and m.m5 == 1 and m.m10 == 1 and m.m15 == 1, "Identity Matrix failed"

  # --- Rectangle 转换 ---
  block:
    let r1 = Rectangle(x: 10, y: 20, width: 100, height: 50)
    let v = r1.toVec4()
    assert v.x == 10 and v.y == 20 and v.z == 100 and v.w == 50, "Rect→Vec4 failed"
    let r2 = v.toRect()
    assert r1 == r2, "Rect roundtrip failed"

  # --- Color 转换 ---
  block:
    let c1 = Color(r: 255, g: 128, b: 64, a: 32)
    let v = c1.toVec4()
    assert abs(v.x - 1.0) < 0.01, "Color→Vec4 R failed"
    assert abs(v.y - 0.502) < 0.01, "Color→Vec4 G failed"
    let c2 = v.toColor()
    assert c1 == c2, "Color roundtrip failed"

  # --- hex Color ---
  block:
    let c = toColor(0xFF804020'u32)
    assert c.r == 0xFF and c.g == 0x80 and c.b == 0x40 and c.a == 0x20, "hex→Color failed"
    assert c.toUint32() == 0xFF804020'u32, "Color→hex failed"

  # --- 双精度向量转换 ---
  block:
    let dv = dvec3(1.5, 2.5, 3.5)
    let rv = dv.toRaylib()
    assert rv.x == 1.5 and rv.y == 2.5 and rv.z == 3.5, "DVec3→Vector3 failed"
    let dv2 = rv.toVmathD()
    assert dv == dv2, "DVec3 roundtrip failed"

  echo "✅ All conversions verified"
