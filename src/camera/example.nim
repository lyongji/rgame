## 摄像机模块用法示例
##
## WASD + 鼠标：自由移动
## 数字键 1-5：切换摄像机模式
## 滚轮：缩放（自由/第三人称/轨道模式）
## F11：最大化/还原窗口  |  拖拽边框自由调整窗口大小
## ESC：退出

import raylib
import ../mymath/vmath_raylib
import camera
import vmath

# ----------------------------------------------------------------------------
# 全局状态
# ----------------------------------------------------------------------------
var
  屏幕宽: int32
  屏幕高: int32

# ----------------------------------------------------------------------------
# 辅助：3D 场景
# ----------------------------------------------------------------------------
proc 绘制场景*() =
  ## 绘制一个简单的 3D 场景供摄像机观察

  # 网格地面
  drawGrid(20, 1.0)

  # 中心参考轴
  drawLine3D(vec3(0, 0, 0), vec3(3, 0, 0), Red)     # X 轴：红
  drawLine3D(vec3(0, 0, 0), vec3(0, 3, 0), Green)   # Y 轴：绿
  drawLine3D(vec3(0, 0, 0), vec3(0, 0, 3), Blue)    # Z 轴：蓝

  # 散落方块
  for x in countup(-4, 4, 2):
    for z in countup(-4, 4, 2):
      let 位置 = vec3(x.float32, 0.5, z.float32)
      let 颜色: Color = if (x + z) mod 4 == 0: Maroon else: DarkGray
      drawCube(位置, 0.8, 0.8, 0.8, 颜色)
      drawCubeWires(位置, 0.8, 0.8, 0.8, fade(颜色, 0.3))

  # 中心高塔
  drawCube(vec3(0, 2, 0), 0.5, 4, 0.5, Gold)
  drawCubeWires(vec3(0, 2, 0), 0.5, 4, 0.5, fade(Gold, 0.4))

  # 浮动球体
  drawSphere(vec3(2, 1.5, 2), 0.6, Blue)
  drawSphere(vec3(-2, 1.5, -2), 0.6, Red)
  drawSphere(vec3(2, 1.5, -2), 0.6, Green)
  drawSphere(vec3(-2, 1.5, 2), 0.6, Orange)

# ----------------------------------------------------------------------------
# 辅助：显示 HUD
# ----------------------------------------------------------------------------
proc 显示HUD*(屏幕宽, 屏幕高: int32; 摄像机: 摄像机; 模式名: string;
              是否已最大化: bool) =
  let 窗口状态 = if 是否已最大化: "最大化" else: $屏幕宽 & "×" & $屏幕高

  drawText("摄像机模式: " & 模式名, 10, 10, 20, LightGray)
  drawText("窗口: " & 窗口状态, 10, 35, 16, fade(LightGray, 0.6))
  drawText("位置: " & $摄像机.位置, 10, 55, 16, fade(LightGray, 0.6))
  drawText("目标: " & $摄像机.目标, 10, 75, 16, fade(LightGray, 0.6))
  drawText("前方: " & $摄像机.前方(), 10, 95, 16, fade(LightGray, 0.6))
  drawText("到目标距离: " & $摄像机.到目标距离(), 10, 115, 16, fade(LightGray, 0.6))

  drawText("[1]自由 [2]第一人称 [3]第三人称 [4]轨道 [5]自定义  [F11]最大化/还原",
           10, 屏幕高 - 30, 14, fade(LightGray, 0.5))

# ----------------------------------------------------------------------------
# 窗口管理
# ----------------------------------------------------------------------------
proc 初始化窗口*() =
  ## 初始化窗口（可调整大小 + HighDPI 支持）
  setConfigFlags(flags(WindowResizable, WindowHighdpi))

  initWindow(1080, 720, "摄像机模块示例 — WASD + 鼠标控制")

  # 按 DPI 缩放初始窗口
  let 缩放 = getWindowScaleDPI()
  屏幕宽 = int32(1080 * 缩放.x)
  屏幕高 = int32(720 * 缩放.x)
  setWindowSize(屏幕宽, 屏幕高)

  setTargetFPS(60)

proc 处理窗口事件*() =
  ## 处理窗口缩放和 F11 最大化

  # F11 切换最大化/还原
  if isKeyPressed(F11):
    if isWindowState(WindowMaximized):
      restoreWindow()
    else:
      maximizeWindow()

  # 窗口被用户拖拽缩放后，更新屏幕尺寸
  if isWindowResized():
    屏幕宽 = getScreenWidth()
    屏幕高 = getScreenHeight()

# ----------------------------------------------------------------------------
# 主入口
# ----------------------------------------------------------------------------
proc main =
  初始化窗口()
  defer: closeWindow()

  # ── 创建摄像机 ────────────────────────────────
  var 摄像机 = 新建摄像机(
    位置   = vec3(8, 4, 8),
    目标   = vec3(0, 1, 0),
    上向量 = vec3(0, 1, 0),
    视野   = 60,
    投影   = Perspective
  )

  var 当前模式: 摄像机模式 = 自由模式

  while not windowShouldClose():
    # ── 窗口管理（缩放 / 最大化） ──────────────
    处理窗口事件()

    # ── 模式切换 ────────────────────────────────
    if isKeyPressed(One):   当前模式 = 自由模式
    if isKeyPressed(Two):   当前模式 = 第一人称
    if isKeyPressed(Three): 当前模式 = 第三人称
    if isKeyPressed(Four):  当前模式 = 轨道模式
    if isKeyPressed(Five):  当前模式 = 用户自定义

    # ── 更新摄像机 ──────────────────────────────
    #
    # 便捷更新：根据当前模式自动处理键盘+鼠标输入
    # 也可直接调用各模式专属更新函数，效果等同：
    #   摄像机.自由模式更新()
    #   摄像机.第一人称更新()
    #   摄像机.第三人称更新()
    #   摄像机.轨道模式更新()
    # ────────────────────────────────────────────
    摄像机.更新(当前模式)

    # 自定义模式下，手动控制摄像机位置（沿椭圆轨道绕 Y 轴旋转）
    if 当前模式 == 用户自定义:
      let 角度 = getTime().float32 * 0.3
      摄像机.位置 = vec3(cos(角度) * 6, 3, sin(角度) * 6)
      摄像机.注视(vec3(0, 0, 0))

    # ── 模式中文名（用于 HUD） ──────────────────
    let 模式名 = case 当前模式
      of 自由模式:     "自由模式"
      of 第一人称:     "第一人称"
      of 第三人称:     "第三人称"
      of 轨道模式:     "轨道模式"
      of 用户自定义:   "用户自定义"

    let 是否已最大化 = isWindowState(WindowMaximized)

    # ── 绘制 ────────────────────────────────────
    beginDrawing()
    clearBackground(RayWhite)

    # 3D 场景
    beginMode3D(摄像机.转Raylib())
    绘制场景()
    endMode3D()

    # HUD
    显示HUD(屏幕宽, 屏幕高, 摄像机, 模式名, 是否已最大化)

    endDrawing()

when isMainModule:
  main()
