## vmath ↔ raylib 类型转换示例
##
## 演示 mymath/vmath_raylib 模块的各种转换功能：
##   - Vec2/3/4 ↔ Vector2/3/4  零拷贝互转
##   - Quat ↔ Quaternion        零拷贝互转
##   - Mat4 ↔ Matrix            行优先↔列优先转置
##   - Color ↔ uint32/Vec4      便捷转换
##   - Rectangle ↔ Vec4         便捷转换
##   - DVec2/3/4 ↔ Vector2/3/4  双精度↔单精度
##
## 构建: cd 项目根 && nim c -r -p:modules/raytext src/mymath/examples/conversions.nim

import raylib
import raytext
import mymath/vmath_raylib
import tool/dpi
import std/math

# ══════════════════════════════════════════════════════════════
# 辅助函数（中文版，使用 raytext 渲染）
# ══════════════════════════════════════════════════════════════

var 屏幕W*, 屏幕H*: int32  # 在 main 中由 DPI 模块赋值

proc 绘制标题*(字体: Font, 文本: string, x, y, 字号: float32) =
  ## 用 raytext 绘制中文小节标题
  绘制文本(字体, 文本, Vector2(x: x, y: y), 字号, 2,
            Color(r: 220, g: 220, b: 255, a: 255))

proc 绘制信息*(字体: Font, 文本: string, x, y, 字号: float32) =
  ## 用 raytext 绘制灰色信息文本
  绘制文本(字体, 文本, Vector2(x: x, y: y), 字号, 1,
            Color(r: 180, g: 180, b: 200, a: 255))

proc 绘制数值*(字体: Font, 文本: string, x, y, 字号: float32) =
  ## 用 raytext 绘制高亮数值文本
  绘制文本(字体, 文本, Vector2(x: x, y: y), 字号, 1,
            Color(r: 255, g: 220, b: 100, a: 255))

# ══════════════════════════════════════════════════════════════
# 演示区块（控制台验证）
# ══════════════════════════════════════════════════════════════

proc 演示向量转换 =
  ## Vec2/3/4 ↔ Vector2/3/4 零拷贝转换演示

  let vm2 = vec2(3.0, 4.0)
  let rv2: Vector2 = vm2.toRaylib()
  let back2: Vec2 = rv2.toVmath()
  assert vm2 == back2

  let vm3 = vec3(1.0, 2.0, 3.0)
  let rv3: Vector3 = vm3.toRaylib()
  let back3: Vec3 = rv3.toVmath()
  assert vm3 == back3

  let vm4 = vec4(0.5, 0.6, 0.7, 1.0)
  let rv4: Vector4 = vm4.toRaylib()
  let back4: Vec4 = rv4.toVmath()
  assert vm4 == back4

  echo "[向量] 零拷贝转换验证通过: Vec2/3/4 ↔ Vector2/3/4"

proc 演示四元数转换 =
  ## Quat ↔ Quaternion 零拷贝转换演示

  let qv = quat(0.0, 0.0, 0.0, 1.0)
  let rq: Quaternion = qv.toRaylibQuat()
  let backQ: Quat = rq.toVmath()
  assert qv == backQ

  echo "[四元数] 零拷贝转换验证通过: Quat ↔ Quaternion"

proc 演示矩阵转置 =
  ## Mat4 ↔ Matrix 行优先↔列优先转置验证

  let 原始 = mat4(
    1, 2, 3, 4,
    5, 6, 7, 8,
    9, 10, 11, 12,
    13, 14, 15, 16
  )

  let 转成raylib = 原始.toRaylib()
  let 转回来 = 转成raylib.toVmath()
  assert 原始 == 转回来, "Mat4 转置往返失败"

  let 单位 = mat4()
  let 单位Ray = 单位.toRaylib()
  assert 单位Ray.m0 == 1 and 单位Ray.m5 == 1 and 单位Ray.m10 == 1 and 单位Ray.m15 == 1

  echo "[矩阵] 转置验证通过: Mat4 ↔ Matrix (行优先↔列优先)"

