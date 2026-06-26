import raylib, std/importutils
import tool/dpi
import raytext
import h3nim
import std/math

const
  屏幕高度 = 600
  屏幕宽度 = 800
  球体半径 = 2.0f

proc memAlloc(size: uint32): pointer {.importc: "MemAlloc".}

proc 经纬度转向量(纬度弧度, 经度弧度: float64): Vector3 =
  let 余弦 = cos(纬度弧度).float32
  result.x = cos(经度弧度).float32 * 余弦 * 球体半径
  result.y = sin(纬度弧度).float32 * 球体半径
  result.z = sin(经度弧度).float32 * 余弦 * 球体半径

type 带心边* = tuple[中心: Vector3, 起点, 终点: Vector3]

proc 生成H3球体轮廓(分辨率: int): seq[带心边] =
  var 迭代 = 初始化分辨率迭代(分辨率.cint)
  while 迭代.单元 != H3空:
    var 中心经纬度: 经纬度
    if 单元转经纬度(迭代.单元, addr 中心经纬度) != H3错误(0):
      步进分辨率迭代(addr 迭代); continue
    let 单元中心 = 经纬度转向量(中心经纬度.纬度, 中心经纬度.经度)
    var 边界: 单元边界
    if 单元转边界(迭代.单元, addr 边界) != H3错误(0):
      步进分辨率迭代(addr 迭代); continue
    let 顶点数 = 边界.顶点数.int
    for i in 0 ..< 顶点数:
      let j = (i + 1) mod 顶点数
      result.add((中心: 单元中心,
                   起点: 经纬度转向量(边界.顶点[i].纬度, 边界.顶点[i].经度),
                   终点: 经纬度转向量(边界.顶点[j].纬度, 边界.顶点[j].经度)))
    步进分辨率迭代(addr 迭代)

proc 绘制高亮单元(单元: H3索引) =
  var 中心经纬度: 经纬度
  if 单元转经纬度(单元, addr 中心经纬度) != H3错误(0): return
  var 边界: 单元边界
  if 单元转边界(单元, addr 边界) != H3错误(0): return

  let 顶点数 = 边界.顶点数.int
  let 偏移 = 1.002f  # 略外推避免 z-fighting
  let 中心 = 经纬度转向量(中心经纬度.纬度, 中心经纬度.经度)
  let 中心p = Vector3(x: 中心.x*偏移, y: 中心.y*偏移, z: 中心.z*偏移)

  var 三维点: array[10, Vector3]
  for i in 0 ..< 顶点数:
    let v = 经纬度转向量(边界.顶点[i].纬度, 边界.顶点[i].经度)
    三维点[i] = Vector3(x: v.x*偏移, y: v.y*偏移, z: v.z*偏移)

  # 半透明蓝色填充（线框模式下最明显）
  let 填充色 = Color(r: 0, g: 120, b: 255, a: 80)
  for i in 0 ..< 顶点数:
    let j = (i + 1) mod 顶点数
    drawTriangle3D(中心p, 三维点[i], 三维点[j], 填充色)

  # 亮蓝轮廓
  let 线色 = Color(r: 0, g: 200, b: 255, a: 255)
  for i in 0 ..< 顶点数:
    let j = (i + 1) mod 顶点数
    drawLine3D(三维点[i], 三维点[j], 线色)
    drawLine3D(三维点[i], 三维点[j], 线色)
    drawLine3D(三维点[i], 三维点[j], 线色)

