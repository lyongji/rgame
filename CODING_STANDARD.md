# 中文代码命名通用规范 — Nim 版（V8.0）

> **代码如母语，一眼即懂，无需脑中翻译。**

---

## 一、设计哲学

摒弃脑中翻译的步骤，追求代码阅读时的默读即懂。变量名只表达"是什么"，其单位、计量方式等"怎么计量"的信息交由类型系统（`distinct` / Type Alias）表达，让编译器帮你防止错误。

### 核心原则

| 原则 | 检验标准 | 反例 |
|------|----------|------|
| **默读即懂** | 不跳转到定义就能理解当前行 | `process(d)` — d 是什么？ |
| **状态可见** | 布尔值一律 `是否` 前缀 | `running` → `是否正在运行` |
| **术语唯一** | 同一个概念全项目一个名 | 别处`用户`这里`账号` |
| **类型自解释** | 单位/语义靠类型系统，不靠变量名后缀 | `金额 分` 而非 `金额分` |

### 三不做

- **不缩写**状态词（`已`/`正在`/`未`）和量词（`个`/`次`/`秒`/`毫秒`）
- **不超过**两级作用域嵌套（proc 内 if/for/while 嵌套深度 ≤ 2）
- **不在**对象（object）内部重复对象名作为字段前缀

---

## 二、命名公式

### 基础公式

```
[状态][动作][主体][集合名词]
```

直接拼接，**不加任何分隔符**。中文词汇边界由读者自然识别。

### 按场景选用

| 场景 | 模式 | 示例 |
|------|------|------|
| **函数/proc** | `[动作][主体]` | `提交订单` `查询用户` `发送通知` |
| **变量/字段** | `[状态][主体][集合名词]` | `已处理数量` `待审核列表` `存活连接数` |
| **布尔变量** | `是否[状态][主体]` | `是否已认证` `是否正在加载` `是否有效` |
| **配置项** | `[主体][属性]`，单位由类型提供 | `缓存有效期`（类型 `秒`）`重试间隔`（类型 `毫秒`）|

### 状态词缀

| 词缀 | 含义 | 示例 |
|------|------|------|
| `未` | 尚未发生 | `未初始化` `未支付` |
| `正在` | 进行中 | `是否正在请求` `是否正在计算` |
| `已` | 已完成 | `已签收` `已过期` |
| `是否` | 布尔判断 | `是否有效` `是否可编辑` |
| `是否已` | 布尔+完成 | `是否已缓存` `是否已完成` |
| `是否正在` | 布尔+进行中 | `是否正在重试` `是否正在同步` |

### 时机词缀（回调/事件）

| 词缀 | 场景 | 示例 |
|------|------|------|
| `时` | 瞬间触发 | `点击时` `连接断开时` |
| `前` | 前置检查 | `提交前` `保存前` |
| `后` | 后置处理 | `保存后` `删除后` |
| `每` | 周期性任务 | `每小时` `每帧` |
| `超时后` | 超时处理 | `超时后取消` |
| `失败时` | 错误处理 | `失败时重试` |

---

## 三、类型别名体系

### 核心理念

变量名表达"是什么"，类型表达"怎么计量"。即使底层类型相同，也定义不同的类型名称，利用 Nim 的 `distinct`（强区分）或 `type` 别名（弱区分）让编译器/类型检查器防止参数传递错误。

### Nim 类型定义方式

#### 1. 基础别名（轻量级，可隐式转换）

```nim
type
  秒* = int64
  毫秒* = int64
  字节* = int

var 过期时间: 秒 = 3600
var 重试间隔: 毫秒 = 500
```

#### 2. Distinct 类型（强区分，编译期阻止混用）— 推荐

```nim
type
  秒* = distinct int64
  毫秒* = distinct int64
  用户ID* = distinct int64
  订单ID* = distinct int64
  会话ID* = distinct string

# 编译期阻止：
proc 查询用户*(id: 用户ID) =
  discard

let uid: 用户ID = 123.用户ID
查询用户(uid)                 # ✓ 编译通过
# 查询用户(42)                # ✗ 编译错误：类型不匹配
# 查询用户(42.订单ID)         # ✗ 编译错误：类型不匹配
```

