import nimib, std/[strutils, strformat, json]
import vmath

nbInit
# nb.darkMode

# ============================================================
# 目录相关 — 自动生成锚点导航
# ============================================================
var
  nb目录: NbText   # 存储目录的文本块，每添加一个标题就往里追加

template add目录 =
  nb目录 = newNbText(text = "# 目录：\n\n")
  nb.add nb目录

# ============================================================
# nb段落 模板 — 生成带锚点的标题，并同步更新目录
# 用法：nb段落 "# 一级标题" 或 nb段落 "## 二级标题"
# ============================================================
template nb段落(heading: string) =
  ##  生成一个 HTML 锚点标题，并添加到目录列表
  let titleText = heading.strip(chars = {'#'}).strip()      # 提取纯文本（去掉 # 号）
  let anchorName = titleText.toLower.replace(" ", "-")      # 生成 URL 友好的锚点 ID
  nbText "<a name=\"" & anchorName & "\"></a>\n" & heading & "\n\n"
  nb目录.text.add "1. <a href=\"#" & anchorName & "\">" & titleText & "</a>\n"

# ============================================================
# 文档正文
# ============================================================
add目录()

nb段落 "# vmath 使用手册"

nbText """
vmath 是一个 Nim 数学库，提供类似 **GLSL** 的向量、矩阵、四元数类型及常用几何运算。
支持 **单精度**（`float32`）和 **双精度**（`float64`），并包含整数、无符号整数、布尔向量变体。

> 所有类型均为 **值类型**（栈分配），运算符返回新值而不修改原值。

**主要特性概览**：

| 类别 | 具体类型 / 功能 |
|------|----------------|
| **向量** | `Vec2`/`Vec3`/`Vec4`（float32）、`DVec2`/`DVec3`/`DVec4`（float64）、`IVec2`/`IVec3`/`IVec4`（int32）、`UVec2`/`UVec3`/`UVec4`（uint32）、`BVec2`/`BVec3`/`BVec4`（bool） |
| **矩阵** | `Mat2`/`Mat3`/`Mat4`（float32）、`DMat2`/`DMat3`/`DMat4`（float64）— **列主序存储** |
| **四元数** | `Quat`（float32）和 `DQuat`（float64） |
| **运算符** | `+` `-` `*` `/`（逐分量）、`~=`（近似相等，默认容差 1e-6） |
| **Swizzle** | `.x` `.y` `.z` `.w` 及任意组合如 `.xyzw` `.yzx`，支持读写 |
| **几何函数** | 长度/归一化、点积/叉积、角度/距离、线性插值、限制/量化 |
| **矩阵变换** | 平移/缩放/旋转、正交/透视投影、`lookAt` 视图矩阵 |
| **四元数** | 轴角构造、旋转向量、slerp/nlerp 插值、与矩阵互相转换 |
| **工具** | 弧度/度互换、角度规范化、`isNan` 检测等 |

"""

# ----------------------------------------------------------
# 安装
# ----------------------------------------------------------
nb段落 "## 安装"

nbText """
通过 Nimble 安装：

```bash
nimble install vmath
```

或在 `.nimble` 文件中添加依赖后，代码中直接导入：

```nim
import vmath   # 导入所有类型与函数
```
"""

# ----------------------------------------------------------
# 基础类型与导入
# ----------------------------------------------------------
nb段落 "## 基础类型与导入"

nbText """
```nim
import vmath
```

所有类型均位于 `vmath` 模块顶层，无需额外前缀。**类型别名对照表**：

| 别名 | 底层类型 | 说明 |
|------|---------|------|
| `Vec2` / `Vec3` / `Vec4` | `float32` | 单精度浮点向量 |
| `DVec2` / `DVec3` / `DVec4` | `float64` | 双精度浮点向量 |
| `IVec2` / `IVec3` / `IVec4` | `int32` | 有符号整数向量 |
| `UVec2` / `UVec3` / `UVec4` | `uint32` | 无符号整数向量 |
| `BVec2` / `BVec3` / `BVec4` | `bool` | 布尔向量（常用于比较结果） |
| `Mat2` / `Mat3` / `Mat4` | `float32` | 单精度矩阵（**列主序**） |
| `DMat2` / `DMat3` / `DMat4` | `float64` | 双精度矩阵 |
| `Quat` | `float32` | 单精度四元数（本质是 `Vec4`） |
| `DQuat` | `float64` | 双精度四元数 |

> ⚠️ **注意**：Nim 的 `PI` 常量是 `float64` 类型。vmath 函数多为泛型，当传入 `PI`（float64）
> 时会返回 `DMat4`/`DQuat` 等双精度类型，可能导致与单精度类型混合运算时报错。
> **建议**：在需要单精度时使用 `PI.float32` 或将字面量写为 `'f32` 后缀。
"""

