## RayText 动态字体演示
##
## 按需加载字形，启动快，输入新字符时自动追加。
## 按 +/- 缩放字号，输入内容观察按需加载。
##
## 构建: cd modules/raytext && nim c -r examples/dynamic.nim

import raylib, ../raytext, std/unicode

proc main =
  let 屏幕W = int32(960)
  let 屏幕H = int32(600)

  initWindow(屏幕W, 屏幕H, "RayText — 动态字体按需加载")
  defer: closeWindow()

  var 字体 = 初始化动态字体(
    "/usr/share/fonts/TTF/MapleMono-NF-CN-Regular.ttf", 32)

  # 批量预加载码点范围（所有演示符号的完整 Unicode 区块）
  预加载码点范围(字体, {r数学运算符, r箭头, r图形符号})
  # 预加载界面文本中的中文字符
  预加载文本(字体, [
    "RayText 动态字体 — 输入汉字观察按需加载",
    "已加载  个字符  |  字号: ",
    "操作:  +/- = 缩放  |  Backspace = 退格",
    "拉丁字母:  The quick brown fox jumps over the lazy dog",
    "中文汉字:  天地玄黄 宇宙洪荒 日月盈昃 辰宿列张",
    "NF 图标:          ",
  ])

  var 演示字号: float32 = 22
  var 输入文本 = "你好世界 → 输入试试"

  setTargetFPS(60)

  while not windowShouldClose():
    if isKeyPressed(Equal) or isKeyPressed(KpAdd):
      演示字号 = min(演示字号 + 2, 64)
    if isKeyPressed(Minus) or isKeyPressed(KpSubtract):
      演示字号 = max(演示字号 - 2, 8)

    var 键 = getCharPressed()
    while 键 > 0:
      if 键 >= 0x20 and 键 <= 0x10FFFF:
        输入文本.add $Rune(键)
      键 = getCharPressed()

    var 键码 = getKeyPressed()
    while 键码 != Null: 键码 = getKeyPressed()

    if isKeyPressed(Backspace) and 输入文本.len > 0:
      删除末字符(输入文本)

    beginDrawing()
    clearBackground(Color(r: 248, g: 248, b: 248, a: 255))

    绘制文本(字体, "RayText 动态字体 — 输入汉字观察按需加载",
              Vector2(x: 20, y: 10), 20, 2, Color(r: 60, g: 60, b: 60, a: 255))

    drawRectangle(int32 20, int32 50, 屏幕W - int32 40, int32 60,
                  fade(White, 0.8))
    drawRectangleLines(int32 20, int32 50, 屏幕W - int32 40, int32 60,
                       fade(DarkGray, 0.3))
    绘制文本(字体, 输入文本, Vector2(x: 30, y: 65), 演示字号, 2, DarkBlue)

    let 统计 = "已加载 " & $已加载数(字体) & " 个字符  |  字号: " & $int32(演示字号)
    绘制文本(字体, 统计, Vector2(x: 30, y: 130), 16, 2,
              Color(r: 100, g: 100, b: 100, a: 255))

    drawText("操作:  +/- = 缩放  |  Backspace = 退格",
             int32 30, int32 180, int32 14, fade(DarkGray, 0.6))

    const 分类 = [
      "拉丁字母:  The quick brown fox jumps over the lazy dog",
      "中文汉字:  天地玄黄 宇宙洪荒 日月盈昃 辰宿列张",
      "数学符号:  ∑ ∫ √ ∞ ≈ ≠ ≤ ≥ ∈ ∝",
      "箭头符号:  → ← ↑ ↓ ⇒ ⇐ ⇑ ⇓ ➜",
      "几何图形:  ■ □ ▲ △ ● ○ ★ ☆ ♥ ♠",
      "NF 图标:          ",
    ]
    var y = 220.0
    for 行 in 分类:
      绘制文本(字体, 行, Vector2(x: 30, y: y), 18, 2, DarkBlue)
      y += 28

    drawFPS(屏幕W - 80, 10)
    endDrawing()

main()
