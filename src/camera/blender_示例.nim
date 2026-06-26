## Blender 视口摄像机 — 用法示例
##
## 中键拖拽          : 轨道旋转
## Shift + 中键拖拽  : 平移视图
## 滚轮              : 推拉缩放
## 小键盘 1/3/7     : 前/右/顶 视图
## Ctrl+小键盘 1/3/7: 后/左/底 视图
## 小键盘 5          : 透视/正交 切换
## 小键盘 9          : 反向视图
## ESC               : 退出

import raylib
import ../mymath/vmath_raylib
import camera/blender_摄像机
import vmath

# ============================================================================
# 全局状态
# ============================================================================
var
  屏幕宽: int32
  屏幕高: int32

# ============================================================================
# 3D 场景
# ============================================================================
proc 绘制场景*() =
  drawGrid(20, 1.0)

  # XYZ 参考轴
  drawLine3D(vec3(0, 0, 0), vec3(5, 0, 0), Red)
  drawLine3D(vec3(0, 0, 0), vec3(0, 5, 0), Green)
  drawLine3D(vec3(0, 0, 0), vec3(0, 0, 5), Blue)

  # 散落立方体
  for x in countup(-4, 4, 2):
    for z in countup(-4, 4, 2):
      let 位置 = vec3(x.float32, 0.5, z.float32)
      drawCube(位置, 0.8, 0.8, 0.8, Maroon)
      drawCubeWires(位置, 0.8, 0.8, 0.8, fade(Maroon, 0.3))

  # 中心塔
  drawCube(vec3(0, 2, 0), 0.5, 4, 0.5, Gold)
  drawCubeWires(vec3(0, 2, 0), 0.5, 4, 0.5, fade(Gold, 0.4))

  # 浮动球体
  drawSphere(vec3(2, 1.5, 2), 0.6, Blue)
  drawSphere(vec3(-2, 1.5, -2), 0.6, Red)

  # 枢轴点标记
  drawSphere(vec3(0, 0, 0), 0.1, Yellow)

# ============================================================================
# HUD
# ============================================================================
proc 显示HUD*(屏幕宽, 屏幕高: int32; 摄像机: 视口摄像机) =
  let 投影名 = if 摄像机.投影 == Perspective: "透视" else: "正交"

  drawText("Blender 风格视口摄像机", 10, 10, 20, LightGray)
  drawText("投影: " & 投影名, 10, 35, 16, fade(LightGray, 0.6))
  drawText("枢轴: " & $摄像机.枢轴, 10, 55, 16, fade(LightGray, 0.6))
  drawText("距离: " & $摄像机.距离, 10, 75, 16, fade(LightGray, 0.6))
  drawText("方向: " & $摄像机.方向, 10, 95, 16, fade(LightGray, 0.6))

  drawText("中键: 旋转  |  Shift+中键: 平移  |  滚轮: 缩放", 10, 屏幕高 - 45, 14, fade(LightGray, 0.5))
  drawText("小键盘 1/3/7: 前/右/顶  |  5: 投影  |  9: 反向", 10, 屏幕高 - 25, 14, fade(LightGray, 0.5))

# ============================================================================
# 窗口初始化
# ============================================================================
proc 初始化窗口*() =
  setConfigFlags(flags(WindowResizable, WindowHighdpi))
  initWindow(1080, 720, "Blender 视口摄像机示例")
  let 缩放 = getWindowScaleDPI()
  屏幕宽 = int32(1080 * 缩放.x)
  屏幕高 = int32(720 * 缩放.x)
  setWindowSize(屏幕宽, 屏幕高)
  setTargetFPS(60)

proc 处理窗口事件*() =
  if isKeyPressed(F11):
    if isWindowState(WindowMaximized):
      restoreWindow()
    else:
      maximizeWindow()
  if isWindowResized():
    屏幕宽 = getScreenWidth()
    屏幕高 = getScreenHeight()

# ============================================================================
# 主入口
# ============================================================================
proc main =
  初始化窗口()
  defer: closeWindow()

  # ── 创建视口摄像机 ─────────────────────────────
  var 摄像机 = 新建视口摄像机(
    枢轴 = vec3(0, 0, 0),
    距离 = 12,
    方向 = vec3(-1, 0.5, -1),
    视野 = 45,
  )

  var 过渡: 过渡动画

  while not windowShouldClose():
    处理窗口事件()

    # 一句调用 = Blender 全部视口操作
    摄像机.视口更新(过渡)

    # 聚焦到原点（句号键自动聚焦到枢轴）
    if isKeyPressed(Period):
      摄像机.聚焦并调整距离(vec3(0, 0, 0), 5)

    # ── 绘制 ──────────────────────────────────────
    beginDrawing()
    clearBackground(RayWhite)

    # 隐式转换：视口摄像机自动转为 Camera3D
    beginMode3D(摄像机)
    绘制场景()
    endMode3D()

    显示HUD(屏幕宽, 屏幕高, 摄像机)

    endDrawing()

when isMainModule:
  main()