# ============================================================
# 向量
# ============================================================
nb段落 "## 向量"

# --- 构造 ---
nb段落 "### 构造"

nbCode:
  # === 标量填充 ===
  # 传入单个标量，所有分量被设为相同值
  echo "vec2(1.0) = ", vec2(1.0)          # 结果: (1.0, 1.0)
  echo "vec3(2.0) = ", vec3(2.0)          # 结果: (2.0, 2.0, 2.0)
  echo "vec4(3.0) = ", vec4(3.0)          # 结果: (3.0, 3.0, 3.0, 3.0)

  # === 逐个分量构造 ===
  # 传入全部分量，Nim 会自动将 int 等类型转为目标浮点类型
  echo "vec2(1.0, 2.0) = ", vec2(1.0, 2.0)
  echo "vec3(1, 2, 3) = ", vec3(1, 2, 3)  # int → float32 自动转换

  # === 组合构造 ===
  # 可以用低维向量 + 标量拼接成高维向量
  echo "vec3(vec2(1,2), 3) = ", vec3(vec2(1,2), 3)             # (1,2) + 3 → (1,2,3)
  echo "vec4(vec3(1,2,3), 4) = ", vec4(vec3(1,2,3), 4)         # (1,2,3) + 4 → (1,2,3,4)
  echo "vec4(vec2(1,2), vec2(3,4)) = ", vec4(vec2(1,2), vec2(3,4))  # 两个 vec2 拼成 vec4

  # === 类型转换 ===
  # 不同精度/类型的向量可以互相转换构造
  echo "vec2(ivec2(1,2)) = ", vec2(ivec2(1,2))   # 整数向量 → 浮点向量

  # === 整数 / 布尔向量 ===
  echo "ivec3 = ", ivec3(-1, 0, 1)
  echo "uvec4 = ", uvec4(10, 20, 30, 40)
  echo "bvec2 = ", bvec2(true, false)             # 布尔向量常用于比较结果

# --- 访问与 Swizzle ---
nb段落 "### 访问与 Swizzle"

nbCode:
  var v = vec4(1, 2, 3, 4)

  # === 分量访问 ===
  # 支持 .x .y .z .w 命名分量 和 [0] [1] [2] [3] 数组下标
  echo v.x    # 输出: 1.0 — 第 0 分量
  echo v.y    # 输出: 2.0 — 第 1 分量
  echo v.z    # 输出: 3.0 — 第 2 分量
  echo v.w    # 输出: 4.0 — 第 3 分量
  echo v[0]   # 输出: 1.0 — 等价于 v.x

  # === Swizzle 读取 ===
  # 任意组合 .xyzw 可以生成任意维度的新向量
  echo "v.xy = ", v.xy        # 取前两个分量 → vec2(1.0, 2.0)
  echo "v.yzx = ", v.yzx      # 重排顺序     → vec3(2.0, 3.0, 1.0)
  echo "v.wzyx = ", v.wzyx    # 逆序         → vec4(4.0, 3.0, 2.0, 1.0)

  # === Swizzle 写入 ===
  # 可以对 swizzle 表达式赋值，修改原向量的对应分量
  var v2 = vec2(0, 0)
  v2.yx = vec2(10, 20)        # 同时修改 v2.y=10, v2.x=20
  echo "v2 after yx = ", v2   # 输出: vec2(20.0, 10.0) — x 和 y 被交换

  v.xy = vec2(5, 6)           # 只修改 v 的 x 和 y
  echo "v after xy = ", v     # 输出: vec4(5.0, 6.0, 3.0, 4.0)

# --- 向量运算 ---
nb段落 "### 向量运算"

