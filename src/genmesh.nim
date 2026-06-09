import raylib, std/importutils
import tool/dpi
import raytext

const
  屏幕高度 = 450
  屏幕宽度 = 800

  模型数量 = 9

proc memAlloc(size: uint32): pointer {.importc: "MemAlloc".}

proc 生成自定义网格(): Mesh =
  # 从代码生成一个简单的三角形网格
  privateAccess(Mesh)
  result = Mesh()
  result.triangleCount = 1
  result.vertexCount = result.triangleCount*3
  result.vertices = cast[typeof(result.vertices)](
      memAlloc(uint32(result.vertexCount*3*sizeof(float32)))) # 3 个顶点，每个 3 个坐标 (x, y, z)
  result.texcoords = cast[typeof(result.texcoords)](
      memAlloc(uint32(result.vertexCount*2*sizeof(float32)))) # 3 个顶点，每个 2 个坐标 (x, y)
  result.normals = cast[typeof(result.normals)](
      memAlloc(uint32(result.vertexCount*3*sizeof(float32)))) # 3 个顶点，每个 3 个坐标 (x, y, z)

  # 顶点 (0, 0, 0)
  result.vertices[0] = 0
  result.vertices[1] = 0
  result.vertices[2] = 0
  result.normals[0] = 0
  result.normals[1] = 1
  result.normals[2] = 0
  result.texcoords[0] = 0
  result.texcoords[1] = 0

  # 顶点 (1, 0, 2)
  result.vertices[3] = 1
  result.vertices[4] = 0
  result.vertices[5] = 2
  result.normals[3] = 0
  result.normals[4] = 1
  result.normals[5] = 0
  result.texcoords[2] = 0.5
  result.texcoords[3] = 1

  # 顶点 (2, 0, 0)
  result.vertices[6] = 2
  result.vertices[7] = 0
  result.vertices[8] = 0
  result.normals[6] = 0
  result.normals[7] = 1
  result.normals[8] = 0
  result.texcoords[4] = 1
  result.texcoords[5] = 0

  # 将网格数据从 CPU（RAM）上传到 GPU（VRAM）显存
  uploadMesh(result, false)

# ----------------------------------------------------------------------------------------
# 程序主入口
# ----------------------------------------------------------------------------------------