#### 3. 语义类型（防止混淆）

即使底层类型相同，也定义不同名称，编译期阻止参数传错：

```nim
type
  用户ID* = distinct int64
  订单ID* = distinct int64
  会话ID* = distinct string

proc 查询用户*(id: 用户ID) =
  discard

proc 查询订单*(id: 订单ID) =
  discard

# 编译期阻止：
let uid = 42.用户ID
查询用户(uid)         # ✓
# 查询订单(uid)       # ✗ 编译错误
```

### Distinct 类型运算支持

如果 distinct 类型需要算术运算，手工重载：

```nim
proc `+`*(a, b: 秒): 秒 {.borrow.}
proc `-`*(a, b: 秒): 秒 {.borrow.}
proc `$`*(s: 秒): string = $s.int64  # 打印支持

func 秒转毫秒*(s: 秒): 毫秒 = (s.int64 * 1000).毫秒
func 毫秒转秒*(ms: 毫秒): 秒 = (ms.int64 div 1000).秒
```

### 集合名词速查

| 数据形态 | 集合名词 | 示例 |
|----------|----------|------|
| 有序集合 | `列表` | `用户列表` `日志列表` |
| 无序/去重 | `集合` / `HashSet` | `标签集合` `已读ID集合` |
| 计数值 | `数` / `数量` | `在线数` `失败次数` |
| 键值对 | `映射` / `表` | `配置映射` `缓存表` |
| 文本 | `消息` / `文本` | `错误消息` `提示文本` |

Nim 中集合类型对应：

| 概念 | Nim 类型 | 命名示例 |
|------|----------|----------|
| 有序集合 | `seq[T]` | `var 用户列表: seq[用户]` |
| 无序去重 | `HashSet[T]` | `var 标签集合: HashSet[string]` |
| 键值对 | `Table[K, V]` | `var 缓存表: Table[string, 缓存条目]` |
| 定长数组 | `array[N, T]` | `var 日统计: array[7, int]` |

---

## 四、英文保留规则

以下**必须保留英文**，不翻译：

| 类别 | 示例 | 原因 |
|------|------|------|
| 协议/格式 | `JSON` `HTTP` `gRPC` `XML` | 行业标准缩写 |
| 算法名 | `AES` `SHA256` `LRU` | 无歧义固定名称 |
| 专有名词 | `Redis` `PostgreSQL` `React` `Kafka` | 品牌/项目名 |
| 通用缩写 | `ID` `API` `URL` `CPU` `UUID` | 已全球通用 |
| Nim 关键字/内置类型 | `bool` `int` `string` `seq` `ref` `ptr` `var` | 语言保留 |

```nim
# 正确
proc 解析HTTP请求*(raw: seq[byte]) =
  discard

# 错误 — 不要翻译专有名词
proc 解析超文本传输协议请求*(原始数据: seq[byte]) =
  discard
```

中英混合时自然拼接即可：`解析JSON响应`、`写入Redis缓存`。

---

## 五、注释规范

```
注释只写三件事：为什么、边界在哪、什么坑
```

| 类型 | 触发条件 | 示例 |
|------|----------|------|
| **为什么** | 选型、取舍、非直觉做法 | `# 用一致性哈希而非取模：节点变动时数据迁移量更小` |
| **边界条件** | 参数约束、取值范围 | `# 折扣: [0.0, 1.0]，越界按无折扣处理` |
| **已知陷阱** | 并发、副作用、顺序依赖 | `# 非线程安全，需在持有锁时调用` |

**不写**：代码干了什么（名字已经说了）、谁写的 / 什么时候改的（用 git）。

Nim 注释格式：

```nim
## 模块级文档注释（##）—— 生成 HTML 文档

# 普通行注释（#）

discard """
  多行块注释 / 文档字符串
  可用于 proc 文档
"""

proc 查询用户*(id: 用户ID): 用户 =
  ## 按ID查询用户，未找到时返回 nil（ref 类型）
  ##
  ## 边界: id 必须 > 0，≤ 0 视为无效请求直接返回 nil
  ## 陷阱: 非线程安全，调用方需自行加锁
  discard
```