nbCode:
  let a1 = vec2(1, 2)
  let b1 = vec2(3, 4)

  # === 逐分量算术运算 ===
  # + - * / 都是逐分量操作
  echo a1 + b1   # (1+3, 2+4)   = (4.0, 6.0)
  echo a1 - b1   # (1-3, 2-4)   = (-2.0, -2.0)
  echo a1 * b1   # (1*3, 2*4)   = (3.0, 8.0)
  echo a1 / b1   # (1/3, 2/4)   = (0.333..., 0.5)

  # === 标量与向量运算 ===
  # 标量 * 向量 或 向量 * 标量 均可
  echo a1 * 2    # (1*2, 2*2) = (2.0, 4.0)
  echo a1 / 2    # (1/2, 2/2) = (0.5, 1.0)

  # === 复合赋值运算符 ===
  # += -= *= /= 均支持
  var c1 = a1
  c1 += b1       # c1 变成 (4.0, 6.0)
  c1 *= 2        # c1 变成 (8.0, 12.0)
  echo "c1 after += and *=: ", c1

  # === 比较运算 ===
  # == 和 != 逐分量比较，返回布尔向量（BVec2）
  echo a1 == b1   # (1==3, 2==4) = (false, false) → BVec2
  echo a1 != b1   # (1!=3, 2!=4) = (true, true)   → BVec2

  # === 近似相等 ~= ===
  # 默认容差 1e-6，非常适合浮点比较
  echo a1 ~= vec2(1.000001, 2.000001)  # true — 误差在容差内

# --- 向量函数 ---
nb段落 "### 向量函数"

nbText """
以下函数适用于所有浮点向量类型（单/双精度），部分如 `lengthSq` 也适用于整数/布尔向量。

**长度与距离**
"""

nbCode:
  let v1 = vec3(1, 2, 2)

  # `length` — 欧几里得长度（模）
  echo v1.length          # sqrt(1²+2²+2²) = 3.0

  # `lengthSq` — 长度平方（避免 sqrt，性能更好）
  echo v1.lengthSq        # 1²+2²+2² = 9

  # `dist` / `distSq` — 两点之间的距离
  echo dist(vec2(0,0), vec2(3,4))      # sqrt(3²+4²) = 5.0
  echo distSq(vec2(0,0), vec2(3,4))    # 3²+4² = 25

  # `normalize` — 归一化为单位向量（方向不变，长度变 1）
  echo normalize(v1)      # (0.333..., 0.666..., 0.666...)

  # `dir(起点, 终点)` — 从起点指向终点的**单位**方向向量
  echo dir(vec3(0,0,0), vec3(10,0,0))  # (1.0, 0.0, 0.0)

nbText "**点积与叉积**"

nbCode:
  # `dot` — 点积（内积），结果为一个标量
  # 常用于：判断两个方向是否垂直（dot==0）、判断朝向（dot>0 同向）
  echo dot(vec2(1,0), vec2(0,1))   # 1*0 + 0*1 = 0 → 垂直

  # `cross` — 叉积（仅 3D 向量），结果为垂直于两向量的新向量
  # 常用于：计算法线方向
  echo cross(vec3(1,0,0), vec3(0,1,0))  # (0, 0, 1) → Z 轴方向

nbText "**角度**"

nbCode:
  # `angle(a, b)` — 两个向量之间的夹角（弧度）
  echo angle(vec2(1,0), vec2(0,1))       # PI/2 = 90°
  echo angle(vec3(1,0,0), vec3(0,1,0))   # PI/2 = 90°

  # `angle(v)` — 向量与 X 轴正方向的夹角
  echo angle(vec2(1,0))                  # 0 弧度
  echo angle(vec2(0,1))                  # PI/2 弧度

  # `dir(angle)` — 从弧度得到单位方向向量 (cos, sin)
  echo dir(1.57)                         # 约 (0, 1)，即 PI/2 方向

  # `angleBetween(a, b)` — 两个弧度之间的夹角差（自动考虑圆周环绕）
  echo angleBetween(0.1, 6.383)          # 约 0.1 弧度（绕了几乎一整圈）

  # `turnAngle(当前角, 目标角, 最大角速度)` — 向目标旋转，但不超过速度限制
  echo turnAngle(0.0, 1.57, 1.0)         # 1.0（最多转 1.0 rad）

nbText "**线性插值**"

