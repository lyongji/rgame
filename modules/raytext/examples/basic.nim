## RayText 基本用法示例
##
## 构建: cd modules/raytext && nim c -r examples/basic.nim

import raylib, ../raytext

proc main =
  let 屏幕W = int32(800)
  let 屏幕H = int32(450)

  initWindow(屏幕W, 屏幕H, "RayText — 基础用法")
  defer: closeWindow()

  let 字体 = 加载全字体("/usr/share/fonts/TTF/MapleMono-NF-CN-Regular.ttf", 48)

  setTargetFPS(60)

  while not windowShouldClose():
    beginDrawing()
    clearBackground(RayWhite)

    绘制文本(字体, "你好世界！Hello World!", Vector2(x: 20, y: 20), 32, 2, DarkBlue)
    绘制文本(字体, "数学符号：∑ ∫ √ ∞ ≈ ≠ ≤ ≥", Vector2(x: 20, y: 70), 24, 2, DarkGreen)
    绘制文本(字体, "NF 图标：    ", Vector2(x: 20, y: 110), 24, 2, DarkPurple)

    let 区域 = Rectangle(x: 20, y: 180, width: 300, height: 150)
    绘制文本换行(字体, "自动换行测试：床前明月光，疑是地上霜。举头望明月，低头思故乡。",
                  区域, 20, 2, 4, DarkBlue)

    drawFPS(屏幕W - 80, 10)
    endDrawing()

main()