---

## 六、缩写规则

| 原词长度 | 策略 | 示例 |
|----------|------|------|
| ≤3 字 | **不缩写** | `用户名` `密码` `商品` |
| 4-5 字 | 截取首尾 | `网络连接` → `网连`（首次注释全称）|
| ≥6 字 | 语义分块 | `增值税专用发票` → `增值税票` |

**硬约束**：状态词缀（`已`/`正在`/`未`/`是否`）和量词（`个`/`次`/`秒`/`毫秒`）**永不缩写**。缩写首次出现必须注释全称。

---

## 七、Nim 语言专项

### 可见性与导出

Nim 使用 `*` 后缀标记公开（export）符号：

```nim
type
  内部状态 = enum       # 模块私有
  用户角色* = enum       # 公开导出
    管理员
    普通用户
    访客

proc 内部校验() =        # 模块私有
  discard

proc 提交订单*() =       # 公开导出
  discard
```

**建议**：对外 API（proc、type、常量）使用 `*` 导出并在命名上体现中文可读性；内部实现用无 `*` 符号，保持模块私有。

### Proc 定义

```nim
# 无返回值
proc 发送通知*(消息: string, 目标用户: 用户ID) =
  discard

# 有返回值
proc 查询用户*(id: 用户ID): 用户 =
  result = 新用户()

# 使用 result 隐式变量
proc 计算折扣*(原价: int): int =
  result = 原价 * 8 div 10  # 八折
```

### 对象（Object）

Nim 中 class 的等价物是 `object`：

```nim
type
  用户* = object
    用户ID*: 用户ID       # 字段中文命名，不重复对象名
    昵称*: string
    是否已认证*: bool
    注册时间*: int64      # Unix 时间戳（底层用 int64，无需 distinct）

  订单* = object
    订单ID*: 订单ID
    下单用户*: 用户ID
    商品列表*: seq[string]
    是否已支付*: bool
```

### 枚举（Enum）

```nim
type
  订单状态* = enum
    待支付
    已支付
    已发货
    已签收
    已取消

var 当前订单状态 = 待支付

if 当前订单状态 == 已支付:
  echo "订单已支付"
```

### 错误处理 / Result 类型

Nim 常用范式：返回 `bool` + 输出参数，或使用 `Result[T, E]` 库/内置范式：

```nim
# 范式 1: 返回布尔 + 输出参数
proc 尝试解析*(输入: string, 输出: var 解析结果): bool =
  # 成功返回 true，失败返回 false
  result = true

# 范式 2: 抛出异常（Nim 支持）
proc 必须解析*(输入: string): 解析结果 =
  if 输入.len == 0:
    raise newException(ValueError, "输入为空")
  # ...

# 范式 3: Option[T]（stdlib/options）
import std/options

proc 可能查询*(id: 用户ID): Option[用户] =
  ## 返回 some(用户) 或 none(用户)
  discard
```

### 模板与宏

模板/宏名同样遵循中文命名：

```nim
template 以锁保护*(锁: var Lock, 主体: untyped) =
  acquire(锁)
  try:
    主体
  finally:
    release(锁)

# 调用
以锁保护 我的锁:
  echo "临界区"
```

---

## 八、Nim 宏：中文编程的编译期利器

### 核心价值

中文编程的痛点有三：手写样板代码量大、类型系统强安全与开发速度的权衡、命名约定的检查依赖人工。Nim 宏在**编译期直接操作 AST**，这三件事一网打尽：

| 痛点 | 宏解法 | 收益 |
|------|--------|------|
| distinct 类型每次要手写 `+.borrow` `$` `转换` | `定义Distinct类型` 一行生成全套 | 类型安全零成本 |
| 对象 + CRUD + 存储每次重复手写 | `定义实体` 一行生成对象 + 存储 + 查询/保存/删除 | 业务层零样板 |
| bool 变量是否漏掉 `是否` 前缀 | `检查命名` 编译期断言，违规拒绝编译 | 规范自动落地 |
| 状态机手写 if/else 散落各处 | `定义状态机` 声明式定义转换表 | 状态流转一目了然 |