nbCode:
  # `mix(a, b, t)` — 线性插值，t=0 得 a，t=1 得 b
  echo mix(0.0, 10.0, 0.5)                     # 5.0 — 标量插值

  # 向量也可以插值
  echo mix(vec2(0,0), vec2(10,20), 0.5)        # (5.0, 10.0)

  # 逐分量插值（第三个参数也是向量，各分量独立插值）
  echo mix(vec2(0,0), vec2(10,20), vec2(0.2,0.8))  # (2.0, 16.0)

  # 注：vmath 不含 GLSL 的 step/smoothstep，可用 clamp 和 mix 组合替代

nbText "**限制与量化**"

nbCode:
  # `clamp(v, min, max)` — 将值限制在 [min, max] 范围内
  echo clamp(vec3(5, -2, 10), 0.0, 5.0)      # (5.0, 0.0, 5.0)
  # 也可以传入向量形式的上下限
  echo clamp(vec2(5, -2), vec2(0,0), vec2(3,3))   # (3.0, 0.0)

  # `min` / `max` — 逐分量取最小/最大值
  echo min(vec3(5, -2, 10), vec3(0,0,5))     # (0.0, -2.0, 5.0)
  echo max(vec3(5, -2, 10), vec3(0,0,5))     # (5.0, 0.0, 10.0)

  # `quantize(v, n)` — 将 v 量化到 n 的整数倍（类似网格对齐）
  echo quantize(1.23456789, 0.01)            # 1.23

  # `fract(v)` — 取小数部分
  echo fract(3.14)                           # 0.14

  # `sign(v)` — 符号函数（返回 -1 或 1，注意 sign(0.0) = 1.0）
  echo sign(-5.0)                            # -1.0

  # `between(val, lo, hi)` — 判断值是否在区间内
  echo between(0.5, 0.0, 1.0)                # true

nbText "**杂项函数**"

nbCode:
  # `inversesqrt` — 平方根倒数（GLSL 风格，常用于快速归一化）
  echo inversesqrt(4.0)     # 1/sqrt(4) = 0.5

  # `zmod(a, b)` — GLSL 风格的取模（`mod` 是 Nim 关键字故加 ` 转义）
  echo zmod(5.5, 3.0)       # 5.5 - 3.0*floor(5.5/3.0) = 2.5

  # `fixAngle(rad)` — 将角度规范化到 [-PI, PI] 范围
  echo fixAngle(4.1)        # 4.1 - 2*PI ≈ -2.183...

  # `isNan(x)` — 判断是否为 NaN
  echo isNan(float32(0.0/0.0))  # true

# ============================================================
# 矩阵
# ============================================================
nb段落 "## 矩阵"

nbText """
vmath 的矩阵采用 **列主序**（column-major）存储，与 GLSL 一致。访问时使用
`[row, col]`（行优先索引），打印时也按行展示。

> 矩阵乘法 `A * B` 表示先应用 B 变换再应用 A 变换（与 GLSL 一致）。
"""

# --- 构造 ---
nb段落 "### 构造"

nbCode:
  # === 单位矩阵 ===
  # 无参构造得到单位矩阵
  echo "mat4() = ", mat4()                          # 4x4 单位矩阵

  # === 从标量元素构造（列主序） ===
  # mat2: 参数 1-2 为第 0 列，3-4 为第 1 列
  echo "mat2(1,2, 3,4) = ", mat2(1,2, 3,4)
  # mat3: 每 3 个参数为一列
  echo "mat3 = ", mat3(1,2,3, 4,5,6, 7,8,9)
  # mat4: 每 4 个参数为一列
  echo "mat4 = ", mat4(1,2,3,4, 5,6,7,8, 9,10,11,12, 13,14,15,16)

  # === 从列向量构造 ===
  # 每列传入一个向量，更直观易读
  echo "m2c = ", mat2(vec2(1,2), vec2(3,4))
  echo "m3c = ", mat3(vec3(1,2,3), vec3(4,5,6), vec3(7,8,9))
  echo "m4c = ", mat4(vec4(1,2,3,4), vec4(5,6,7,8), vec4(9,10,11,12), vec4(13,14,15,16))

  # === 双精度矩阵 ===
  echo "dmat4() = ", dmat4()                        # DMat4 单位矩阵

# --- 元素访问 ---
nb段落 "### 元素访问"

