import raylib
import mymath/vmath_raylib
import curve/bezier  # 假设 bezier 模块位于上一级目录，根据实际路径调整
import vmath
# ----------------------------------------------------------------------------------------
# Global Variables Definition
# ----------------------------------------------------------------------------------------

let
  screenWidth  = (1080 * getWindowScaleDPI().x).int32
  screenHeight = (720 * getWindowScaleDPI().x).int32

# ----------------------------------------------------------------------------------------
# Program main entry point
# ----------------------------------------------------------------------------------------

proc main =
  # Initialization
  # --------------------------------------------------------------------------------------
  initWindow(screenWidth, screenHeight, "raylib [core] example - basic window")
  defer: closeWindow()
  setTargetFPS(60)
  
  # 定义贝塞尔曲线（三次贝塞尔曲线，4个控制点）
  let curve = newBezier[3](vec2(100.0, 500.0), vec2(200, 100), vec2(400, 100), vec2(500, 500))
  var 测试 =1
  echo 测试
  # --------------------------------------------------------------------------------------
  # Main game loop
  while not windowShouldClose(): # Detect window close button or ESC key
    # Update
    # ------------------------------------------------------------------------------------
    # 可在此更新曲线参数（例如随时间变化控制点），本例保持静态
    # ------------------------------------------------------------------------------------
    # Draw
    # ------------------------------------------------------------------------------------
    beginDrawing()
    clearBackground(Black)
    # 绘制网格背景
    for x in countup(0, screenWidth, 50):
      drawLine(x.int32, 0, x.int32, screenHeight, LightGray)
    for y in countup(0, screenHeight, 50):
      drawLine(0, y.int32, screenWidth, y.int32, LightGray)

    # 3. 绘制贝塞尔曲线（通过分段直线近似）
    let segments = 50
    var prevPoint = curve.compute(0.0)
    for i in 1..segments:
      let t = i.float / segments.float
      let currentPoint = curve.compute(t)
      drawLine(prevPoint, currentPoint, Maroon)
      prevPoint = currentPoint

    # 4. 绘制控制点
    for point in curve:
      drawCircle(point, 15, Red)

    # 5. 显示文本
    drawText("Basic shapes and Bezier curve", 190, 200, 20, LightGray)

    endDrawing()
    # ------------------------------------------------------------------------------------
  # De-Initialization
  # --------------------------------------------------------------------------------------

when isMainModule:
  main()