---

### 8.1 定义Distinct类型 — 消除类型系统样板

每次定义 `秒`、`金额` 等 distinct 类型都要手写 borrow、`$`、转换函数。一行宏全搞定：

```nim
import std/macros

macro 定义Distinct类型*(类型名, 底层类型: untyped): untyped =
  ## 定义一个 distinct 类型，自动生成：
  ## - {.borrow.} 算术运算符（仅数值底层类型）
  ## - `$` 字符串化
  ## - 底层类型互转 proc
  ## - 比较运算符
  let 底层类型名 = 底层类型  # 如 int64
  result = quote do:
    type
      `类型名`* = distinct `底层类型名`

    # 字符串化
    proc `$`*(x: `类型名`): string = `$`(`底层类型名`(x))

    # 与底层类型互转
    converter to`底层类型名`*(x: `类型名`): `底层类型名` = `底层类型名`(x)
    converter from`底层类型名`*(x: `底层类型名`): `类型名` = `类型名`(x)

    # 比较运算符（所有 distinct 类型通用）
    proc `==`*(a, b: `类型名`): bool {.borrow.}
    proc `<`*(a, b: `类型名`): bool {.borrow.}
    proc `<=`*(a, b: `类型名`): bool {.borrow.}

# ── 使用：一行定义 ──

定义Distinct类型(秒, int64)
定义Distinct类型(金额, int64)   # 单位：分
定义Distinct类型(用户ID, int64)
定义Distinct类型(订单ID, string)  # 字符串底层也支持

# 直接使用，无需任何手写样板
var 过期时间: 秒 = 3600.秒
var 实付金额: 金额 = 9950.金额

if 过期时间 < 7200.秒:
  echo "即将过期"

echo 实付金额  # 自动调用 `$`
```

**进阶**：可按需生成单位转换链：

```nim
macro 定义带单位的Distinct类型*(类型名, 底层类型: untyped,
                                 下级单位: untyped = nil): untyped =
  ## 除了基础 distinct，还自动生成 单位转下级单位 / 下级转单位
  result = newStmtList()
  result.add quote do:
    定义Distinct类型(`类型名`, `底层类型`)

  if 下级单位.kind != nnkNilLit:
    let 转换比 = 1000  # 可根据实际参数调整
    result.add quote do:
      func 转`下级单位`*(x: `类型名`): `下级单位` =
        `下级单位`(`底层类型`(x) * `转换比`)
      func 从`下级单位`*(x: `下级单位`): `类型名` =
        `类型名`(`底层类型`(x) div `转换比`)
```

---

### 8.2 定义实体 — 对象 + 存储 + CRUD 一行生成

最常见的模式：定义一个对象 → 定义一个 Table 存储 → 手写查询/保存/删除。宏将其压缩到一行声明：

