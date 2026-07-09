##
## 贝塞尔曲线交互式演示
##
##   红点 = 控制点（拖拽 / 右键删除 / 空白点击添加）
##   Q/W  = 升降阶（保持曲线形状，增减控制点）
##   J/K  = 曲线精度
##   T    = 切线 / 曲率圆
##   C    = 重置
##
import raylib, vmath, bezier, raytext, tool/dpi, std/[strformat]

func toVec2(p: DVec2): Vector2 {.inline.} =
  Vector2(x: p.x.float32, y: p.y.float32)
func toDVec2(p: Vector2): DVec2 {.inline.} =
  dvec2(p.x.float64, p.y.float64)

# ═══════════════════════════════════════════════════
# 绘制辅助
# ═══════════════════════════════════════════════════

proc drawCurve(curve: Curve; segs: int; color: Color; thick: float32) =
  if curve.n < 2: return
  var prev = curve.valueAt(0.0).toVec2
  for i in 1 .. segs:
    let curr = curve.valueAt(i.float64 / segs.float64).toVec2
    drawLine(prev, curr, thick, color)
    prev = curr

proc drawDashedLine(a, b: Vector2; dash, gap: float32; color: Color) =
  let len = sqrt((b.x - a.x)^2 + (b.y - a.y)^2)
  if len < 1: return
  let dx = (b.x - a.x) / len; let dy = (b.y - a.y) / len
  var t = 0'f32; var on = true
  while t < len:
    let seg = min(t + (if on: dash else: gap), len)
    if on:
      drawLine(Vector2(x: a.x + dx * t, y: a.y + dy * t),
               Vector2(x: a.x + dx * seg, y: a.y + dy * seg), 2, color)
    t = seg; on = not on

proc drawControlPolygon(curve: Curve; color: Color; dash, gap: float32) =
  for i in 0 ..< curve.n - 1:
    drawDashedLine(curve.controlPoints[i].toVec2,
                   curve.controlPoints[i + 1].toVec2, dash, gap, color)

proc drawTangent(curve: Curve; t: float64; len: float32; color: Color) =
  ## 绘制切线段 + 箭头
  let pt = curve.valueAt(t).toVec2
  let d  = curve.tangentAt(t).toVec2
  let tip = Vector2(x: pt.x + d.x*len, y: pt.y + d.y*len)
  drawLine(pt, tip, 2, color)
  # 小箭头
  let arrow = 8'f32
  let n = Vector2(x: -d.y, y: d.x)  # 垂直方向
  drawTriangle(tip,
    Vector2(x: tip.x - d.x*arrow + n.x*arrow*0.4, y: tip.y - d.y*arrow + n.y*arrow*0.4),
    Vector2(x: tip.x - d.x*arrow - n.x*arrow*0.4, y: tip.y - d.y*arrow - n.y*arrow*0.4),
    color)

