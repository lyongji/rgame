## 完整 3D 摄像机模块
##
## 基于 raylib rcamera.h，数学运算全部使用 vmath
## 依赖 mymath/vmath_raylib 提供的 Vec3↔Vector3 隐式转换器
##
## 支持的摄像机模式:
##   用户自定义 - 完全手动控制
##   自由模式   - 六自由度，无俯仰限制
##   第一人称   - 锁定水平面，限制俯仰 ±90°
##   第三人称   - 俯仰 + 偏航，绕目标旋转
##   轨道模式   - 绕目标自动旋转
##
## 用法:
##   import camera/camera
##   var 摄像机 = 新建摄像机(位置=vec3(0,2,0), 目标=vec3(0,0,0), 视野=45)
##   while not windowShouldClose():
##     摄像机.自由模式更新()
##     beginMode3D(摄像机.转Raylib())
##       ...
##     endMode3D()

import vmath
import raylib
import rcamera
import mymath/vmath_raylib

export vmath

# ============================================================================
# 类型定义
# ============================================================================

type
  摄像机模式* = enum
    用户自定义   ## 用户完全控制
    自由模式      ## 自由模式
    轨道模式      ## 轨道模式，绕 target 旋转
    第一人称      ## 第一人称
    第三人称      ## 第三人称

  摄像机* = object
    ## 纯 vmath 摄像机，转换到 raylib 时才转为 Camera3D
    位置*:    Vec3
    目标*:    Vec3
    上向量*:  Vec3
    视野*:    float32      ## 角度制
    投影*:    CameraProjection

# ============================================================================
# 构造函数
# ============================================================================

func 新建摄像机*(
  位置: Vec3 = vec3(0, 2, 0),
  目标: Vec3 = vec3(0, 0, 0),
  上向量: Vec3 = vec3(0, 1, 0),
  视野: float32 = 45,
  投影: CameraProjection = Perspective
): 摄像机 {.inline.} =
  ## 创建一个 3D 摄像机
  摄像机(
    位置: 位置,
    目标: 目标,
    上向量: 上向量,
    视野: 视野,
    投影: 投影
  )

# ============================================================================
# 与 raylib Camera3D 互转
# ============================================================================

func 转Raylib*(c: 摄像机): Camera3D {.inline.} =
  ## 摄像机 → raylib Camera3D
  Camera3D(
    position: c.位置,
    target:   c.目标,
    up:       c.上向量,
    fovy:     c.视野,
    projection: c.投影
  )

func 转Vmath*(c: Camera3D): 摄像机 {.inline.} =
  ## raylib Camera3D → 摄像机
  摄像机(
    位置: c.position.toVmath(),
    目标: c.target.toVmath(),
    上向量: c.up.toVmath(),
    视野: c.fovy,
    投影: c.projection
  )

# ============================================================================
# 方向向量查询
# ============================================================================

func 前方*(c: 摄像机): Vec3 {.inline.} =
  ## 摄像机前方向（归一化）
  let cam = c.转Raylib()
  getCameraForward(cam).toVmath()

func 上方*(c: 摄像机): Vec3 {.inline.} =
  ## 摄像机上方方向（归一化）
  let cam = c.转Raylib()
  getCameraUp(cam).toVmath()

func 右方*(c: 摄像机): Vec3 {.inline.} =
  ## 摄像机右方向（归一化）
  let cam = c.转Raylib()
  getCameraRight(cam).toVmath()

# ============================================================================
# 视图 / 投影矩阵
# ============================================================================

func 视图矩阵*(c: 摄像机): Mat4 {.inline.} =
  ## 视图矩阵（观察矩阵）
  let cam = c.转Raylib()
  getCameraViewMatrix(cam).toVmath()

func 投影矩阵*(c: 摄像机; 宽高比: float32): Mat4 {.inline.} =
  ## 投影矩阵
  let cam = c.转Raylib()
  getCameraProjectionMatrix(cam, 宽高比).toVmath()

# ============================================================================
# 摄像机移动
# ============================================================================

proc 前进*(c: var 摄像机; 距离: float32; 是否水平移动: bool) {.inline.} =
  ## 沿前方向移动
  var cam = c.转Raylib()
  moveForward(cam, 距离, 是否水平移动)
  c = cam.转Vmath()