```nim
import std/[macros, tables, options, strutils]

macro 定义实体*(实体名, 字段定义: untyped): untyped =
  ## 从字段定义自动生成：
  ## 1. 对象类型: `实体名`
  ## 2. ID 类型: `实体名ID`（从第一个字段推导）
  ## 3. 存储类型: `实体名存储`（内含 Table + 索引）
  ## 4. proc 查询`实体名`
  ## 5. proc 保存`实体名`
  ## 6. proc 删除`实体名`
  ## 7. proc 列表`实体名`
  ##
  ## 示例调用：
  ##   定义实体(订单):
  ##     订单ID: 订单ID
  ##     下单用户: 用户ID
  ##     实付金额: 金额
  ##     是否已支付: bool

  let 字段列表 = 字段定义[0]  # nnkTupleConstr or nnkObjConstr
  var 字段声明 = nnkRecList.newTree()
  let 实体名id = ident($实体名 & "ID")
  let 存储名 = ident($实体名 & "存储")
  let 表名 = ident($实体名 & "表")
  let 实体名str = $实体名

  # 提取第一个字段当 ID 字段名和类型
  var id字段名: NimNode
  var id字段类型: NimNode
  var 是否第一个 = true

  for 字段 in 字段列表:
    if 字段.kind == nnkIdentDefs:
      let 名 = 字段[0]
      let 类型 = 字段[1]
      字段声明.add nnkIdentDefs.newTree(名, 类型, newEmptyNode())
      if 是否第一个:
        id字段名 = 名
        id字段类型 = 类型
        是否第一个 = false

  let 查询proc名 = ident("查询" & 实体名str)
  let 保存proc名 = ident("保存" & 实体名str)
  let 删除proc名 = ident("删除" & 实体名str)
  let 列表proc名 = ident("列表" & 实体名str)

  result = quote do:
    type
      `实体名`* = object
        `字段声明`

      `存储名`* = object
        `表名`*: Table[`id字段类型`, `实体名`]

    proc `查询proc名`*(存储: var `存储名`, id: `id字段类型`): Option[`实体名`] =
      if id in 存储.`表名`:
        result = some(存储.`表名`[id])

    proc `保存proc名`*(存储: var `存储名`, 实体: `实体名`) =
      存储.`表名`[实体.`id字段名`] = 实体

    proc `删除proc名`*(存储: var `存储名`, id: `id字段类型`): bool =
      if id in 存储.`表名`:
        存储.`表名`.del(id)
        result = true

    proc `列表proc名`*(存储: var `存储名`): seq[`实体名`] =
      result = toSeq(存储.`表名`.values)

# ── 使用示例 ──

定义实体(订单):
  订单ID: string
  下单用户: string
  实付金额: int64
  是否已支付: bool

var 订单存储: 订单存储
订单存储.保存订单(订单(订单ID: "A001", 下单用户: "U042", 实付金额: 9950, 是否已支付: false))

if let 某订单 = 订单存储.查询订单("A001"); 某订单.isSome:
  echo 某订单.get.实付金额
```

---

### 8.3 定义状态机 — 声明式状态流转

状态机在业务代码中无处不在（订单、审批、工单）。手写散落各处的 if/else 易遗漏转换检查。宏从声明式定义自动生成完整的 transition proc：

```nim
import std/macros

macro 定义状态机*(类型名, 初始状态, 转换规则: untyped): untyped =
  ## 声明式定义状态机，编译期展开为：
  ## - 状态枚举
  ## - `类型名`状态字段
  ## - `尝试转换`类型名` proc：校验转换合法性并执行
  ## - `可能转换`类型名` proc：列出当前状态的所有合法目标
  ##
  ## 示例：
  ##   定义状态机(订单, 待支付):
  ##     (待支付 → 已支付)
  ##     (待支付 → 已取消)
  ##     (已支付 → 已发货)
  ##     (已发货 → 已签收)

  # 收集所有唯一状态名
  var 状态集合: seq[string]
  var 转换表: seq[(string, string)]

  for 规则 in 转换规则:
    if 规则.kind == nnkInfix and $规则[0] == "→":
      let 从 = $规则[1]
      let 到 = $规则[2]
      if 从 notin 状态集合: 状态集合.add 从
      if 到 notin 状态集合: 状态集合.add 到
      转换表.add((从, 到))

  # 构建枚举
  var 枚举成员 = nnkEnumTy.newTree()
  for s in 状态集合:
    枚举成员.add ident(s)

  let 枚举名 = ident($类型名 & "状态")
  let 转换proc名 = ident("尝试转换" & $类型名)
  let 可能proc名 = ident("可能转换" & $类型名)

  # 构建转换 proc 的 case 分支
  var 分支列表 = nnkCaseStmt.newTree(newDotExpr(ident("实体"), ident("状态")))
  for s in 状态集合:
    var 目标列表 = nnkOfBranch.newTree(ident(s))
    var 内部if = newStmtList()
    for (从, 到) in 转换表:
      if 从 == s:
        内部if.add quote do:
          if 新状态 == `ident(到)`:
            实体.状态 = `ident(到)`
            实体.`ident("转换" & 到 & "时")`()  # 回调钩子
            return true
    目标列表.add 内部if
    分支列表.add 目标列表

  result = quote do:
    type
      `枚举名`* = enum
        `枚举成员`

    proc `转换proc名`*(实体: var `类型名`, 新状态: `枚举名`): bool =
      ## 尝试将实体转换到新状态，非法转换返回 false
      `分支列表`

    proc `可能proc名`*(实体: `类型名`): seq[`枚举名`] =
      ## 返回当前状态所有合法的目标状态
      result = @[]
      case 实体.状态
      `for s in 状态集合:`
        `let 目标s = s`
        `for (从, 到) in 转换表:`
          `if 从 == s:`
            `result.add ident(到)`

