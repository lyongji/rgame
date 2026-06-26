import raylib
import tool/dpi
import raytext
import point_sampler
import std/[options, math, random]

const
  基准宽 = 800
  基准高 = 600

var
  算法名列表 = [
    "1 均匀随机",
    "2 Halton",
    "3 Hammersley",
    "4 抖动网格",
    "5 拉丁超立方",
    "6 高斯聚类",
    "7 泊松盘",
    "8 随机游走纤维",
    "9 随机拒绝过滤",
    "10 函数拒绝过滤",
    "11 距离拒绝过滤",
    "12 拒绝采样",
    "13 重要性重采样",
    "14 K-means 聚类",
    "15 DBSCAN 聚类",
    "16 逾渗聚类",
    "17 K-近邻松弛",
  ]
  当前算法 = 0

type 带色点 = object
  pos: Point[float64, 2]
  color: Color

proc 生成(索引: int): seq[带色点] =
  let 范围 = [(0.0, 1.0), (0.0, 1.0)]
  let 种 = some(uint32(42))
  template 填色(pts: seq[Point[float64, 2]], c: Color) =
    for pt in pts: result.add(带色点(pos: pt, color: c))

  case 索引
  of 0: 填色 random[float64, 2](1200, 范围, 种), Color(r: 100, g: 200, b: 255, a: 220)
  of 1: 填色 halton[float64, 2](1200, 范围), Color(r: 255, g: 180, b: 100, a: 220)
  of 2: 填色 hammersley[float64, 2](1200, 范围, 种), Color(r: 180, g: 255, b: 100, a: 220)
  of 3: 填色 jitteredGrid[float64, 2](1200, 范围, 种), Color(r: 255, g: 100, b: 180, a: 220)
  of 4: 填色 latinHypercubeSampling[float64, 2](1200, 范围, 种), Color(r: 100, g: 255, b: 200, a: 220)
  of 5: 填色 gaussianClusters[float64, 2](10, 120, 范围, 0.05, 种), Color(r: 200, g: 200, b: 100, a: 220)
  of 6: 填色 poissonDiskSamplingUniform[float64, 2](1500, 范围, 0.025, 种), Color(r: 100, g: 150, b: 255, a: 220)
  of 7: 填色 randomWalkFilaments[float64, 2](5, 200, 0.008, 范围, 种), Color(r: 255, g: 150, b: 150, a: 220)

  of 8:
    let src = random[float64, 2](3000, 范围, 种)
    填色 randomRejectionFilter(src, 0.3f), Color(r: 200, g: 150, b: 255, a: 220)

  of 9:
    let src = random[float64, 2](2000, 范围, 种)
    proc 密度(p: Point[float64, 2]): float64 =
      let dx = p[0] - 0.5; let dy = p[1] - 0.5
      exp(-(dx*dx + dy*dy) / 0.05)
    填色 functionRejectionFilter(src, 密度, 种), Color(r: 150, g: 200, b: 255, a: 220)

  of 10:
    let src = random[float64, 2](5000, 范围, 种)
    填色 distanceRejectionFilter(src, 0.04), Color(r: 255, g: 200, b: 150, a: 220)

  of 11:
    proc 密度11(p: Point[float64, 2]): float64 =
      let dx = p[0] - 0.5; let dy = p[1] - 0.5
      1.0 - sqrt(dx*dx + dy*dy) / 0.7
    填色 rejectionSampling[float64, 2](500, 范围, 密度11, 种), Color(r: 100, g: 255, b: 150, a: 220)

  of 12:
    proc 密度12(p: Point[float64, 2]): float64 =
      let dx = p[0] - 0.5; let dy = p[1] - 0.5
      exp(-(dx*dx + dy*dy) / 0.1) + 0.2
    填色 importanceResampling[float64, 2](800, 10, 范围, 密度12, 种), Color(r: 255, g: 255, b: 150, a: 220)

  of 13:
    let src = random[float64, 2](800, 范围, 种)
    let (中心, 标签) = kmeansClustering(src, 5)
    let 簇色 = [
      Color(r: 255, g: 100, b: 100, a: 220),
      Color(r: 100, g: 255, b: 100, a: 220),
      Color(r: 100, g: 100, b: 255, a: 220),
      Color(r: 255, g: 255, b: 100, a: 220),
      Color(r: 255, g: 100, b: 255, a: 220),
    ]
    for i, pt in src:
      result.add(带色点(pos: pt, color: 簇色[标签[i] mod 5]))

  of 14:
    let src = random[float64, 2](800, 范围, 种)
    let 标签 = dbscanClustering(src, 0.08, 5)
    for i, pt in src:
      let lb = 标签[i]
      if lb >= 0:
        result.add(带色点(pos: pt, color: Color(r: uint8(50 + lb*40 mod 200), g: uint8(100 + lb*30 mod 150), b: uint8(150 + lb*50 mod 100), a: 220)))
      else:
        result.add(带色点(pos: pt, color: Color(r: 80, g: 80, b: 80, a: 120)))

  of 15:
    let src = random[float64, 2](200, 范围, 种)
    let 标签 = percolationClustering(src, 0.12)
    for i, pt in src:
      let lb = 标签[i]
      result.add(带色点(pos: pt, color: Color(r: uint8(50 + lb*50 mod 200), g: uint8(100 + lb*30 mod 100), b: uint8(200 - lb*40 mod 150), a: 220)))

  of 16:
    var src = random[float64, 2](500, 范围, 种)
    relaxationKtree(src, 5, 0.6, 100)
    填色 src, Color(r: 200, g: 200, b: 255, a: 220)

  else:
    填色 random[float64, 2](1200, 范围, 种), Color(r: 100, g: 200, b: 255, a: 220)

proc 主函数 =
  let 窗口 = 初始化窗口("PointSampler — 点采样演示 (J/L 切换)",
                        基准宽 = 基准宽, 基准高 = 基准高)
  defer: closeWindow()
  let 字体 = 加载全字体("/usr/share/fonts/TTF/MapleMono-CN-Regular.ttf", 22)

  # 点绘制区域 = 窗口尺寸 - 100 px 边距（每边各 50）
  let 边距 = 50
  let 画布宽 = 窗口.屏幕宽 - 边距*2
  let 画布高 = 窗口.屏幕高 - 边距*2
  let 画布偏移 = 边距

  func 实际映射(x, y: float64): tuple[x, y: int32] =
    (x: int32(x * 画布宽.float64 + 画布偏移.float64),
     y: int32((1.0 - y) * 画布高.float64 + 画布偏移.float64))

  var 点列表 = 生成(当前算法)
  setTargetFPS(30)

  while not windowShouldClose():
    if isKeyPressed(J):
      当前算法 = (当前算法 - 1 + 算法名列表.len) mod 算法名列表.len
      点列表 = 生成(当前算法)
    if isKeyPressed(L):
      当前算法 = (当前算法 + 1) mod 算法名列表.len
      点列表 = 生成(当前算法)

    beginDrawing()
    clearBackground(Color(r: 20, g: 20, b: 30, a: 255))

    for 点 in 点列表:
      let (x, y) = 实际映射(点.pos[0], 点.pos[1])
      drawCircle(x, y, 5.5, 点.color)

    绘制文本(字体, 算法名列表[当前算法],
              Vector2(x: 12, y: 6), 24, 1, White)
    绘制文本(字体, "点数 " & $点列表.len & "  |  J / L 切换",
              Vector2(x: 12, y: 32), 20, 1, Color(r: 120, g: 120, b: 120, a: 255))

    endDrawing()

主函数()