proc 向右移动*(c: var 摄像机; 距离: float32; 是否水平移动: bool) {.inline.} =
  ## 沿右方向移动
  var cam = c.转Raylib()
  moveRight(cam, 距离, 是否水平移动)
  c = cam.转Vmath()

proc 向上移动*(c: var 摄像机; 距离: float32) {.inline.} =
  ## 沿上方向移动
  var cam = c.转Raylib()
  moveUp(cam, 距离)
  c = cam.转Vmath()

proc 移向目标*(c: var 摄像机; 偏移: float32) {.inline.} =
  ## 推近/拉远到目标
  var cam = c.转Raylib()
  moveToTarget(cam, 偏移)
  c = cam.转Vmath()

# ============================================================================
# 摄像机旋转
# ============================================================================

proc 偏航*(c: var 摄像机; 角度: float32; 是否绕目标旋转: bool) {.inline.} =
  ## 偏航（左右看）。角度单位：弧度
  var cam = c.转Raylib()
  yaw(cam, 角度, 是否绕目标旋转)
  c = cam.转Vmath()

proc 俯仰*(c: var 摄像机; 角度: float32; 是否锁定视角: bool;
            是否绕目标旋转: bool; 是否旋转上向量: bool) {.inline.} =
  ## 俯仰（上下看）。角度单位：弧度
  var cam = c.转Raylib()
  pitch(cam, 角度, 是否锁定视角, 是否绕目标旋转, 是否旋转上向量)
  c = cam.转Vmath()

proc 滚转*(c: var 摄像机; 角度: float32) {.inline.} =
  ## 滚动。角度单位：弧度
  var cam = c.转Raylib()
  roll(cam, 角度)
  c = cam.转Vmath()

# ============================================================================
# 高级便捷操作（vmath 原生实现，不经由 raylib C）
# ============================================================================

proc 轨道旋转*(c: var 摄像机; 角度: float32; 轴: Vec3 = vec3(0, 1, 0)) {.inline.} =
  ## 绕目标旋转摄像机位置（轨道模式）
  let 视线 = c.位置 - c.目标
  let 旋转后 = rotate(角度, 轴.normalize()) * 视线
  c.位置 = c.目标 + 旋转后

proc 缩放*(c: var 摄像机; 偏移: float32) {.inline.} =
  ## 缩放：将摄像机移近/远离目标
  c.移向目标(-偏移)

proc 平移*(c: var 摄像机; 偏移: Vec2; 是否水平移动: bool = true) {.inline.} =
  ## 平移（鼠标中键）
  c.向右移动(偏移.x, 是否水平移动)
  c.向上移动(-偏移.y)

proc 注视*(c: var 摄像机; 新目标: Vec3) {.inline.} =
  ## 设置注视点
  c.目标 = 新目标

proc 到目标距离*(c: 摄像机): float32 {.inline.} =
  ## 到目标的距离
  length(c.位置 - c.目标)

# ============================================================================
# 摄像机自动更新（各模式）
# ============================================================================