proc 生成H3球体网格*(分辨率: int): Mesh =
  ## 遍历 H3 全分辨率单元，生成三角化球体网格
  privateAccess(Mesh)

  var
    顶点组: seq[float32]  # xyzxyz...
    法线组: seq[float32]
    纹理组: seq[float32]

  var 迭代 = 初始化分辨率迭代(分辨率.cint)
  while 迭代.单元 != H3空:
    var 中心经纬度: 经纬度
    if 单元转经纬度(迭代.单元, addr 中心经纬度) != H3错误(0):
      步进分辨率迭代(addr 迭代); continue

    let 中心纬度 = 中心经纬度.纬度; let 中心经度 = 中心经纬度.经度
    let 中心余弦 = cos(中心纬度).float32
    let cx = cos(中心经度).float32 * 中心余弦 * 球体半径
    let cy = sin(中心纬度).float32 * 球体半径
    let cz = sin(中心经度).float32 * 中心余弦 * 球体半径

    var 边界: 单元边界
    if 单元转边界(迭代.单元, addr 边界) != H3错误(0):
      步进分辨率迭代(addr 迭代); continue

    let 顶点数 = 边界.顶点数.int
    var bx, by, bz: array[10, float32]
    for i in 0 ..< 顶点数:
      let 纬度 = 边界.顶点[i].纬度; let 经度 = 边界.顶点[i].经度
      let 余弦 = cos(纬度).float32
      bx[i] = cos(经度).float32 * 余弦 * 球体半径
      by[i] = sin(纬度).float32 * 球体半径
      bz[i] = sin(经度).float32 * 余弦 * 球体半径

    for i in 0 ..< 顶点数:
      let j = (i + 1) mod 顶点数
      # 三个顶点：中心, 边界i, 边界j
      let 顶点数组 = [(cx, cy, cz), (bx[i], by[i], bz[i]), (bx[j], by[j], bz[j])]
      for (x, y, z) in 顶点数组:
        顶点组.add(x); 顶点组.add(y); 顶点组.add(z)
        let l = sqrt(x*x + y*y + z*z)
        法线组.add(x/l); 法线组.add(y/l); 法线组.add(z/l)
        纹理组.add(0.5f + arctan2(z, x) / (2*PI).float32)
        纹理组.add(0.5f - arcsin(y / 球体半径) / PI.float32)

    步进分辨率迭代(addr 迭代)

  let vn = 顶点组.len div 3
  let tn = vn div 3
  result.triangleCount = tn.int32; result.vertexCount = vn.int32
  result.vertices   = cast[typeof(result.vertices)](memAlloc(uint32(vn * 3 * sizeof(float32))))
  result.normals    = cast[typeof(result.normals)](memAlloc(uint32(vn * 3 * sizeof(float32))))
  result.texcoords  = cast[typeof(result.texcoords)](memAlloc(uint32(vn * 2 * sizeof(float32))))

  copyMem(result.vertices,  addr 顶点组[0], uint32(vn * 3 * sizeof(float32)))
  copyMem(result.normals,   addr 法线组[0], uint32(vn * 3 * sizeof(float32)))
  copyMem(result.texcoords, addr 纹理组[0], uint32(vn * 2 * sizeof(float32)))

  uploadMesh(result, false)

# ═══════════════════════════════════════════════════