nbCode:
  var m = mat2(1,2, 3,4)

  # === 行列访问 [row, col] ===
  # 索引方式为行优先，内部存储为列主序（与 GLSL 一致）
  echo m[0,0]   # 第 0 行第 0 列 = 1.0
  echo m[0,1]   # 第 0 行第 1 列 = 2.0
  echo m[1,0]   # 第 1 行第 0 列 = 3.0
  echo m[1,1]   # 第 1 行第 1 列 = 4.0

  # 支持通过索引赋值
  m[0,1] = 99
  echo m[0,1]   # 99.0 — 已修改

  # === 按列访问 m[col] ===
  # 返回指定列的列向量
  echo m[0]     # 第 0 列 → vec2(1.0, 3.0)
  echo m[1]     # 第 1 列 → vec2(99.0, 4.0)

# --- 矩阵运算 ---
nb段落 "### 矩阵运算"

nbCode:
  let A = mat2(1,2, 3,4)   # A = [1 3; 2 4]（列主序→行视角）
  let B = mat2(5,6, 7,8)   # B = [5 7; 6 8]

  # === 矩阵乘法 ===
  # 注意：A * B 表示先 B 后 A 的变换组合
  echo "A * B = ", A * B

  # === 矩阵 × 向量 ===
  # 矩阵乘以列向量，返回变换后的向量
  let v2b = vec2(1, 2)
  echo "A * v2b = ", A * v2b

  # === 转置 ===
  # transpose 将矩阵的行和列互换
  echo "transpose(A) = ", transpose(A)

  # === 行列式 ===
  # 可用于判断矩阵是否可逆（det == 0 则不可逆）
  echo "det(A) = ", determinant(A)          # 1*4 - 3*2 = -2

  # === 逆矩阵 ===
  # inverse 求逆矩阵（若行列式为 0 则无意义）
  let invA = inverse(A)
  echo "invA = ", invA
  # 验证：原矩阵 × 逆矩阵 ≈ 单位矩阵
  echo A * invA ~= mat2()                    # true

# --- 变换矩阵 ---
nb段落 "### 变换矩阵"

nbText """
变换矩阵配合齐次坐标使用：2D 变换用 `Mat3`，3D 变换用 `Mat4`。
变换按**从右到左**的顺序应用：`transform * vec` 中，右侧的变换先作用于向量。

**2D 变换（`Mat3` 齐次坐标）**
"""

nbCode:
  # === 平移 ===
  # translate(vec2) 返回 Mat3 平移矩阵
  let trans2 = translate(vec2(10, 20))

  # === 缩放 ===
  # scale(vec2) 返回 Mat3 缩放矩阵
  let scale2 = scale(vec2(2, 3))       # X 轴放大 2 倍，Y 轴放大 3 倍

  # === 旋转 ===
  # rotate(弧度) 返回 Mat3 旋转矩阵（绕 Z 轴旋转，适用于 2D 平面）
  let rot2 = rotate(45.toRadians)

  # === 组合变换 ===
  # 从右到左：先缩放，再旋转，最后平移（这正是我们想要的顺序）
  let transform2D = trans2 * rot2 * scale2

  # === 应用变换 ===
  # 矩阵 * vec2 自动进行齐次变换，返回变换后的 vec2
  let point = vec2(1, 1)
  let transformed = transform2D * point
  echo "transformed point: ", transformed

  # === 获取平移分量 ===
  # Mat3/Mat4 变换矩阵的 .pos 返回平移部分
  echo "trans2.pos: ", trans2.pos        # vec2(10.0, 20.0)

nbText "**3D 变换（`Mat4`）**"

nbCode:
  # === 基本变换矩阵 ===
  let t  = translate(vec3(10, 20, 30))   # 平移
  let s  = scale(vec3(2, 2, 2))          # 均匀缩放
  let rx = rotateX((PI/4).float32)       # 绕 X 轴旋转 45°
  let ry = rotateY((PI/4).float32)       # 绕 Y 轴旋转 45°
  let rz = rotateZ((PI/4).float32)       # 绕 Z 轴旋转 45°

  # === 组合变换 ===
  # 顺序：先缩放 → 绕 XYZ 旋转 → 平移到最终位置
  let model = t * rz * ry * rx * s
  echo "model matrix: ", model

  # === 方向向量访问 ===
  # Mat4 提供 .forward .right .up 等属性，提取旋转后的方向
  let m1 = rotateY((PI/2).float32)       # 绕 Y 轴旋转 90°
  echo m1.forward   # (1.0, 0.0, 0.0) → 前方
  echo m1.right     # (0.0, 0.0, -1.0) → 右方
  echo m1.up        # (0.0, 1.0, 0.0) → 上方

  # === 提取纯旋转部分 ===
  # rotationOnly 去掉平移分量，仅保留旋转+缩放
  let rotOnly = rotationOnly(m1)
  echo "rotationOnly: ", rotOnly