proc 演示颜色转换 =
  ## Color ↔ uint32/Vec4 转换演示

  let c1 = toColor(0xFF804020'u32)
  assert c1.r == 0xFF and c1.g == 0x80 and c1.b == 0x40 and c1.a == 0x20

  let c2 = Color(r: 255, g: 128, b: 64, a: 32)
  assert c2.toUint32() == 0xFF804020'u32

  let cv = c2.toVec4()
  let cBack = cv.toColor()
  assert c2 == cBack

  echo "[颜色] 转换验证通过: Color ↔ uint32/Vec4"

proc 演示矩形转换 =
  ## Rectangle ↔ Vec4 转换演示

  let r1 = toRect(10.0, 20.0, 100.0, 50.0)
  assert r1.x == 10 and r1.y == 20 and r1.width == 100 and r1.height == 50

  let v = r1.toVec4()
  assert v.x == 10 and v.y == 20 and v.z == 100 and v.w == 50

  let r2 = v.toRect()
  assert r1 == r2

  echo "[矩形] 转换验证通过: Rectangle ↔ Vec4"

proc 演示双精度转换 =
  ## DVec2/3/4 ↔ Vector2/3/4 精度转换演示

  let dv = dvec3(1.5, 2.5, 3.5)
  let rv = dv.toRaylib()
  assert abs(rv.x - 1.5) < 0.0001
  assert abs(rv.y - 2.5) < 0.0001
  assert abs(rv.z - 3.5) < 0.0001

  let backD = rv.toVmathD()
  assert abs(backD.x - 1.5) < 0.0001
  assert abs(backD.y - 2.5) < 0.0001
  assert abs(backD.z - 3.5) < 0.0001

  echo "[双精度] 转换验证通过: DVec2/3/4 ↔ Vector2/3/4"

# ══════════════════════════════════════════════════════════════
# 主程序 — 图形化演示
# ══════════════════════════════════════════════════════════════

proc main =
  演示向量转换()
  演示四元数转换()
  演示矩阵转置()
  演示颜色转换()
  演示矩形转换()
  演示双精度转换()
  echo "═══════════════════════════════════════"
  echo "所有转换验证通过，启动图形演示..."

  # ── 自动适配显示器尺寸（跨平台） ──
  let 窗口 = 初始化窗口("vmath_raylib — 类型转换演示",
                        基准宽 = 1080, 基准高 = 720)
  屏幕W = 窗口.屏幕宽
  屏幕H = 窗口.屏幕高

  # 字号与间距按缩放比缩放
  let 缩放比 = 窗口.缩放比
  let 字号标题 = int32(18 * 缩放比)
  let 字号正文 = int32(14 * 缩放比)
  let 行距标题 = 28 * 缩放比
  let 行距正文 = 18 * 缩放比
  let 行距数值 = 22 * 缩放比
  defer: closeWindow()
  setTargetFPS(60)

  # ── 加载中文字体（raytext） ──
  let 字体 = 加载全字体(
    "/usr/share/fonts/TTF/MapleMono-NF-CN-Regular.ttf", 32)

  # ── 旋转立方体参数（使用 vmath 类型） ──
  var 旋转角: float32 = 0

  let 演示向量 = vec3(1.0, 2.0, 3.0)

  while not windowShouldClose():
    旋转角 += 0.02

    # ── 用 vmath 计算旋转矩阵 ──
    let 旋转 = mat4() * rotate(旋转角, vec3(0.0'f32, 1.0'f32, 0.0'f32)) *
                          rotate(旋转角 * 0.3'f32, vec3(1.0'f32, 0.0'f32, 0.0'f32))

    let raylib矩阵 = 旋转.toRaylib()

    # ── 演示用颜色/矩形 ──
    let 演示色 = toColor(0x4488CCFF'u32)
    let 演示色2 = toColor(0xCC8844FF'u32)
    let 演示矩形 = toRect(20.0, 20.0, 160.0, 60.0)

    beginDrawing()
    clearBackground(Color(r: 30, g: 30, b: 40, a: 255))

    let S = 缩放比  # 简写，所有坐标/字号乘以 S

    # ══════════════════════════════════════════
    # 左栏：转换说明（使用 raytext 渲染中文）
    # ══════════════════════════════════════════

    绘制标题(字体, "类型转换演示", 20*S, 20*S, 字号标题.float32)
    drawRectangleLines(int32(20*S), int32(20*S),
                       int32(360*S), int32(760*S),
                       Color(r: 80, g: 80, b: 100, a: 255))

    var y = 60*S

    绘制标题(字体, "■ Vec2/3/4 ↔ Vector2/3/4  零拷贝", 30*S, y, 字号标题.float32)
    y += 行距标题
    绘制信息(字体, "vmath.Vec3(1, 2, 3)  →  raylib.Vector3", 35*S, y, 字号正文.float32)
    y += 行距正文
    绘制数值(字体, $演示向量, 35*S, y, 字号正文.float32)
    y += 行距数值
    let 转Vector3: Vector3 = 演示向量.toRaylib()
    绘制数值(字体, "(" & $转Vector3.x & ", " & $转Vector3.y &
             ", " & $转Vector3.z & ")", 35*S, y, 字号正文.float32)
    y += 行距标题

    绘制标题(字体, "■ Quat ↔ Quaternion  零拷贝", 30*S, y, 字号标题.float32)
    y += 行距标题
    绘制信息(字体, "vmath.Quat(0, 0, 0, 1)  ↔  raylib.Quaternion", 35*S, y, 字号正文.float32)
    y += 行距数值
    绘制数值(字体, "单位四元数，内存布局完全一致", 35*S, y, 字号正文.float32)
    y += 行距标题

    绘制标题(字体, "■ Mat4 ↔ Matrix  行优先↔列优先", 30*S, y, 字号标题.float32)
    y += 行距标题
    绘制信息(字体, "vmath 行优先  →  raylib 列优先（转置）", 35*S, y, 字号正文.float32)
    y += 行距正文
    绘制信息(字体, "← 回转换回行优先，值完全不变", 35*S, y, 字号正文.float32)
    y += 行距数值
    绘制数值(字体, "当前旋转矩阵 (m0..m3):", 35*S, y, 字号正文.float32)
    y += 行距正文
    绘制数值(字体, $raylib矩阵.m0 & " " & $raylib矩阵.m1 & " " &
             $raylib矩阵.m2 & " " & $raylib矩阵.m3, 35*S, y, 字号正文.float32)
    y += 行距标题

    绘制标题(字体, "■ Color ↔ uint32/Vec4", 30*S, y, 字号标题.float32)
    y += 行距标题
    绘制信息(字体, "0x4488CCFF  →  Color(R:68 G:136 B:204 A:255)", 35*S, y, 字号正文.float32)
    y += 行距正文
    let 色vec = 演示色.toVec4()
    绘制信息(字体, "→ Vec4(" & $色vec.x & ", " & $色vec.y &
             ", " & $色vec.z & ", " & $色vec.w & ")", 35*S, y, 字号正文.float32)
    y += 行距数值
    drawRectangle(int32(35*S), int32(y), int32(60*S), int32(20*S), 演示色)
    y += 行距标题

    绘制标题(字体, "■ Rectangle ↔ Vec4", 30*S, y, 字号标题.float32)
    y += 行距标题
    绘制信息(字体, "toRect(20, 20, 160, 60) → Vec4", 35*S, y, 字号正文.float32)
    y += 行距正文
    绘制数值(字体, "(" & $演示矩形.x & ", " & $演示矩形.y &
             ", " & $演示矩形.width & ", " & $演示矩形.height & ")", 35*S, y, 字号正文.float32)
    y += 行距标题

    绘制标题(字体, "■ DVec3 → Vector3  双精度转换", 30*S, y, 字号标题.float32)
    y += 行距标题
    let d演示 = dvec3(PI.float64, E.float64, 1.41421356)
    let 转单 = d演示.toRaylib()
    绘制信息(字体, "DVec3( pi , e, √2)", 35*S, y, 字号正文.float32)
    y += 行距正文
    绘制信息(字体, "→ Vector3(" & $转单.x & ", " & $转单.y &
             ", " & $转单.z & ")", 35*S, y, 字号正文.float32)
    y += 行距标题

    # ══════════════════════════════════════════
    # 右栏：3D 可视化
    # ══════════════════════════════════════════

    beginMode3D(Camera3D(
      position: Vector3(x: 10, y: 6, z: 10),
      target:   Vector3(x: 0, y: 0, z: 0),
      up:       Vector3(x: 0, y: 1, z: 0),
      fovy:     45,
      projection: Perspective
    ))

    drawGrid(10, 1.0)

    # 用 vmath 计算变换矩阵 → 手动变换顶点 → toRaylib 绘制
    # 演示 Mat4*Vec3 变换 + Vec3→Vector3 零拷贝转换
    const 立方体顶点: array[8, Vec3] = [
      vec3(-1,-1,-1), vec3( 1,-1,-1), vec3( 1, 1,-1), vec3(-1, 1,-1),
      vec3(-1,-1, 1), vec3( 1,-1, 1), vec3( 1, 1, 1), vec3(-1, 1, 1),
    ]
    var 变换后顶点: array[8, Vector3]
    for i, v in 立方体顶点:
      变换后顶点[i] = (旋转 * v).toRaylib()  # Mat4 * Vec3 → Vector3（零拷贝）

    const 棱: array[12, tuple[a,b: int]] = [
      (0,1),(1,2),(2,3),(3,0),  # 前面
      (4,5),(5,6),(6,7),(7,4),  # 后面
      (0,4),(1,5),(2,6),(3,7),  # 连接前后
    ]
    for (i, j) in 棱:
      drawLine3D(变换后顶点[i], 变换后顶点[j], 演示色)
    for v in 变换后顶点:
      drawSphere(v, 0.06, 演示色2)

    # 坐标轴（vmath 变换后转 raylib 绘制）
    let 原点 = vec3(0,0,0).toRaylib()
    drawLine3D(原点, (旋转 * vec3(3,0,0)).toRaylib(), Red)
    drawLine3D(原点, (旋转 * vec3(0,3,0)).toRaylib(), Green)
    drawLine3D(原点, (旋转 * vec3(0,0,3)).toRaylib(), Blue)

    endMode3D()

    # ── 右下角状态信息 ──
    绘制信息(字体, "旋转角: " & $(旋转角 * 180 / PI).int32 & "°",
              屏幕W.float32 - 160*S, 屏幕H.float32 - 80*S, 字号正文.float32)
    绘制信息(字体, "FPS: " & $getFPS(),
              屏幕W.float32 - 160*S, 屏幕H.float32 - 60*S, 字号正文.float32)

    endDrawing()

when isMainModule:
  main()
