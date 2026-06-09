## RayText — Nim 中文文本渲染模块
##
## 基于 raylib，支持 CJK / Unicode 字符，提供静态预加载和动态按需加载两种模式。
##
## 快速开始
## ==========
##
##   import raytext
##
##   # 方式一：静态预加载（启动时一次性加载全部字形）
##   let 字体 = 加载全字体("font.ttf", 48)
##   绘制文本(字体, "你好世界", vec2(100,100), 32, 2, Black)
##   绘制文本换行(字体, "长文本", rect(10,10,300,200), 20, 2, Black)
##
##   # 方式二：动态按需加载（启动快，缺字自动补）
##   var df = 初始化动态字体("font.ttf", 32)
##   绘制文本(df, "你好世界", vec2(100,100), 32, 2, Black)

import raylib
import std/unicode, std/intsets
from std/sugar import collect

# ═══════════════════════════════════════════════════
# 类型定义
# ═══════════════════════════════════════════════════

type
  中文字体* = Font

  码点范围* {.size: sizeof(int8).} = enum
    # ── 基础拉丁 ──
    r基本拉丁     ## 0x0020–0x007E  ASCII 可打印字符
    r拉丁补充     ## 0x00A0–0x00FF  · × ÷
    # ── 通用符号 ──
    r常用标点     ## 0x2000–0x206F  — … ‐ –
    r箭头         ## 0x2190–0x21FF  → ← ↑ ↓ ⇒
    r数学运算符   ## 0x2200–0x22FF  ≈ ≠ ≤ ≥ ∈ √ ∞ ±
    r图形符号     ## 0x25A0–0x27BF  ■□▲△●○★☆♥♠➜ (几何+杂项+丁巴特)
    # ── 汉字辅助 (部首/结构/标点/日文/注音) ──
    r汉字辅助     ## 0x2E80–0x312F  部首+结构+CJK标点+日文假名+注音
    r注音笔画     ## 0x31A0–0x31EF  注音拓展+汉字笔画
    # ── CJK 核心 ──
    rCJK扩展A     ## 0x3400–0x4DBF  㐀–䶿
    r基本汉字     ## 0x4E00–0x9FFF  一–鿿 (20,992 字)
    # ── CJK 兼容与变体 ──
    r兼容汉字     ## 0xF900–0xFAFF  豈–﫿
    r汉字变体     ## 0xFE10–0xFE6F  垂直形式+兼容形式+小型变体
    r全角半角      ## 0xFF00–0xFFEF  全角字母数字、括号
    r象形符号标点 ## 0x16FE0–0x16FFF  𖿠–𖿿
    # ── CJK 扩展 (超大区块) ──
    r扩展BtoF     ## 0x20000–0x2EBE0  扩展 B~F (约 60K 字)
    r兼容汉字扩展 ## 0x2F800–0x2FA1F  (544 字)
    r扩展GtoH     ## 0x30000–0x323AF  扩展 G+H (约 9K 字)
    # ── Nerd Font 图标 (私用区 PUA) ──
    rNerd字体     ## 0xE000–0xF8FF  全部 NF 图标 (Powerline/Devicons/FA/Material)

  动态字体* = object
    ## 按需加载字形的字体。
    ## 初始化只加载基本拉丁 + 常用标点（≈50ms），
    ## 遇到未加载字符时自动追加，已加载字符不重复光栅化。
    字体: Font
    已加载: IntSet            # 使用位图存储，内存远小于 HashSet
    路径: string
    字号: int32

# ═══════════════════════════════════════════════════
# 码点范围数据
# ═══════════════════════════════════════════════════

const
  范围表: array[码点范围, tuple[起始, 结束: int32]] = [
    r基本拉丁:      (int32 0x0020,   int32 0x007E),
    r拉丁补充:      (int32 0x00A0,   int32 0x00FF),
    r常用标点:      (int32 0x2000,   int32 0x206F),
    r箭头:          (int32 0x2190,   int32 0x21FF),
    r数学运算符:    (int32 0x2200,   int32 0x22FF),
    r图形符号:      (int32 0x25A0,   int32 0x27BF),
    r汉字辅助:      (int32 0x2E80,   int32 0x312F),
    r注音笔画:      (int32 0x31A0,   int32 0x31EF),
    rCJK扩展A:      (int32 0x3400,   int32 0x4DBF),
    r基本汉字:      (int32 0x4E00,   int32 0x9FFF),
    r兼容汉字:      (int32 0xF900,   int32 0xFAFF),
    r汉字变体:      (int32 0xFE10,   int32 0xFE6F),
    r全角半角:       (int32 0xFF00,   int32 0xFFEF),
    r象形符号标点:  (int32 0x16FE0,  int32 0x16FFF),
    r扩展BtoF:      (int32 0x20000,  int32 0x2EBE0),
    r兼容汉字扩展:  (int32 0x2F800,  int32 0x2FA1F),
    r扩展GtoH:      (int32 0x30000,  int32 0x323AF),
    rNerd字体:      (int32 0xE000,   int32 0xF8FF),
  ]