nbText "**投影矩阵**"

nbCode:
  # === 正交投影 ===
  # ortho(left, right, bottom, top, near, far)
  let orth = ortho[float32](-1, 1, -1, 1, 0.1, 100)
  echo "ortho: ", orth

  # === 透视投影 ===
  # perspective(fovY弧度, 宽高比, near, far)
  let persp = perspective[float32](75, 16/9, 0.1, 1000)
  echo "perspective: ", persp

  # === 视景锥体 ===
  # frustum(left, right, bottom, top, near, far) — 非对称锥体
  let frust = frustum[float32](-1, 1, -1, 1, 1, 100)
  echo "frustum: ", frust

  # === 视图矩阵（LookAt） ===
  # lookAt(相机位置, 目标点, 上方向)
  let view = lookAt(vec3(5,5,5), vec3(0,0,0), vec3(0,1,0))
  echo "view matrix: ", view

  # 默认上方向为 (0,1,0)，可省略
  let viewDefault = lookAt(vec3(0,0,5), vec3(0,0,0))
  echo "viewDefault: ", viewDefault

# ============================================================
# 四元数
# ============================================================
nb段落 "## 四元数"

nbText """
四元数用于表示 3D 旋转，避免欧拉角的**万向节锁**问题。
vmath 的四元数本质是 `Vec4`（分量顺序 x, y, z, w）。

> `Quat` 是单精度四元数（`GVec4[float32]`），`DQuat` 是双精度版本。
"""

# --- 构造 ---
nb段落 "### 构造"

nbCode:
  # === 单位四元数 ===
  # quat(x, y, z, w)：w 为实部，(x,y,z) 为虚部
  # quat(0,0,0,1) 表示无旋转
  echo "qid: ", quat(0,0,0,1)

  # === 从轴角构造 ===
  # fromAxisAngle(旋转轴, 弧度) — 绕任意轴旋转
  let axis = normalize(vec3(1, 1, 0))        # 归一化旋转轴
  let qAxisAngle = fromAxisAngle(axis, 45.toRadians)
  echo "axis: ", axis, ", qAxisAngle: ", qAxisAngle

  # === 绕坐标轴旋转 ===
  # quatRotateX/Y/Z — 便捷函数，等效于 fromAxisAngle
  let qx = quatRotateX((PI/2).float32)       # 绕 X 轴 90°
  let qy = quatRotateY((PI/2).float32)       # 绕 Y 轴 90°
  let qz = quatRotateZ((PI/2).float32)       # 绕 Z 轴 90°
  echo "qx: ", qx

  # === 从两个向量之间的旋转构造 ===
  # fromTwoVectors(从, 到) — 自动计算最短旋转路径
  let qVecs = fromTwoVectors(vec3(1,0,0), vec3(0,1,0))
  echo "qVecs: ", qVecs

  # === 从旋转矩阵构造 ===
  # 矩阵.quat() — 提取四元数（要求矩阵是正交矩阵）
  let rotMat = rotateX((PI/3).float32)
  let qFromMat = rotMat.quat()
  echo "qFromMat: ", qFromMat

  # === 双精度四元数 ===
  echo "dq: ", dquat(0,0,0,1)

# --- 运算与旋转 ---
nb段落 "### 运算与旋转"

nbCode:
  # === 四元数乘法 ===
  # q1 * q2 表示先 q2 后 q1 的旋转组合
  var q = quatRotateZ((PI/2).float32)
  let qCombined = qx * qy * qz     # 先绕 Z、再绕 Y、再绕 X
  echo "qCombined: ", qCombined

  # === 逆 / 共轭 ===
  # quatInverse(q)：对于单位四元数，逆 = 共轭（x,y,z 取反）
  let qInv = quatInverse(q)
  echo q * qInv ~= quat(0,0,0,1)   # true — 四元数乘其逆得单位四元数

  # === 旋转向量 ===
  # q * vec3 等价于将四元数转为矩阵再乘向量
  let v3test = vec3(1, 0, 0)       # X 轴上的点
  let vRotated = q * v3test        # 绕 Z 轴旋转 90° → (0, 1, 0)
  echo "vRotated: ", vRotated

  # === 获取旋转矩阵 ===
  # q.mat4() 将四元数转为 4x4 旋转矩阵
  let rotMat4 = q.mat4()
  echo "rotMat4: ", rotMat4

  # === 归一化 ===
  # normalize(q) — 保持旋转不变，确保四元数模长为 1
  let qNorm = normalize(q)
  echo "qNorm: ", qNorm

