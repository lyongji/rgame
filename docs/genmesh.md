# 程序化网格生成指南

> 基于 `src/genmesh.nim`，教你从零生成自定义 3D 网格并附上材质。

---

## 目录

- [前置准备](#前置准备)
- [核心概念](#核心概念)
- [第一步：用 raylib 内置函数生成标准网格](#第一步用-raylib-内置函数生成标准网格)
- [第二步：从零手动构建自定义网格](#第二步从零手动构建自定义网格)
- [第三步：为网格附加材质和纹理](#第三步为网格附加材质和纹理)
- [完整示例：将所有网格组合到一个场景](#完整示例将所有网格组合到一个场景)
- [导出网格](#导出网格)
- [进阶技巧](#进阶技巧)

---

## 前置准备

在你的 Nim 项目中引入所需模块：

```nim
import raylib              # 核心图形 API
import tool/dpi            # 窗口 DPI 自适应（可选）
import raytext             # 中文文本渲染（可选）
```

> 如果使用本文档配套的 `rgame` 项目结构，以上 import 开箱即用。

---

## 核心概念

| 概念      | 说明                                     |
| --------- | ---------------------------------------- |
| `Mesh`    | 存储在 CPU 上的原始网格数据（顶点/法线/UV） |
| `Model`   | 包含一个或多个 `Mesh` + 材质的完整模型     |
| `Material`| 控制渲染外观（颜色、纹理、光照参数等）       |
| `Texture` | 图像数据，贴到材质上作为漫反射/法线/…贴图   |

流程：

```
Mesh (CPU数据) → loadModelFromMesh() → Model (GPU就绪) → 设置材质纹理 → drawModel()
```

---

## 第一步：用 raylib 内置函数生成标准网格

raylib 内置了多种程序化网格生成函数，直接返回 `Mesh` 对象：

```nim
let 网格平面  = genMeshPlane(宽=2, 高=2, 细分X=5, 细分Z=5)
let 网格立方体 = genMeshCube(宽=2, 高=1, 深=2)
let 网格球体  = genMeshSphere(半径=2, 环数=32, 分段数=32)
let 网格半球体= genMeshHemiSphere(半径=2, 环数=16, 分段数=16)
let 网格圆柱体= genMeshCylinder(半径=1, 高=2, 分段数=16)
let 网格环面体= genMeshTorus(内径=0.25, 外径=4, 环分段=16, 管分段=32)
let 网格环结  = genMeshKnot(半径=1, 管半径=2, 管分段=16, 环分段=128)
let 网格多边形= genMeshPoly(边数=5, 半径=2)
```

所有函数签名中的参数都有默认值，可只传需要的参数：

```nim
let 球 = genMeshSphere()            # 半径=1, 环数=8, 分段数=8
let 立方体 = genMeshCube(3, 3, 3)  # 3x3x3
```

---

## 第二步：从零手动构建自定义网格

> 在 `genmesh.nim` 中，`生成自定义网格()` 演示了如何从零构建一个三角形。

### 网格结构速览

一个 `Mesh` 对象包含三个核心数组：

| 数组          | 类型           | 说明                                 |
| ------------- | -------------- | ------------------------------------ |
| `vertices`    | `ptr float32`  | 顶点坐标，每 3 个 float 为一个顶点 (x,y,z) |
| `normals`     | `ptr float32`  | 法线向量，每 3 个 float 为一个法线 (nx,ny,nz) |
| `texcoords`   | `ptr float32`  | UV 坐标，每 2 个 float 为一个纹理坐标 (u,v) |

额外的可选数组: `colors` (每个顶点颜色), `indices` (索引缓冲区), `animVertices`/`animNormals` (骨骼动画)。

### 分配内存

由于 Nim 的 raylib 绑定需要通过 `MemAlloc`（对应 C 的 `malloc`/`RL_MALLOC`）分配内存，确保 raylib 内部能正确释放：

```nim
proc memAlloc(size: uint32): pointer {.importc: "MemAlloc".}
```

> **重要**：不要用 Nim 的 `alloc()` 或 `new()`，必须用 `MemAlloc`，否则 `unloadMesh()` 可能崩溃。

### 开始构建：一个三角形网格

以下是构建一个红色三角形的完整步骤：

```nim
proc 生成自定义网格(): Mesh =
  # 启用对 Mesh 对象私有字段的访问
  privateAccess(Mesh)

  result = Mesh()
  result.triangleCount = 1      # 1 个三角形
  result.vertexCount = 3        # 3 个顶点

  # ── 分配顶点数据 (3 顶点 × 3 坐标 = 9 个 float) ──
  result.vertices = cast[ptr float32](
    memAlloc(uint32(result.vertexCount * 3 * sizeof(float32))))

  # ── 分配 UV 数据 (3 顶点 × 2 坐标 = 6 个 float) ──
  result.texcoords = cast[ptr float32](
    memAlloc(uint32(result.vertexCount * 2 * sizeof(float32))))

  # ── 分配法线数据 (3 顶点 × 3 坐标 = 9 个 float) ──
  result.normals = cast[ptr float32](
    memAlloc(uint32(result.vertexCount * 3 * sizeof(float32))))
```

#### 填充顶点坐标

```nim
  # 顶点 0: 位置 (0, 0, 0)
  result.vertices[0] = 0.0    # x
  result.vertices[1] = 0.0    # y
  result.vertices[2] = 0.0    # z

  # 顶点 1: 位置 (1, 0, 2)
  result.vertices[3] = 1.0
  result.vertices[4] = 0.0
  result.vertices[5] = 2.0

  # 顶点 2: 位置 (2, 0, 0)
  result.vertices[6] = 2.0
  result.vertices[7] = 0.0
  result.vertices[8] = 0.0
```

#### 填充法线

每个顶点都需要一个法线向量，用于光照计算。此处三角形朝上 (Y 轴正方向)：

```nim
  # 顶点 0 法线
  result.normals[0] = 0.0
  result.normals[1] = 1.0    # Y 轴向上
  result.normals[2] = 0.0

  # 顶点 1 法线
  result.normals[3] = 0.0
  result.normals[4] = 1.0
  result.normals[5] = 0.0

  # 顶点 2 法线
  result.normals[6] = 0.0
  result.normals[7] = 1.0
  result.normals[8] = 0.0
```

#### 填充 UV 坐标

UV 范围通常为 `[0, 1]`，决定纹理如何贴在三角形上：

```nim
  # 顶点 0 UV: 左下角
  result.texcoords[0] = 0.0    # u
  result.texcoords[1] = 0.0    # v

  # 顶点 1 UV: 上中
  result.texcoords[2] = 0.5
  result.texcoords[3] = 1.0

  # 顶点 2 UV: 右下角
  result.texcoords[4] = 1.0
  result.texcoords[5] = 0.0
```

#### 上传到 GPU

```nim
  # 第二个参数表示是否动态更新 (false = 静态数据)
  uploadMesh(result, false)
```

完成后，三角形网格即可用于渲染。

### 完整可用的函数

```nim
proc memAlloc(size: uint32): pointer {.importc: "MemAlloc".}

proc 生成自定义网格(): Mesh =
  privateAccess(Mesh)
  result = Mesh()
  result.triangleCount = 1
  result.vertexCount = 3

  result.vertices = cast[ptr float32](
    memAlloc(uint32(result.vertexCount * 3 * sizeof(float32))))
  result.texcoords = cast[ptr float32](
    memAlloc(uint32(result.vertexCount * 2 * sizeof(float32))))
  result.normals = cast[ptr float32](
    memAlloc(uint32(result.vertexCount * 3 * sizeof(float32))))

  # 顶点数据...
  result.vertices[0] = 0;  result.vertices[1] = 0;  result.vertices[2] = 0
  result.vertices[3] = 1;  result.vertices[4] = 0;  result.vertices[5] = 2
  result.vertices[6] = 2;  result.vertices[7] = 0;  result.vertices[8] = 0

  # 法线...
  result.normals[0] = 0;  result.normals[1] = 1;  result.normals[2] = 0
  result.normals[3] = 0;  result.normals[4] = 1;  result.normals[5] = 0
  result.normals[6] = 0;  result.normals[7] = 1;  result.normals[8] = 0

  # UV...
  result.texcoords[0] = 0;   result.texcoords[1] = 0
  result.texcoords[2] = 0.5; result.texcoords[3] = 1
  result.texcoords[4] = 1;   result.texcoords[5] = 0

  uploadMesh(result, false)
```

---

## 第三步：为网格附加材质和纹理

### 方式 A：单个纹理应用到所有材质

最简单的方式，用一个棋盘格纹理作为所有模型的漫反射贴图：

```nim
# 1. 生成棋盘格图像
var 棋盘格图像 = genImageChecked(2, 2, 1, 1, Red, Green)
let 纹理 = loadTextureFromImage(棋盘格图像)
reset(棋盘格图像)    # 图像上传 GPU 后可以释放 CPU 数据

# 2. 从网格加载模型
let 网格 = genMeshSphere(2, 32, 32)
var 模型 = loadModelFromMesh(网格)

# 3. 设置材质的漫反射纹理
模型.materials[0].maps[MaterialMapIndex.Diffuse].texture = 纹理

# 4. 渲染
drawModel(模型, Vector3(x:0, y:0, z:0), 1.0, White)
```

### 方式 B：为每个模型设置不同材质

```nim
# 不同颜色材质
var 模型 = loadModelFromMesh(genMeshCube(2, 1, 2))
模型.materials[0].maps[MaterialMapIndex.Diffuse].color = Red

var 模型2 = loadModelFromMesh(genMeshSphere(2, 32, 32))
模型2.materials[0].maps[MaterialMapIndex.Diffuse].color = Blue
```

### 材质贴图类型

`MaterialMapIndex` 枚举定义了可用的贴图通道：

| 枚举值                     | 用途             |
| -------------------------- | ---------------- |
| `Diffuse`                  | 漫反射（颜色/纹理）|
| `Metalness`               | 金属度           |
| `Normal`                  | 法线贴图         |
| `Roughness`               | 粗糙度           |
| `Occlusion`               | 环境光遮蔽       |
| `Emission`                | 自发光           |
| `Height`                  | 高度/位移贴图    |
| `Cubemap`                 | 立方体贴图       |
| `Irradiance`              | 辐照度贴图       |
| `Prefilter`               | 预过滤环境贴图   |
| `Brdf`                    | BRDF 查找表      |

---

## 完整示例：将所有网格组合到一个场景

以下代码来自 `src/genmesh.nim`，展示了 9 种网格的生成、纹理设置和交互切换：

```nim
import raylib
import tool/dpi   # 窗口 DPI 自适应
import raytext    # 中文文本渲染

const 屏幕宽 = 800
const 屏幕高 = 450

proc 主函数 =
  # ── 初始化窗口 ──
  let 窗口 = 初始化窗口("程序化网格生成",
                        基准宽 = 屏幕宽, 基准高 = 屏幕高)
  defer: closeWindow()

  # ── 加载字体（中文渲染）──
  let 字体 = 加载全字体("/usr/share/fonts/TTF/MapleMono-CN-Regular.ttf", 32)

  # ── 生成纹理 ──
  var 棋盘格图像 = genImageChecked(2, 2, 1, 1, Red, Green)
  let 纹理 = loadTextureFromImage(棋盘格图像)
  reset(棋盘格图像)

  # ── 生成全部网格 ──
  let 网格平面     = genMeshPlane(2, 2, 5, 5)
  let 网格立方体   = genMeshCube(2, 1, 2)
  let 网格球体     = genMeshSphere(2, 32, 32)
  let 网格半球体   = genMeshHemiSphere(2, 16, 16)
  let 网格圆柱体   = genMeshCylinder(1, 2, 16)
  let 网格环面体   = genMeshTorus(0.25, 4, 16, 32)
  let 网格环结     = genMeshKnot(1, 2, 16, 128)
  let 网格多边形   = genMeshPoly(5, 2)
  let 网格自定义   = 生成自定义网格()  # 见第二步

  # ── 从网格加载模型 ──
  var 模型数组: array[9, Model]
  模型数组[0] = loadModelFromMesh(网格平面)
  模型数组[1] = loadModelFromMesh(网格立方体)
  # ... 以此类推

  # ── 统一设置棋盘格纹理 ──
  for i in 0..<9:
    模型数组[i].materials[0].maps[MaterialMapIndex.Diffuse].texture = 纹理

  # ── 相机与渲染循环 ──
  var 相机 = Camera(
    position: Vector3(x: 5, y: 5, z: 5),
    target:   Vector3(x: 0, y: 0, z: 0),
    up:       Vector3(x: 0, y: 1, z: 0),
    fovy:     45,
    projection: Perspective
  )

  var 当前模型索引: int32 = 0
  setTargetFPS(60)

  while not windowShouldClose():
    updateCamera(相机, Orbital)        # 轨道控制相机

    # 鼠标/键盘切换模型
    if isMouseButtonPressed(Left) or isKeyPressed(Right):
      当前模型索引 = (当前模型索引 + 1) mod 9
    if isKeyPressed(Left):
      当前模型索引 = (当前模型索引 - 1 + 9) mod 9

    beginDrawing()
    clearBackground(RayWhite)
    beginMode3D(相机)
    drawModel(模型数组[当前模型索引], Vector3(x:0, y:0, z:0), 1, White)
    drawGrid(10, 1)
    endMode3D()
    绘制文本(字体, "按 ← → 切换模型", Vector2(x: 40, y: 10), 64, 1, Blue)
    endDrawing()

主函数()
```

---

## 导出网格

生成的网格可以导出为 `.obj` 文件，以便在其他 3D 软件中使用：

```nim
discard exportMesh(模型.meshes[0], "my_mesh.obj")
```

`genmesh.nim` 中注释掉的行展示了如何导出所有网格：

```nim
# discard exportMesh(模型数组[0].meshes[0], "plane.obj")
# discard exportMesh(模型数组[1].meshes[0], "cube.obj")
# discard exportMesh(模型数组[2].meshes[0], "sphere.obj")
# discard exportMesh(模型数组[3].meshes[0], "hemisphere.obj")
# discard exportMesh(模型数组[4].meshes[0], "cylinder.obj")
# discard exportMesh(模型数组[5].meshes[0], "torus.obj")
# discard exportMesh(模型数组[6].meshes[0], "knot.obj")
# discard exportMesh(模型数组[7].meshes[0], "poly.obj")
# discard exportMesh(模型数组[8].meshes[0], "custom.obj")
```

---

## 进阶技巧

### 1. 生成多个三角形的复杂网格

对于超过一个三角形的网格，需要正确计算顶点数量和三角形数量：

```nim
proc 生成四边形网格(): Mesh =
  privateAccess(Mesh)
  result = Mesh()
  result.triangleCount = 2    # 两个三角形组成四边形
  result.vertexCount = 6      # 6 个顶点 (每个三角形3个)

  # 分配内存同上...
  # 顶点 0-2: 三角形1
  # 顶点 3-5: 三角形2
```

### 2. 使用顶点颜色

除了 `vertices`/`normals`/`texcoords`，还可以填充 `colors` 数组 (每 4 个 `unsigned char` 为一个 RGBA 颜色)：

```nim
result.colors = cast[ptr uint8](
  memAlloc(uint32(result.vertexCount * 4 * sizeof(uint8))))
```

### 3. 动态更新网格

如果在 `uploadMesh()` 时第二个参数传 `true`（动态），可以每帧修改顶点数据：

```nim
uploadMesh(result, true)

# 在循环中更新：
result.vertices[0] = newX  # 修改顶点位置
updateMeshBuffer(result, 0, result.vertices,
                 result.vertexCount * 3 * sizeof(float32), 0)
```

### 4. 法线自动计算

对于复杂网格，可以用 `genMeshTangents()` 自动计算法线/切线：

```nim
# 手动填充顶点和索引后
genMeshTangents(result)  # 自动计算法线和切线
```

### 5. 释放资源

```nim
unloadModel(模型)     # 释放模型及其网格
unloadTexture(纹理)   # 释放纹理
unloadMesh(网格)      # 释放网格（如果单独持有）
unloadFont(字体)      # 释放字体
```

> **注意**：`Model` 持有 `Mesh` 的所有权，`unloadModel()` 会自动释放其内部的网格，无需再调 `unloadMesh()`。

---

## 参考

| 函数 | 说明 |
|------|------|
| `genMeshPlane(w, h, resX, resZ)` | 平面网格 |
| `genMeshCube(w, h, d)` | 立方体网格 |
| `genMeshSphere(radius, rings, slices)` | 球体网格 |
| `genMeshHemiSphere(radius, rings, slices)` | 半球体网格 |
| `genMeshCylinder(radius, height, slices)` | 圆柱体网格 |
| `genMeshTorus(innerR, outerR, sides, rings)` | 环面体网格 |
| `genMeshKnot(radius, tubeR, sides, rings)` | 环结网格 |
| `genMeshPoly(sides, radius)` | 多边形网格 |
| `loadModelFromMesh(mesh)` | 网格 → 模型 |
| `uploadMesh(mesh, dynamic)` | 上传网格到 GPU |
| `updateMeshBuffer(mesh, index, data, size, offset)` | 更新 GPU 缓冲区 |
| `exportMesh(mesh, filename)` | 导出为 .obj |
| `genImageChecked(w, h, checkX, checkY, col1, col2)` | 生成棋盘格图像 |
| `loadTextureFromImage(image)` | 图像 → 纹理 |

---

> 完整代码见 [`src/genmesh.nim`](../src/genmesh.nim)。