# ═══════════════════════════════════════════════════
# 预定义子集
# ═══════════════════════════════════════════════════

const
  拉丁符号集* = {
    r基本拉丁, r拉丁补充, r常用标点, r箭头,
    r数学运算符, r图形符号,
  }
  ## 拉丁字母 + 通用符号

  汉字核心* = {
    r基本汉字, rCJK扩展A, r汉字辅助, r注音笔画,
    r全角半角, r兼容汉字, r汉字变体, r象形符号标点,
  }
  ## 汉字核心区块（不含日文和超大扩展）

  汉字扩展* = {r扩展BtoF, r兼容汉字扩展, r扩展GtoH}
  ## CJK 扩展（超大，按需启用）

  NF字体集* = {rNerd字体}
  ## Nerd Font 图标（需要 NF 变体字体）

  常用子集* = 拉丁符号集 + 汉字核心
  ## ≈29K 码点，适合绝大多数场景

  汉字全集* = 汉字核心 + 汉字扩展
  ## ≈94K 码点

  完整子集* = 常用子集 + 汉字扩展 + NF字体集
  ## ≈127K 码点（所有已定义范围）

# ═══════════════════════════════════════════════════
# 码点工具
# ═══════════════════════════════════════════════════

proc 生成码点列表*(子集: set[码点范围]): seq[int32] {.inline.} =
  ## 将一组码点范围展开为扁平 seq[int32]
  for r in 子集:
    let (起始, 结束) = 范围表[r]
    for i in 起始..结束:
      result.add i

proc 删除末字符*(s: var string) =
  ## 删除字符串末尾的一个完整 UTF-8 字符
  if s.len == 0: return
  var i = s.len - 1
  while i > 0 and (s[i].uint8 and 0xC0) == 0x80:
    dec i
  s.setLen(i)

# ═══════════════════════════════════════════════════
# 字体加载 — 静态（预加载全部码点）
# ═══════════════════════════════════════════════════

proc 加载字体*(路径: string, 字号: int32 = 48,
               子集: set[码点范围] = 常用子集,
               额外码点: seq[int32] = @[]): Font =
  ## 加载 TrueType 字体，按子集控制加载哪些码点
  let 码点列表 = 生成码点列表(子集) & 额外码点
  result = loadFont(路径, 字号, 码点列表)

proc 加载字体从内存*(文件类型: string, 数据: openArray[uint8],
                     字号: int32 = 48,
                     子集: set[码点范围] = 常用子集,
                     额外码点: seq[int32] = @[]): Font =
  let 码点列表 = 生成码点列表(子集) & 额外码点
  result = loadFontFromMemory(文件类型, 数据, 字号, 码点列表)

proc 加载全字体*(路径: string, 字号: int32 = 48): Font =
  ## 加载字体并预生成所有支持的 Unicode 字形
  result = 加载字体(路径, 字号, 子集 = 完整子集)

proc 加载全字体从内存*(文件类型: string, 数据: openArray[uint8],
                       字号: int32 = 48): Font =
  result = 加载字体从内存(文件类型, 数据, 子集 = 完整子集)

# ═══════════════════════════════════════════════════
# 字体加载 — 动态（按需加载）
# ═══════════════════════════════════════════════════

proc 已加载数*(df: 动态字体): int {.inline.} = df.已加载.len

proc 初始化动态字体*(路径: string, 字号: int32 = 32): 动态字体 =
  ## 创建动态字体，初始只加载基本拉丁 + 常用标点（≈50ms）
  result.路径 = 路径
  result.字号 = 字号
  result.已加载 = initIntSet()
  let 初始码点 = 生成码点列表({r基本拉丁, r常用标点})
  for c in 初始码点:
    result.已加载.incl c
  result.字体 = loadFont(路径, 字号, 初始码点)