# --- 插值 ---
nb段落 "### 插值"

nbCode:
  let qStart = quatRotateX(0.1'f32)    # 起始四元数
  let qEnd   = quatRotateZ(0.8'f32)    # 结束四元数

  # === 球面线性插值（Slerp） ===
  # slerp(a, b, t) — 在四元数单位球面上**匀速**插值
  # 比线性插值更准确，适用于较大的旋转角度
  let qMid = slerp(qStart, qEnd, 0.5'f32)
  echo "slerp: ", qMid

  # === 归一化线性插值（Nlerp） ===
  # nlerp(a, b, t) — 先线性插值再归一化
  # 比 slerp 更快，适用于角度差异较小的场景
  # 注意：nlerp 仅支持 Quat（float32）类型
  let qNlerp = nlerp(qStart, qEnd, 0.5'f32)
  echo "nlerp: ", qNlerp

# --- 转换 ---
nb段落 "### 转换"

nbCode:
  # === 四元数 → 欧拉角 ===
  # toAngles(q) 返回 Vec3(x 旋转, y 旋转, z 旋转)，单位弧度
  let euler = toAngles(q)
  echo "euler: ", euler

  # === 欧拉角 → 四元数 ===
  # fromAngles(Vec3) 从欧拉角构造四元数
  let qFromEuler = fromAngles(euler)
  echo "qFromEuler: ", qFromEuler

  # === 四元数 → 轴角 ===
  # toAxisAngle(q) 返回 (旋转轴向量, 旋转弧度)
  let (axis2, angle2) = toAxisAngle(q)
  echo "axis2: ", axis2, ", angle2: ", angle2

  # === 方向向量 → 欧拉角 ===
  # dirVec.toAngles() 直接从方向向量计算欧拉角
  let dirVec = vec3(1, 0, 0)
  let angles = dirVec.toAngles()
  echo "angles from dir: ", angles

  # === 矩阵 → 欧拉角 ===
  # 旋转矩阵.toAngles() 从矩阵提取欧拉角
  let rotMatrix = rotateY((PI/4).float32)
  let eulerFromMat = rotMatrix.toAngles()
  echo "eulerFromMat: ", eulerFromMat

# ============================================================
# 杂项实用函数
# ============================================================
nb段落 "## 杂项实用函数"

nbText """
以下是一些零散但实用的工具函数总结：

- **`toRadians` / `toDegrees`**：弧度与度数互转，作为浮点数扩展方法使用。
- **`randomize(seed)`**：初始化随机数生成器（vmath 内部某些随机函数依赖于此）。
- **`isNan`**：检测 `float32`/`float64` 是否为 NaN。
- **`$`（字符串化）**：所有向量/矩阵/四元数类型都支持 `$` 操作符，自动转为可读字符串。

示例：
"""

nbCode:
  # === 角度转换 ===
  echo "180° → rad: ", 180.toRadians()     # 3.14159...
  echo "PI rad → °: ", PI.toDegrees()      # 180.0

  # === 输出格式 ===
  # 四元数打印为 "vec4(x, y, z, w)" 格式
  echo "quat: ", quat(1, 2, 3, 4)

  # 矩阵打印为多行格式，每列一行
  echo "mat2:"
  echo mat2(1,2,3,4)
  # 输出：
  # mat2(
  #   1.0, 2.0,
  #   3.0, 4.0
  # )

# ============================================================
# 参考链接
# ============================================================
nb段落 "## 参考链接"

nbText """
- **GitHub 仓库**：[vmath](https://github.com/treeform/vmath) — 源码、Issues、贡献指南
- **GLSL 规范对照**：大部分函数行为与 GLSL 内置函数一致，熟悉 GLSL 可快速上手
- **nimib 文档生成**：[nimib](https://github.com/pietroppeter/nimib) — 本文档由 nimib 生成
"""

nbSave