proc 更新*(c: var 摄像机; 模式: 摄像机模式) =
  ## 根据模式自动更新摄像机（键盘+鼠标）
  ## 等效于 raylib 的 UpdateCamera()
  let 帧时间 = getFrameTime()

  let 移动速度   = CameraMoveSpeed * 帧时间
  let 旋转速度   = CameraRotationSpeed * 帧时间
  let 轨道速度   = CameraOrbitalSpeed * 帧时间

  let 鼠标偏移 = getMouseDelta()
  let 是否水平移动 = 模式 in {第一人称, 第三人称}
  let 是否绕目标旋转 = 模式 in {第三人称, 轨道模式}
  let 是否锁定视角 = 模式 notin {用户自定义}

  case 模式
  of 用户自定义:
    discard

  of 轨道模式:
    c.轨道旋转(轨道速度)

  of 自由模式, 第一人称, 第三人称:
    # ---- 鼠标旋转 ----
    c.偏航(-鼠标偏移.x * CameraMouseMoveSensitivity, 是否绕目标旋转)
    c.俯仰(-鼠标偏移.y * CameraMouseMoveSensitivity,
            是否锁定视角, 是否绕目标旋转, 是否旋转上向量 = false)

    # ---- 键盘方向键 ----
    if isKeyDown(Down):       c.俯仰(-旋转速度, 是否锁定视角, 是否绕目标旋转, false)
    if isKeyDown(Up):         c.俯仰( 旋转速度, 是否锁定视角, 是否绕目标旋转, false)
    if isKeyDown(Right):      c.偏航(-旋转速度, 是否绕目标旋转)
    if isKeyDown(Left):       c.偏航( 旋转速度, 是否绕目标旋转)
    if isKeyDown(Q):          c.滚转(-旋转速度)
    if isKeyDown(E):          c.滚转( 旋转速度)

    # ---- 鼠标中键平移（仅自由模式） ----
    if 模式 == 自由模式 and isMouseButtonDown(Middle):
      let 鼠标位移 = getMouseDelta()
      if 鼠标位移.x > 0: c.向右移动( 移动速度, 是否水平移动)
      if 鼠标位移.x < 0: c.向右移动(-移动速度, 是否水平移动)
      if 鼠标位移.y > 0: c.向上移动(-移动速度)
      if 鼠标位移.y < 0: c.向上移动( 移动速度)

    # ---- WASD 移动 ----
    if isKeyDown(W): c.前进( 移动速度, 是否水平移动)
    if isKeyDown(S): c.前进(-移动速度, 是否水平移动)
    if isKeyDown(A): c.向右移动(-移动速度, 是否水平移动)
    if isKeyDown(D): c.向右移动( 移动速度, 是否水平移动)

    # ---- 手柄 ----
    if isGamepadAvailable(0):
      c.偏航(-(getGamepadAxisMovement(0, RightX) * 2) *
              CameraMouseMoveSensitivity, 是否绕目标旋转)
      c.俯仰(-(getGamepadAxisMovement(0, RightY) * 2) *
              CameraMouseMoveSensitivity, 是否锁定视角, 是否绕目标旋转, false)

      let 左Y = getGamepadAxisMovement(0, LeftY)
      let 左X = getGamepadAxisMovement(0, LeftX)
      if 左Y <= -0.25: c.前进( 移动速度, 是否水平移动)
      if 左Y >=  0.25: c.前进(-移动速度, 是否水平移动)
      if 左X <= -0.25: c.向右移动(-移动速度, 是否水平移动)
      if 左X >=  0.25: c.向右移动( 移动速度, 是否水平移动)

    # ---- 自由模式上下 ----
    if 模式 == 自由模式:
      if isKeyDown(Space):        c.向上移动( 移动速度)
      if isKeyDown(LeftControl):  c.向上移动(-移动速度)

    # ---- 滚轮缩放（第三人称 / 轨道 / 自由） ----
    if 模式 in {第三人称, 轨道模式, 自由模式}:
      c.缩放(getMouseWheelMove())
      if isKeyPressed(KpSubtract): c.缩放(-2.0)
      if isKeyPressed(KpAdd):      c.缩放( 2.0)

# ============================================================================
# 便捷更新函数
# ============================================================================

proc 自由模式更新*(c: var 摄像机) {.inline.} =
  c.更新(自由模式)

proc 第一人称更新*(c: var 摄像机) {.inline.} =
  c.更新(第一人称)

proc 第三人称更新*(c: var 摄像机) {.inline.} =
  c.更新(第三人称)

proc 轨道模式更新*(c: var 摄像机) {.inline.} =
  c.更新(轨道模式)

# ============================================================================
# 使用 raylib Camera3D 的桥接更新
# ============================================================================

proc 更新*(摄像机3D: var Camera3D; 模式: 摄像机模式) =
  ## 直接更新 raylib Camera3D（经由 vmath 摄像机中转）
  var 相机 = 摄像机3D.转Vmath()
  相机.更新(模式)
  摄像机3D = 相机.转Raylib()

# ============================================================================
# 验证
# ============================================================================

when isMainModule:
  block:
    let c = 新建摄像机()
    assert c.位置 == vec3(0, 2, 0)
    assert c.目标 == vec3(0, 0, 0)
    # 前方 = normalize(目标 - 位置) = normalize(0, -2, 0) = (0, -1, 0)
    assert c.前方() == vec3(0, -1, 0), "前方应为 (0, -1, 0)"
    echo "✅ 摄像机模块验证通过"