proc 预加载码点范围*(df: var 动态字体, 子集: set[码点范围]) =
  ## 预先加载指定码点范围，合并到当前字体
  let 新码点 = 生成码点列表(子集)
  for c in 新码点:
    df.已加载.incl c
  # 修复：显式转换为 int32
  var 全部: seq[int32]
  for cp in df.已加载:
    全部.add int32(cp)
  df.字体 = loadFont(df.路径, df.字号, 全部)

proc 预加载文本*(df: var 动态字体, 文本集: openArray[string]) =
  ## 批量预加载多段文本的所有字符（仅触发一次字体重建）
  for 文本 in 文本集:
    for r in 文本.toRunes:
      if r.int32 > 0x0020:
        df.已加载.incl r.int32
  var 全部: seq[int32]
  for cp in df.已加载:
    全部.add int32(cp)
  df.字体 = loadFont(df.路径, df.字号, 全部)

proc 确保已加载*(df: var 动态字体, 文本: string) =
  ## 确保文本中所有字符已加载，缺失字符自动追加
  var 有缺失 = false
  for r in 文本.toRunes:
    let cp = r.int32
    if cp notin df.已加载 and cp > 0x0020:
      df.已加载.incl cp
      有缺失 = true
  if 有缺失:
    var 全部: seq[int32]
    for cp in df.已加载:
      全部.add int32(cp)
    df.字体 = loadFont(df.路径, df.字号, 全部)

# ═══════════════════════════════════════════════════
# 文本绘制
# ═══════════════════════════════════════════════════

proc 绘制文本*(字体: Font, 文本: string, 位置: Vector2,
               字号: float32 = 32, 间距: float32 = 2,
               颜色: Color = Black) =
  ## 使用静态字体绘制文本
  drawText(字体, 文本, 位置, 字号, 间距, 颜色)

proc 绘制文本*(df: var 动态字体, 文本: string, 位置: Vector2,
               字号: float32 = 32, 间距: float32 = 2,
               颜色: Color = Black) =
  ## 使用动态字体绘制文本（缺失字符自动按需加载）
  确保已加载(df, 文本)
  drawText(df.字体, 文本, 位置, 字号, 间距, 颜色)

proc 测量文本*(字体: Font, 文本: string,
               字号: float32 = 32, 间距: float32 = 2): Vector2 =
  result = measureText(字体, 文本, 字号, 间距)

proc 测量文本*(df: 动态字体, 文本: string,
               字号: float32 = 32, 间距: float32 = 2): Vector2 =
  result = measureText(df.字体, 文本, 字号, 间距)

proc 绘制文本换行*(字体: Font, 文本: string, 区域: Rectangle,
                   字号: float32 = 32, 间距: float32 = 2,
                   行距: float32 = 0, 颜色: Color = Black) =
  ## 在指定矩形区域内绘制文本，超出宽度自动换行
  let 行高 = 行距 + 字号
  let 字符 = 文本.toRunes
  var 行起始 = 0
  var y = 区域.y

  proc 拼段(起始, 结束: int): string =
    for i in 起始 ..< 结束: result.add $字符[i]

  while 行起始 < 字符.len and y + 行高 <= 区域.y + 区域.height:
    var 换行点 = 字符.len
    var i = 行起始

    while i < 字符.len:
      if 字符[i] == Rune('\n'):
        换行点 = i
        break
      if 测量文本(字体, 拼段(行起始, i + 1), 字号, 间距).x > 区域.width:
        换行点 = i
        break
      inc i

    if 换行点 == 行起始:
      换行点 = 行起始 + 1

    let 行文本 = 拼段(行起始, 换行点)
    if 行文本.len > 0:
      绘制文本(字体, 行文本, Vector2(x: 区域.x, y: y), 字号, 间距, 颜色)
    y += 行高
    行起始 = 换行点

    if 行起始 < 字符.len and 字符[行起始] == Rune('\n'):
      inc 行起始

proc 绘制文本换行*(df: var 动态字体, 文本: string, 区域: Rectangle,
                   字号: float32 = 32, 间距: float32 = 2,
                   行距: float32 = 0, 颜色: Color = Black) =
  ## 使用动态字体绘制自动换行文本
  确保已加载(df, 文本)
  绘制文本换行(df.字体, 文本, 区域, 字号, 间距, 行距, 颜色)

# ── 简易版（使用默认字体，仅 ASCII）──────────────

proc 绘制文本*(文本: string, x, y: int32, 字号: int32, 颜色: Color) =
  ## 使用 raylib 默认字体绘制文本（不支持中文）
  drawText(文本, x, y, 字号, 颜色)