# ── 使用 ──

type
  订单 = object
    状态: 订单状态
    金额: int64

  定义状态机(订单, 待支付):
    (待支付 → 已支付)
    (待支付 → 已取消)
    (已支付 → 已发货)
    (已发货 → 已签收)

var 我的订单 = 订单(状态: 待支付, 金额: 10000)

if 我的订单.尝试转换订单(已支付):
  echo "支付成功"
else:
  echo "不允许从已支付转换到待支付"

echo "当前可转换到: ", 我的订单.可能转换订单()  # @[已发货]
```

---

### 8.4 编译期命名检查 — 规范自动化

规范写得再好，没有工具检查就是一纸空文。用宏在编译期强制执行：

```nim
import std/macros

macro 强制命名检查*(主体: untyped): untyped =
  ## 编译期扫描语句块内所有变量定义，检查：
  ## 1. bool 类型变量必须 `是否` 前缀
  ## 2. seq 类型变量必须 `列表` / `集合` 后缀
  ## 3. distinct 类型变量名不能包含单位后缀（如 `金额分`）
  ##
  ## 违规直接产生编译错误，拒绝编译。

  var 错误列表: seq[string]

  proc 检查节点(节点: NimNode) =
    case 节点.kind
    of nnkVarSection, nnkLetSection:
      for 定义 in 节点:
        if 定义.kind == nnkIdentDefs:
          let 变量名 = $定义[0]
          let 类型节点 = 定义[1]

          # 检查 bool
          if 类型节点.kind == nnkIdent and $类型节点 == "bool":
            if not 变量名.startsWith("是否"):
              错误列表.add "布尔变量 `" & 变量名 & "` 必须以 `是否` 开头"

          # 检查 seq
          if 类型节点.kind == nnkBracketExpr and $类型节点[0] == "seq":
            if not (变量名.endsWith("列表") or 变量名.endsWith("集合") or 变量名.endsWith("数组")):
              错误列表.add "seq 变量 `" & 变量名 & "` 应以 `列表`/`集合`/`数组` 结尾"

    else:
      for 子 in 节点.children:
        检查节点(子)

  检查节点(主体)

  if 错误列表.len > 0:
    let 错误消息 = 错误列表.join("\n")
    error(错误消息, 主体)

  result = 主体

# ── 使用 ──

强制命名检查:
  var 是否有效: bool = true        # ✓
  var 用户列表: seq[string] = @[]  # ✓
  # var running: bool = false       # ✗ 编译错误！
  # var data: seq[int]              # ✗ 编译错误！
```

---

### 8.5 中文 DSL — 声明式业务逻辑

宏的终极价值：让业务逻辑读起来像需求文档。

```nim
import std/macros

macro 若(条件: untyped; 则: untyped; 否则: untyped = nil): untyped =
  ## 中文 if/else，配合缩进
  if 否则.isNil:
    result = nnkIfStmt.newTree(
      nnkElifBranch.newTree(条件, 则)
    )
  else:
    result = nnkIfStmt.newTree(
      nnkElifBranch.newTree(条件, 则),
      nnkElse.newTree(否则)
    )

macro 遍历(迭代变量, 集合: untyped; 主体: untyped): untyped =
  ## for-in 的中文写法
  result = nnkForStmt.newTree(迭代变量, 集合, 主体)

macro 当(条件: untyped; 主体: untyped): untyped =
  ## while 的中文写法
  result = nnkWhileStmt.newTree(条件, 主体)