proc drawCurvatureCircle(curve: Curve; t: float64; color: Color; thick: float32) =
  ## 绘制曲率圆 + 半径线
  let k = curve.curvatureAt(t)
  if abs(k) < 1e-10: return
  let r = 1.0 / abs(k)
  if r > 2000.0 or r < 1.0: return
  let pt = curve.valueAt(t)
  let n = curve.normalAt(t)
  let center = pt + n / k
  let cv = center.toVec2
  let rf = r.float32
  # 半径线（曲线点 → 圆心）
  drawLine(pt.toVec2, cv, 1, Color(r: color.r, g: color.g, b: color.b, a: 120))
  # 粗圆
  let steps = max(int32(thick / 2), 1'i32)
  for i in -steps .. steps:
    drawCircleLines(cv, rf + i.float32, color)
  # 圆心小点
  drawCircle(cv, 2, color)

proc drawPoint(pos: Vector2; label: string; r: float32; color: Color; lblSize: float32) =
  drawCircle(pos, r, color)
  drawCircleLines(pos, r + 1, Color(r: 255, g: 255, b: 255, a: 80))
  if label.len > 0:
    drawText(label, (pos.x + r + 4).int32, (pos.y - 7).int32, lblSize.int32, WHITE)

# ═══════════════════════════════════════════════════
# 主程序
# ═══════════════════════════════════════════════════

proc main* =
  let cfg = 初始化窗口("Bezier Curve Demo", 基准宽 = 1280, 基准高 = 800)
  defer: closeWindow()
  setTargetFPS(60)
  let (sw, sh, scl) = (cfg.屏幕宽, cfg.屏幕高, cfg.缩放比)

  let font = 加载字体("/usr/share/fonts/TTF/MapleMono-CN-Regular.ttf", 字号 = int32(20 * scl))
  let
    fz   = 20'f32 * scl
    tz   = 16'f32 * scl
    lz   = 14'f32 * scl
    pR  =  7'f32 * scl
    pRH =  9'f32 * scl
    pRD = 11'f32 * scl
    dash = 12'f32 * scl
    gap  =  8'f32 * scl

  # 初始控制点（三次贝塞尔）
  proc defaultPoints: seq[DVec2] =
    @[dvec2(sw.float64*0.15, sh.float64*0.65),
      dvec2(sw.float64*0.30, sh.float64*0.20),
      dvec2(sw.float64*0.55, sh.float64*0.80),
      dvec2(sw.float64*0.80, sh.float64*0.35)]

  var pts = defaultPoints()

  var
    segs     = 200
    showTan  = true
    showCurv = true
    drag     = -1
    hover    = -1

  while not windowShouldClose():
    let mouse = getMousePosition()

    # ── 输入 ──
    if isKeyPressed(C): pts = defaultPoints()
    if isKeyPressed(T):
      if showTan and showCurv: (showTan, showCurv) = (false, true)
      elif showCurv: (showTan, showCurv) = (true, false)
      else: (showTan, showCurv) = (true, true)
    if isKeyPressed(J) or isKeyPressed(Minus) or isKeyPressed(KpSubtract): segs = max(segs - 10, 10)
    if isKeyPressed(K) or isKeyPressed(Equal) or isKeyPressed(KpAdd): segs = min(segs + 10, 1000)

    # 升/降阶
    if isKeyPressed(Q) and pts.len > 2:
      var c = initCurve(pts)
      lowerOrder(c)
      pts = c.controlPoints
    if isKeyPressed(W) and pts.len < 16:
      var c = initCurve(pts)
      raiseOrder(c)
      pts = c.controlPoints

    # 鼠标交互
    hover = -1
    for i, p in pts:
      if checkCollisionPointCircle(mouse, p.toVec2, pRD): hover = i; break
    if isMouseButtonPressed(Left):
      if hover >= 0: drag = hover
      else: pts.add mouse.toDVec2
    if isMouseButtonReleased(Left): drag = -1
    if drag >= 0 and isMouseButtonDown(Left): pts[drag] = mouse.toDVec2
    if hover >= 0 and pts.len > 2 and isMouseButtonPressed(Right): pts.delete(hover)

    # ── 构建曲线 ──
    let curve = if pts.len >= 2: initCurve(pts)
                else: initCurve(@[dvec2(0, 0), dvec2(1, 1)])
    let ok = pts.len >= 2

    # ── 绘制 ──
    beginDrawing()
    clearBackground(Color(r: 22, g: 22, b: 32, a: 255))

    let grid = max(int32(50 * scl), 20'i32)
    for x in countup(0'i32, sw, grid): drawLine(x, 0, x, sh, Color(r: 40, g: 40, b: 50, a: 255))
    for y in countup(0'i32, sh, grid): drawLine(0, y, sw, y, Color(r: 40, g: 40, b: 50, a: 255))

    # 控制多边形（虚线）
    drawControlPolygon(curve, Color(r: 180, g: 180, b: 180, a: 150), dash, gap)

    # 曲线
    drawCurve(curve, segs, GOLD, thick = 3.0 * scl)

    # 切线（均匀采样 6 个点）
    if showTan and ok:
      let bb = curve.boundingBox
      let scale = length(bb.diagonal).float32 * 0.15
      for i in 0 .. 5:
        let t = (i.float64 + 0.5) / 6.0  # 0.083, 0.25, 0.417, 0.583, 0.75, 0.917
        let a = uint8(70 + i * 30)
        drawTangent(curve, t, scale, Color(r: 100, g: 180, b: 255, a: a))

    # 曲率圆（采样 5 个点，仅显示曲率显著处）
    if showCurv and pts.len >= 3:
      for i in 1 .. 4:
        let t = i.float64 / 5.0  # 0.2, 0.4, 0.6, 0.8
        let a = uint8(40 + i * 15)
        drawCurvatureCircle(curve, t, Color(r: 255, g: 100, b: 255, a: a), 1.5 * scl)

    # 包围盒
    if ok:
      let bb = curve.boundingBox
      drawRectangleLines(Rectangle(x: bb.min.x.float32, y: bb.min.y.float32,
                          width: (bb.max.x - bb.min.x).float32,
                          height: (bb.max.y - bb.min.y).float32),
                          2.0 * scl, Color(r: 100, g: 100, b: 100, a: 180))

    # 控制点
    for i, p in pts:
      let r = if drag == i: pRD elif hover == i: pRH else: pR
      let c = if drag == i: ORANGE elif hover == i: YELLOW else: RED
      drawPoint(p.toVec2, $i, r, c, lz)

    # ── HUD ──
    let hx = 20'i32
    drawFPS(hx, hx)
    var ly = int32(50 * scl)
    let dy = int32(fz + 4)
    template hud(s: string) =
      绘制文本(font, s, Vector2(x: hx.float32, y: ly.float32), fz, 2, LIGHTGRAY); ly += dy
    hud fmt"控制点: {curve.n}   阶数: {curve.n - 1}"
    hud fmt"弧长: {curve.length:.2f}"
    hud fmt"曲率@t=0.5: {curve.curvatureAt(0.5):.6f}"

    let tips = [
      "左键拖拽  移动",  "左键空白  添加", "右键      删除",
      "Q/W 升降阶",       "J/K 精度",       "T 切线/曲率  C 重置",
    ]
    for i, tip in tips:
      let y = sh - 20'i32 - (tips.len - i).int32 * int32(tz + 4)
      绘制文本(font, tip, Vector2(x: hx.float32, y: y.float32), tz, 2, GRAY)

    if drag >= 0:
      绘制文本(font, fmt"#{drag} ({pts[drag].x:.0f}, {pts[drag].y:.0f})",
               Vector2(x: (sw - 220).float32, y: 20), fz, 2, YELLOW)

    endDrawing()

when isMainModule:
  main()