proc 主函数 =
  discard 初始化窗口("H3 球体 — 六边形网格生成",
                        基准宽 = 屏幕宽度, 基准高 = 屏幕高度)
  defer: closeWindow()

  let 字体 = 加载全字体("/usr/share/fonts/TTF/MapleMono-CN-Regular.ttf", 32)

  var 棋盘格 = genImageChecked(2, 2, 1, 1, Red, Green)
  let 纹理 = loadTextureFromImage(棋盘格)
  reset(棋盘格)

  var 当前分辨率 = 1
  var H3网格 = 生成H3球体网格(当前分辨率)
  var H3模型 = loadModelFromMesh(H3网格)
  Model(H3模型).materials[0].maps[MaterialMapIndex.Diffuse].texture = 纹理
  zeroMem(addr H3网格, sizeof(H3网格))

  var 当前轮廓 = 生成H3球体轮廓(当前分辨率)
  var 是否显示轮廓 = true
  var 是否仅线框 = false
  # 初始高亮：相机从 (5,3,5) 看向原点，正面约 (-25°, -135°)
  var 正面经纬 = 度转经纬度(-25.0, -135.0)
  var 高亮单元 = 经纬度转单元(正面经纬, 1)

  var 相机 = Camera(
    position: Vector3(x: 5, y: 3, z: 5),
    target: Vector3(x: 0, y: 0, z: 0),
    up: Vector3(x: 0, y: 1, z: 0),
    fovy: 45,
    projection: Perspective
  )
  var 位置 = Vector3(x: 0, y: 0, z: 0)
  setTargetFPS(60)

  while not windowShouldClose():
    # 鼠标拾取
    let 鼠标位置 = getMousePosition()
    let 射线 = getScreenToWorldRay(鼠标位置, 相机)
    let 碰撞 = getRayCollisionSphere(射线, Vector3(x: 0, y: 0, z: 0), 球体半径)
    if 碰撞.hit:
      let 纬度 = arcsin(碰撞.point.y / 球体半径)
      let 经度 = arctan2(碰撞.point.z, 碰撞.point.x)
      var 经纬: 经纬度
      经纬.纬度 = 纬度; 经纬.经度 = 经度
      高亮单元 = 经纬度转单元(经纬, 当前分辨率)

    # 键盘
    let 新分辨率 =
      if isKeyPressed(One): 1
      elif isKeyPressed(Two): 2
      elif isKeyPressed(Three): 3
      else: 0
    if isKeyPressed(H): 是否显示轮廓 = not 是否显示轮廓
    if isKeyPressed(B): 是否仅线框 = not 是否仅线框

    if 新分辨率 > 0 and 新分辨率 != 当前分辨率:
      当前分辨率 = 新分辨率
      H3网格 = 生成H3球体网格(当前分辨率)
      H3模型 = loadModelFromMesh(H3网格)
      Model(H3模型).materials[0].maps[MaterialMapIndex.Diffuse].texture = 纹理
      zeroMem(addr H3网格, sizeof(H3网格))
      当前轮廓 = 生成H3球体轮廓(当前分辨率)

    if isMouseButtonDown(Right): updateCamera(相机, Orbital)

    beginDrawing()
    clearBackground(RayWhite)
    beginMode3D(相机)
    if not 是否仅线框:
      drawModel(Model(H3模型), 位置, 1, White)

    # 高亮填充（半透明三角形扇）
    if 高亮单元 != H3空:
      绘制高亮单元(高亮单元)

    if 是否显示轮廓 or 是否仅线框:
      let 相机位置 = 相机.position
      for 边 in 当前轮廓:
        let dx = 相机位置.x - 边.中心.x
        let dy = 相机位置.y - 边.中心.y
        let dz = 相机位置.z - 边.中心.z
        if 边.中心.x*dx + 边.中心.y*dy + 边.中心.z*dz > 0:
          drawLine3D(边.起点, 边.终点, Color(r: 64, g: 64, b: 64, a: 200))
    drawGrid(10, 1)
    endMode3D()

    绘制文本(字体, "H3 六边形球体", Vector2(x: 40, y: 10), 64, 1, Blue)
    绘制文本(字体, "1/2/3 密度  |  H 轮廓  |  B 线框  |  右键旋转", Vector2(x: 40, y: 60), 64, 1, DarkBlue)
    绘制文本(字体, "分辨率 " & $当前分辨率, Vector2(x: 920, y: 10), 64, 1, Maroon)
    绘制文本(字体, "面数: " & $Model(H3模型).meshes[0].triangleCount, Vector2(x: 920, y: 60), 64, 1, Maroon)
    if 是否显示轮廓: 绘制文本(字体, "轮廓: 开", Vector2(x: 920, y: 110), 64, 1, DarkGreen)
    else: 绘制文本(字体, "轮廓: 关", Vector2(x: 920, y: 110), 64, 1, Gray)
    if 是否仅线框: 绘制文本(字体, "模式: 仅线框", Vector2(x: 920, y: 160), 64, 1, DarkGreen)
    else: 绘制文本(字体, "模式: 实体", Vector2(x: 920, y: 160), 64, 1, Gray)
    if 高亮单元 != H3空:
      绘制文本(字体, "高亮: " & 单元转字符串(高亮单元), Vector2(x: 40, y: 110), 64, 1, Red)

    endDrawing()

主函数()