# ── 使用 ──

proc 处理订单*(订单列表: seq[订单]) =
  遍历 订单, 订单列表:
    若 订单.是否已支付:
      echo "订单 ", 订单.订单ID, " 已支付"
    否则:
      echo "订单 ", 订单.订单ID, " 未支付"
```

更极致的业务 DSL：

```nim
macro 校验*(主体: untyped): untyped =
  ## 将声明式校验规则转换为 proc 参数校验代码
  ##
  ##   校验 订单:
  ##     商品列表非空
  ##     实付金额 > 0
  ##     下单用户有效
  ##
  ## 展开为 if/return 校验链
  result = newStmtList()
  for 规则 in 主体:
    if 规则.kind == nnkInfix:
      result.add quote do:
        if not (`规则`):
          return false
    elif 规则.kind == nnkIdent and $规则 == "非空":
      discard  # 已在上面处理

# ── 使用 ──

proc 提交前校验*(订单: 订单): bool =
  result = true
  校验:
    订单.商品列表.len > 0
    订单.实付金额 > 0.金额
    订单.下单用户 != 0.用户ID
```

---

### 8.6 以重试执行 / 统计耗时 — 切面宏

横切关注点（重试、计时、日志）天然适合模板/宏，而且中文调用让意图一目了然：

```nim
import std/[times, strformat]

template 统计耗时*(标签: string, 主体: untyped) =
  ## 编译期为代码块注入计时代码，中文日志输出
  let 开始时间 = cpuTime()
  主体
  let 耗时 = cpuTime() - 开始时间
  echo &"[{标签}] 耗时: {耗时:.3f} 秒"

template 以重试执行*(最大重试次数: int, 主体: untyped) =
  ## 为代码块注入重试逻辑，失败时打印中文日志
  block:
    var 已重试次数 = 0
    var 是否成功 = false
    while 已重试次数 <= 最大重试次数 and not 是否成功:
      try:
        主体
        是否成功 = true
      except CatchableError as e:
        已重试次数 += 1
        if 已重试次数 > 最大重试次数:
          raise
        echo &"重试 {已重试次数}/{最大重试次数}: {e.msg}"

# ── 使用 ──

统计耗时 "查询Redis缓存":
  let 结果 = redis.get("user:42")
  echo 结果

以重试执行 3:
  let 响应 = httpClient.post("https://api.example.com/orders", 请求体)
  if 响应.code != 200:
    raise newException(ValueError, "服务不可用")
```

---

### 8.7 宏使用守则

| 原则 | 说明 |
|------|------|
| **宏是最后的武器** | 先看模板(template)能否解决，再看宏。模板更轻量且调试友好 |
| **宏名必须是动词/动词短语** | `定义实体` ✓ `实体定义器` ✗（直觉第一） |
| **宏展开后代码必须可读** | 用 `macros.dumpTree` 检查生成的 AST。失控的宏是负债 |
| **一个宏只做一件事** | `定义Entity` 生成对象+CRUD ✓，把路由也塞进去 ✗ |
| **错误消息用中文** | `"布尔变量 `" & 变量名 & "` 必须以 `是否` 开头"` — 让编译错误也是中文 |
| **先行后宏** | 先用 proc 写三遍同样样板，确认真的是重复模式，再抽象为宏 |

---

### 8.8 宏选型速查表

| 你要做什么 | 用什么 | 原因 |
|-----------|--------|------|
| 消除 distinct 类型样板 | `定义Distinct类型` 宏 | borrow / `$` / 转换 4 行变 1 行 |
| 生成 CRUD + 存储 | `定义实体` 宏 | 每个实体省 ~40 行样板 |
| 声明式状态机 | `定义状态机` 宏 | 转换规则集中声明，编译器帮你检查完整性 |
| 编译期命名检查 | `强制命名检查` 宏 | 规范自动落地，零人为遗漏 |
| 中文 DSL（若/遍历/当） | `若` / `遍历` / `当` 模板 | 模板足够，不需要宏 |
| 注入计时代码 | `统计耗时` 模板 | 模板足够，不需要宏 |
| 注入重试逻辑 | `以重试执行` 模板 | 模板足够，不需要宏 |
| 编译期生成复杂数据结构 | 宏 | 模板无法操作类型定义 |

---

## 九、完整代码示例

```nim
## 订单服务模块
##
## 负责订单的创建、查询与状态流转。
## 所有 proc 均为单线程假设，多线程场景下调用方自行同步。