proc 主函数 =
  # 初始化
  # --------------------------------------------------------------------------------------
  let 窗口 = 初始化窗口("vmath_raylib — 类型转换演示",
                        基准宽 = 屏幕宽度, 基准高 = 屏幕高度)
  # initWindow(屏幕宽度, 屏幕高度, "raylib [models] 示例 - 网格生成")
  defer: closeWindow() # 关闭窗口和 OpenGL 上下文
  # 加载支持中文的字体（自动释放）
  let 字体 = 加载全字体("/usr/share/fonts/TTF/MapleMono-CN-Regular.ttf", 32)
  # 生成用于纹理的棋盘格图像
  var 棋盘格图像 = genImageChecked(2, 2, 1, 1, Red, Green)
  let 纹理 = loadTextureFromImage(棋盘格图像)
  reset(棋盘格图像)
  var 模型数组: array[模型数量, ModelFromMesh]
  # 生成网格
  let 网格平面      = genMeshPlane(2, 2, 5, 5)
  let 网格立方体       = genMeshCube(2, 1, 2)
  let 网格球体     = genMeshSphere(2, 32, 32)
  let 网格半球体 = genMeshHemiSphere(2, 16, 16)
  let 网格圆柱体   = genMeshCylinder(1, 2, 16)
  let 网格环面体      = genMeshTorus(0.25, 4, 16, 32)
  let 网格环结       = genMeshKnot(1, 2, 16, 128)
  let 网格多边形       = genMeshPoly(5, 2)
  let 网格自定义     = 生成自定义网格()

  # 从网格加载模型
  模型数组[0] = loadModelFromMesh(网格平面)
  模型数组[1] = loadModelFromMesh(网格立方体)
  模型数组[2] = loadModelFromMesh(网格球体)
  模型数组[3] = loadModelFromMesh(网格半球体)
  模型数组[4] = loadModelFromMesh(网格圆柱体)
  模型数组[5] = loadModelFromMesh(网格环面体)
  模型数组[6] = loadModelFromMesh(网格环结)
  模型数组[7] = loadModelFromMesh(网格多边形)
  模型数组[8] = loadModelFromMesh(网格自定义)

  # 生成的网格可以导出为 .obj 文件
  # discard exportMesh(模型数组[0].meshes[0], "plane.obj")
  # discard exportMesh(模型数组[1].meshes[0], "cube.obj")
  # discard exportMesh(模型数组[2].meshes[0], "sphere.obj")
  # discard exportMesh(模型数组[3].meshes[0], "hemisphere.obj")
  # discard exportMesh(模型数组[4].meshes[0], "cylinder.obj")
  # discard exportMesh(模型数组[5].meshes[0], "torus.obj")
  # discard exportMesh(模型数组[6].meshes[0], "knot.obj")
  # discard exportMesh(模型数组[7].meshes[0], "poly.obj")
  # discard exportMesh(模型数组[8].meshes[0], "custom.obj")
  # 设置棋盘格纹理为所有模型材质的默认漫反射分量
  for i in 0..<模型数量:
    Model(模型数组[i]).materials[0].maps[MaterialMapIndex.Diffuse].texture = 纹理
  # 定义用于观察 3D 世界的相机
  var 相机 = Camera(
    position: Vector3(x: 5, y: 5, z: 5),  # 相机位置
    target: Vector3(x: 0, y: 0, z: 0),    # 相机观察目标点
    up: Vector3(x: 0, y: 1, z: 0),        # 相机向上向量（朝向目标旋转）
    fovy: 45,                             # 相机视场角 Y
    projection: Perspective               # 相机投影类型
  )

  # 模型绘制位置
  var 位置 = Vector3(x: 0, y: 0, z: 0)
  var 当前模型索引: int32 = 0
  setTargetFPS(60) # 设置游戏以 60 帧每秒运行
  # --------------------------------------------------------------------------------------
  # 主游戏循环
  while not windowShouldClose(): # 检测窗口关闭按钮或 ESC 键
    # 更新
    # ------------------------------------------------------------------------------------
    updateCamera(相机, Orbital)
    if isMouseButtonPressed(Left):
      当前模型索引 = (当前模型索引 + 1) mod 模型数量
      # 在纹理之间循环切换
    if isKeyPressed(Right):
      inc(当前模型索引)
      if 当前模型索引 >= 模型数量:
        当前模型索引 = 0
    elif isKeyPressed(Left):
      dec(当前模型索引)
      if 当前模型索引 < 0:
        当前模型索引 = 模型数量 - 1
    # ------------------------------------------------------------------------------------
    # 绘制
    # ------------------------------------------------------------------------------------
    beginDrawing()
    clearBackground(RayWhite)
    beginMode3D(相机)
    drawModel(Model(模型数组[当前模型索引]), 位置, 1, White)
    drawGrid(10, 1)
    endMode3D()
    绘制文本(字体, "鼠标左键切换程序化生成的模型", Vector2(x: 40, y: 10), 64, 1, Blue)
    case 当前模型索引
    of 0:
      绘制文本(字体, "平面", Vector2(x: 980, y: 10), 64, 1, DarkBlue)
    of 1:
      绘制文本(字体, "立方体", Vector2(x: 980, y: 10), 64, 1, DarkBlue)
    of 2:
      绘制文本(字体, "球体", Vector2(x: 980, y: 10), 64, 1, DarkBlue)
    of 3:
      绘制文本(字体, "半球体", Vector2(x: 980, y: 10), 64, 1, DarkBlue)
    of 4:
      绘制文本(字体, "圆柱体", Vector2(x: 980, y: 10), 64, 1, DarkBlue)
    of 5:
      绘制文本(字体, "环面体", Vector2(x: 980, y: 10), 64, 1, DarkBlue)
    of 6:
      绘制文本(字体, "环结", Vector2(x: 980, y: 10), 64, 1, DarkBlue)
    of 7:
      绘制文本(字体, "多边形", Vector2(x: 980, y: 10), 64, 1, DarkBlue)
    of 8:
      绘制文本(字体, "自定义（三角形）", Vector2(x: 980, y: 10), 64, 1, DarkBlue)
    else:
      discard
    endDrawing()
    # ------------------------------------------------------------------------------------

主函数()
