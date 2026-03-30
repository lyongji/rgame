# vmath_raylib.nim
import vmath
import raylib

export vmath
export raylib

# ============================================================================
# 编译时验证内存布局兼容性
# ============================================================================
when defined(vmathObjBased) or defined(vmathArrayBased) or defined(vmathObjArrayBased):
  static:
    # 验证向量布局兼容性
    assert sizeof(Vec2) == sizeof(Vector2), "Vec2 layout mismatch"
    assert sizeof(Vec3) == sizeof(Vector3), "Vec3 layout mismatch"
    assert sizeof(Vec4) == sizeof(Vector4), "Vec4 layout mismatch"
    assert sizeof(Quat) == sizeof(Quaternion), "Quat layout mismatch"
    
    # 验证对齐方式
    assert alignof(Vec3) == alignof(Vector3), "Vec3 alignment mismatch"
    assert alignof(Quat) == alignof(Quaternion), "Quat alignment mismatch"

# ============================================================================
# 零拷贝转换（向量和四元数）
# ============================================================================

# 单精度向量转换
func toRaylib*(v: Vec2): Vector2 {.inline, noinit.} = cast[Vector2](v)
func toRaylib*(v: Vec3): Vector3 {.inline, noinit.} = cast[Vector3](v)
func toRaylib*(v: Vec4): Vector4 {.inline, noinit.} = cast[Vector4](v)
func toRaylib*(q: Quat): Quaternion {.inline, noinit.} = cast[Quaternion](q)

func toVmath*(v: Vector2): Vec2 {.inline, noinit.} = cast[Vec2](v)
func toVmath*(v: Vector3): Vec3 {.inline, noinit.} = cast[Vec3](v)
func toVmath*(v: Vector4): Vec4 {.inline, noinit.} = cast[Vec4](v)
func toVmath*(q: Quaternion): Quat {.inline, noinit.} = cast[Quat](q)

# 双精度转换（需要显式转换）
func toRaylib*(v: DVec2): Vector2 {.inline.} = 
  Vector2(x: v.x.float32, y: v.y.float32)
func toRaylib*(v: DVec3): Vector3 {.inline.} = 
  Vector3(x: v.x.float32, y: v.y.float32, z: v.z.float32)
func toRaylib*(v: DVec4): Vector4 {.inline.} = 
  Vector4(x: v.x.float32, y: v.y.float32, z: v.z.float32, w: v.w.float32)

func toVmathD*(v: Vector2): DVec2 {.inline.} = 
  dvec2(v.x.float64, v.y.float64)
func toVmathD*(v: Vector3): DVec3 {.inline.} = 
  dvec3(v.x.float64, v.y.float64, v.z.float64)
func toVmathD*(v: Vector4): DVec4 {.inline.} = 
  dvec4(v.x.float64, v.y.float64, v.z.float64, v.w.float64)
func toVmathD*(q: Quaternion): DQuat {.inline.} = 
  dquat(q.x.float64, q.y.float64, q.z.float64, q.w.float64)

# ============================================================================
# 矩阵转换（注意列优先 vs 行优先）
# ============================================================================

# vmath (行优先) -> raylib (列优先)
func toRaylib*(m: Mat4): Matrix {.inline.} =
  # vmath 索引: m[row, col]
  # raylib 存储: m[col, row]
  Matrix(
    # 第 0 列
    m0: m[0,0], m4: m[1,0], m8:  m[2,0], m12: m[3,0],
    # 第 1 列
    m1: m[0,1], m5: m[1,1], m9:  m[2,1], m13: m[3,1],
    # 第 2 列
    m2: m[0,2], m6: m[1,2], m10: m[2,2], m14: m[3,2],
    # 第 3 列
    m3: m[0,3], m7: m[1,3], m11: m[2,3], m15: m[3,3]
  )

# raylib (列优先) -> vmath (行优先)
func toVmath*(m: Matrix): Mat4 {.inline.} =
  mat4(
    # 行 0: 来自各列的第一个元素
    m.m0, m.m1, m.m2, m.m3,
    # 行 1: 来自各列的第二个元素
    m.m4, m.m5, m.m6, m.m7,
    # 行 2: 来自各列的第三个元素
    m.m8, m.m9, m.m10, m.m11,
    # 行 3: 来自各列的第四个元素
    m.m12, m.m13, m.m14, m.m15
  )

# ============================================================================
# 便捷转换器
# ============================================================================

converter toRayVec2*(v: Vec2): Vector2 = cast[Vector2](v)
converter toRayVec3*(v: Vec3): Vector3 = cast[Vector3](v)
converter toRayVec4*(v: Vec4): Vector4 = cast[Vector4](v)
converter toRayQuat*(q: Quat): Quaternion = cast[Quaternion](q)

converter toVmathVec2*(v: Vector2): Vec2 = cast[Vec2](v)
converter toVmathVec3*(v: Vector3): Vec3 = cast[Vec3](v)
converter toVmathVec4*(v: Vector4): Vec4 = cast[Vec4](v)
converter toVmathQuat*(q: Quaternion): Quat = cast[Quat](q)

# 矩阵不提供自动转换（因为布局不同，避免混淆）

# ============================================================================
# 验证转换正确性（可选）
# ============================================================================

when isMainModule:
    # 验证向量转换
    let v1 = vec3(1, 2, 3)
    let v2 = v1.toRaylib()
    let v3 = v2.toVmath()
    assert v1 == v3, "Vector conversion failed"
    
    # 验证矩阵转换
    let m1 = mat4()
    let m2 = m1.toRaylib()
    let m3 = m2.toVmath()
    assert m1[0,0] == m3[0,0], "Matrix conversion failed"
    
    echo "✅ All conversions verified"