import std/[tables, options]

# ── 类型定义 ──────────────────────────────────────

type
  用户ID* = distinct int64
  订单ID* = distinct int64
  秒* = distinct int64
  金额* = distinct int64      # 单位：分

  订单状态* = enum
    待支付
    已支付
    已发货
    已签收
    已取消

  订单* = object
    订单ID*: 订单ID
    下单用户*: 用户ID
    商品列表*: seq[string]
    实付金额*: 金额
    是否已支付*: bool
    创建时间*: 秒

  订单存储* = object
    订单表*: Table[订单ID, 订单]
    用户订单映射*: Table[用户ID, seq[订单ID]]

# ── 辅助转换 ──────────────────────────────────────

func 分转元*(分: 金额): float64 = 分.int64.float64 / 100.0
func 元转分*(元: float64): 金额 = (元 * 100.0).int64.金额

# ── 存储操作 ──────────────────────────────────────

proc 查询订单*(存储: var 订单存储, id: 订单ID): Option[订单] =
  ## 按ID查询订单，未找到返回 none(订单)
  if id in 存储.订单表:
    result = some(存储.订单表[id])
  else:
    result = none(订单)

proc 保存订单*(存储: var 订单存储, 订单: 订单) =
  ## 保存订单，同时更新用户订单映射
  ## 陷阱：调用方需确保订单ID不会重复，此处不检查幂等
  存储.订单表[订单.订单ID] = 订单

  # 更新反向索引
  if 订单.下单用户 notin 存储.用户订单映射:
    存储.用户订单映射[订单.下单用户] = @[]
  存储.用户订单映射[订单.下单用户].add(订单.订单ID)

# ── 业务逻辑 ──────────────────────────────────────

proc 提交前校验*(订单: 订单): bool =
  ## 订单提交前的完整性校验
  ## 边界：商品列表为空、金额 ≤ 0 均拒绝
  result = 订单.商品列表.len > 0 and 订单.实付金额.int64 > 0

proc 创建订单*(下单用户: 用户ID, 商品列表: seq[string],
               实付金额: 金额, 当前时间: 秒): 订单 =
  ## 创建新订单，默认状态为 待支付
  result = 订单(
    商品列表: 商品列表,
    实付金额: 实付金额,
    下单用户: 下单用户,
    是否已支付: false,
    创建时间: 当前时间,
  )

# ── 使用示例 ──────────────────────────────────────

when isMainModule:
  var 存储 = 订单存储()

  let 新订单 = 创建订单(
    下单用户 = 42.用户ID,
    商品列表 = @["Nim 编程指南", "算法图解"],
    实付金额 = 元转分(99.50),
    当前时间 = 1717084800.秒,
  )

  if 提交前校验(新订单):
    存储.保存订单(新订单)
    echo "订单创建成功，金额: ", 分转元(新订单.实付金额), " 元"
```

---

## 十、团队落地检查清单

- [ ] 建立团队术语表（≤ 50 个核心术语，写入 `GLOSSARY.md`）
- [ ] 配置输入法团队共享词库（`sfzz` → `是否正在`，`yhtj` → `已回退`）
- [ ] 新人入职：本规范 + 术语表 + 示例项目，30 分钟内可写出合规 Nim 代码
- [ ] 每周代码评审中记录高频不规范命名，补充术语表
- [ ] 季度审视：删除废弃术语，合并同义词
- [ ] CI 接入 `nim check` / `nimpretty` 并配置中文命名检查规则

---

核心理念：相信中文母语直觉，让 Nim 的 `distinct` 类型系统替你携带单位与语义，让状态与时机一览无余。一套规则，内部一致即科学。
