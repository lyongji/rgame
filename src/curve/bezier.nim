##
## 贝塞尔曲线库
##
## 基于以下工作：
## * https://pomax.github.io/bezierinfo/
## * https://pomax.github.io/bezierjs/
## * https://github.com/Pomax/bezierjs
## * https://github.com/oysteinmyrmo/bezier
##

import vmath, sequtils, algorithm, bezier/util, options

type
    Bezier*[N: static[int]] = object
        ## 阶数为 `N` 的贝塞尔曲线
        points: array[N + 1, Vec2]

    DynBezier* = object
        ## 阶数在编译时未知的贝塞尔曲线
        points: seq[Vec2]

    LUT*[T: Bezier | DynBezier] {.byref.} = object
        ## 曲线内预计算点的查找表
        table: seq[tuple[t: float, point: Vec2, distanceFrom0: float]]
        curve: T

template assign(points: typed) =
    for i in 0..<points.len:
        result.points[i] = points[i]

proc newBezier*[N](points: varargs[Vec2]): Bezier[N] =
    ## 创建一个新的贝塞尔曲线，曲线阶数在编译时已知。例如，传入 `N = 3` 表示三次曲线。
    # 函数名：newBezier - 创建新贝塞尔曲线
    assert(points.len == N + 1)
    assign(points)

proc newDynBezier*(points: varargs[Vec2]): DynBezier =
    ## 创建一个新的贝塞尔曲线，曲线阶数仅在运行时已知。
    # 函数名：newDynBezier - 创建动态贝塞尔曲线
    result.points.setLen(points.len)
    assign(points)

proc order*(curve: DynBezier): Natural = curve.points.len - 1
    ## 曲线的阶数是定义曲线所用的点数，从0开始。
    ## `N = 1` 是线性（2个点），`N = 2` 是二次（3个点），`N = 3` 是三次（4个点）
    # 函数名：order - 获取曲线阶数

proc order*[N](curve: Bezier[N]): Natural = N
    ## 曲线的阶数是定义曲线所用的点数，从0开始。
    ## `N = 1` 是线性（2个点），`N = 2` 是二次（3个点），`N = 3` 是三次（4个点）
    # 函数名：order - 获取曲线阶数

proc `$`*(curve: Bezier | DynBezier): string =
    ## 创建贝塞尔曲线的字符串表示
    # 函数名：`$` - 转换为字符串
    result = "Bezier["
    var first = true
    for point in curve.points:
        if first:
            first = false
        else:
            result.add(", ")
        result.add("{")
        result.add($point.x)
        result.add(", ")
        result.add($point.y)
        result.add("}")
    result.add("]")

proc `[]`*[N](curve: Bezier[N], point: range[0..N]): Vec2 = curve.points[point]
    ## 返回该曲线内的一个控制点
    # 函数名：`[]` - 下标访问控制点

proc `[]`*(curve: DynBezier, point: Natural): Vec2 = curve.points[point]
    ## 返回该曲线内的一个控制点
    # 函数名：`[]` - 下标访问控制点

iterator pairs*(curve: DynBezier | Bezier): (int, Vec2) =
    ## 生成该曲线中的所有点及其索引
    # 函数名：pairs - 迭代控制点（带索引）
    for i in 0..curve.order:
        yield (i, curve.points[i])

iterator items*(curve: DynBezier | Bezier): lent Vec2 =
    ## 生成该曲线中的所有点
    # 函数名：items - 迭代控制点
    for i in 0..curve.order:
        yield curve.points[i]

template mapItTpl[OutputType](order, curve: typed, mapper: untyped): OutputType =
    ## 将映射函数应用于曲线中的点
    block:
        var output: OutputType
        when compiles(output.points.setLen(order + 1)): output.points.setLen(order + 1)
        for i in 0..order:
            let it {.inject.} = curve.points[i]
            output.points[i] = mapper
        output

template mapIt*[N](curve: Bezier[N], mapper: untyped): Bezier[N] =
    ## 将映射函数应用于曲线中的点。在映射块内，名为 `it` 的变量将被注入当前点。
    # 函数名：mapIt - 映射控制点
    mapItTpl[Bezier[N]](N, curve, mapper)

template mapIt*(curve: DynBezier, mapper: untyped): DynBezier =
    ## 将映射函数应用于曲线中的点。在映射块内，名为 `it` 的变量将被注入当前点。
    # 函数名：mapIt - 映射控制点
    mapItTpl[DynBezier](curve.order, curve, mapper)

proc computeForQuadOrCubic(p0, p1, p2, p3: Vec2; a, b, c, d: float): Vec2 {.inline.} =
    vec2(
        a * p0.x + b * p1.x + c * p2.x + d * p3.x,
        a * p0.y + b * p1.y + c * p2.y + d * p3.y,
    )

proc computeForLinear(curve: Bezier | DynBezier, t: float): Vec2 {.inline.} =
    let mt = 1 - t
    return vec2(
        mt * curve.points[0].x + t * curve.points[1].x,
        mt * curve.points[0].y + t * curve.points[1].y
    )

proc computeForQuad(curve: Bezier | DynBezier, t: float): Vec2 {.inline.} =
    let mt = 1 - t
    return computeForQuadOrCubic(
        curve.points[0], curve.points[1], curve.points[2], vec2(0, 0),
        a = mt * mt,
        b = mt * t * 2,
        c = t * t,
        d = 0
    )

proc computeForCubic(curve: Bezier | DynBezier, t: float): Vec2 {.inline.} =
    let mt = 1 - t
    return computeForQuadOrCubic(
        curve.points[0], curve.points[1], curve.points[2], curve.points[3],
        a = mt * mt * mt,
        b = mt * mt * t * 3,
        c = mt * t * t * 3,
        d = t * t * t
    )

proc compute*[N](curve: Bezier[N], t: float): Vec2 =
    ## 计算曲线上一点的位置，其中 `t` 是介于 0.0 和 1.0 之间的值。
    # 函数名：compute - 计算曲线上的点
    when N == 0: return curve.points[0]
    elif N == 1: return computeForLinear(curve, t)
    elif N == 2: return computeForQuad(curve, t)
    elif N == 3: return computeForCubic(curve, t)
    else: return deCasteljau(curve.points, t).finalPoint

proc compute*(curve: DynBezier, t: float): Vec2 =
    ## 计算曲线上一点的位置，其中 `t` 是介于 0.0 和 1.0 之间的值。
    # 函数名：compute - 计算曲线上的点
    case curve.order
    of 0: return curve.points[0]
    of 1: return computeForLinear(curve, t)
    of 2: return computeForQuad(curve, t)
    of 3: return computeForCubic(curve, t)
    else: return deCasteljau(curve.points, t).finalPoint

template xyTpl(curve: typed, prop: untyped) =
    when compiles(result.setLen(0)): result.setLen(curve.points.len)
    for i, point in curve: result[i] = point.`prop`

proc xs*[N](curve: Bezier[N]): array[N + 1, float] = xyTpl(curve, x)
    ## 返回该曲线中所有点的 x 值
    # 函数名：xs - 获取所有 x 坐标

proc xs*(curve: DynBezier): seq[float] = xyTpl(curve, x)
    ## 返回该曲线中所有点的 x 值
    # 函数名：xs - 获取所有 x 坐标

proc ys*[N](curve: Bezier[N]): array[N + 1, float] = xyTpl(curve, y)
    ## 返回该曲线中所有点的 y 值
    # 函数名：ys - 获取所有 y 坐标

proc ys*(curve: DynBezier): seq[float] = xyTpl(curve, y)
    ## 返回该曲线中所有点的 y 值
    # 函数名：ys - 获取所有 y 坐标

template derivativeTpl(curve: typed) =
    for i in 0..<curve.order:
        output.points[i] = (curve.points[i + 1] - curve.points[i]) * curve.order.float
    return output

proc derivative*[N](curve: Bezier[N]): auto =
    ## 计算贝塞尔曲线的导数。结果是一条阶数为 N-1 的新贝塞尔曲线。
    # 函数名：derivative - 求导
    when N <= 0: {.error( "不能对常数曲线求导").}
    var output: Bezier[N - 1]
    derivativeTpl(curve)

proc derivative*(curve: DynBezier): DynBezier =
    ## 计算贝塞尔曲线的导数。结果是一条阶数为 N-1 的新贝塞尔曲线。
    # 函数名：derivative - 求导
    assert(curve.order > 0, "不能对常数曲线求导")
    var output: DynBezier
    output.points.setLen(curve.points.len - 1)
    derivativeTpl(curve)

proc addExtrema(curve: Bezier | DynBezier, output: var seq[float]) =
    for t in roots(curve.xs): output.add(abs(t))
    for t in roots(curve.ys): output.add(abs(t))

template extremaTpl(curve: typed) =
    let deriv = curve.derivative()

    var output = newSeq[float]()
    addExtrema(deriv, output)

    if curve.order == 3:
        addExtrema(deriv.derivative(), output)

    sort(output)
    yieldAll(forDistinct(output))

iterator extrema*[N](curve: Bezier[N]): float =
    ## 计算曲线上的所有极值点，表示为 0.0 到 1.0 之间的位置。可以将这些值传递给 `compute` 方法获取它们的坐标。
    # 函数名：extrema - 获取极值点参数 t
    when N > 1: extremaTpl(curve)

iterator extrema*(curve: DynBezier): float = extremaTpl(curve)
    ## 计算曲线上的所有极值点，表示为 0.0 到 1.0 之间的位置。可以将这些值传递给 `compute` 方法获取它们的坐标。
    # 函数名：extrema - 获取极值点参数 t

proc boundingBox*(curve: Bezier | DynBezier): tuple[minX, minY, maxX, maxY: float] =
    ## 返回曲线的包围盒
    # 函数名：boundingBox - 计算包围盒
    result = (curve.points[0].x.float, curve.points[0].y.float, curve.points[0].x.float, curve.points[0].y.float)

    if curve.order > 0:
        proc handlePoint(point: Vec2, output: var tuple[minX, minY, maxX, maxY: float]) =
            output.minX = min(point.x, output.minX)
            output.minY = min(point.y, output.minY)
            output.maxX = max(point.x, output.maxX)
            output.maxY = max(point.y, output.maxY)

        handlePoint(curve.points[curve.order], result)
        for extrema in curve.extrema():
            curve.compute(extrema).handlePoint(result)

template withAligned(curve: Bezier | DynBezier, p1, p2: Vec2, exec: untyped) =
    ## 执行回调，该回调需要一条与某点对齐的贝塞尔曲线，并提供额外的细节。
    let ang = -arctan2(p2.y - p1.y, p2.x - p1.x)
    let cosA {.inject.} = cos(ang)
    let sinA {.inject.} = sin(ang)
    let aligned {.inject.} = curve.mapIt:
        vec2((it.x - p1.x) * cosA - (it.y - p1.y) * sinA, (it.x - p1.x) * sinA + (it.y - p1.y) * cosA)
    exec

proc align*(curve: Bezier | DynBezier, p1, p2: Vec2): auto =
    ## 旋转该贝塞尔曲线，使其与给定直线对齐。
    # 函数名：align - 对齐曲线
    withAligned(curve, p1, p2): return aligned

proc tightBoundingBox*(curve: Bezier | DynBezier): array[4, Vec2] =
    ## 返回一个紧密贴合曲线的包围盒的四个角点。
    # 函数名：tightBoundingBox - 计算紧密包围盒
    if curve.order == 0:
        for i in 0..3: result[i] = curve.points[0]
    else:
        withAligned(curve, curve.points[0], curve.points[curve.order]):

            template corner(x, y: float): Vec2 =
                 vec2(curve.points[0].x + x * cosA - y * -sinA, curve.points[0].y + x * -sinA + y * cosA)

            let (minX, minY, maxX, maxY) = aligned.boundingBox()
            result[0] = corner(minX, minY)
            result[1] = corner(maxX, minY)
            result[2] = corner(maxX, maxY)
            result[3] = corner(minX, maxY)

iterator findY*(curve: Bezier | DynBezier, x: float): Vec2 =
    ## 对于给定的 X 值，产生对应的 Y 值。因为贝塞尔曲线可能与同一个 `x` 值有多个交点，所以可能产生多个值。
    # 函数名：findY - 根据 X 查找 Y
    if curve.order == 0:
        if x == curve.points[0].x:
            yield curve.points[0]
    else:
        var xVals = curve.xs()
        for i in 0..curve.order:
            xVals[i] -= x
        for root in roots(xVals):
            yield curve.compute(root)

proc findMaxY*(curve: Bezier | DynBezier, x: float): Option[Vec2] =
    ## 对于给定的 `x`，找到曲线上的最大 `y` 值。
    # 函数名：findMaxY - 根据 X 查找最大 Y
    for point in findY(curve, x):
        if result.isNone or point.y > result.unsafeGet.y:
            result = some(point)

proc findMinY*(curve: Bezier | DynBezier, x: float): Option[Vec2] =
    ## 对于给定的 `x`，找到曲线上的最小 `y` 值。
    # 函数名：findMinY - 根据 X 查找最小 Y
    for point in findY(curve, x):
        if result.isNone or point.y < result.unsafeGet.y:
            result = some(point)

iterator points*(curve: Bezier | DynBezier, steps: range[2..high(int)]): tuple[t: float, point: Vec2] =
    ## 按给定的步数在曲线上生成一系列点。
    # 函数名：points - 迭代曲线上的点
    let step: float = 1 / (steps - 1)
    var t: float = 0
    for i in 1..steps:
        if i == steps:
            t = 1.0
        yield (t, curve.compute(t))
        t += step

iterator segments*(curve: Bezier | DynBezier, steps: Positive): (Vec2, Vec2) =
    ## 将曲线分解为直线段。也称为曲线展平。这些线段不保证几何均匀。
    # 函数名：segments - 迭代曲线分段
    if curve.order > 0:
        var previous: Vec2
        for (t, current) in points(curve, steps + 1):
            if t != 0.0:
                yield (previous, current)
            previous = current

proc tangent*(curve: Bezier | DynBezier, t: float): Vec2 =
    ## 返回给定位置处的切向量，其中 `t` 是介于 0.0 和 1.0 之间的值。
    # 函数名：tangent - 计算切向量
    curve.derivative().compute(t)

proc normal*(curve: Bezier | DynBezier, t: float): Vec2 =
    ## 返回给定位置处的法向量，其中 `t` 是介于 0.0 和 1.0 之间的值。
    # 函数名：normal - 计算法向量
    let d = curve.tangent(t)
    let q = sqrt(d.x * d.x + d.y * d.y)
    return vec2(-d.y / q, d.x / q)

iterator intersects*(curve: Bezier | DynBezier, p1, p2: Vec2): Vec2 =
    ## 生成曲线与直线相交的点。
    # 函数名：intersects - 迭代交点
    case curve.order
    of 0:
        if curve.points[0].isOnLine(p1, p2):
            yield curve.points[0]
    of 1:
        let intersect = linesIntersect(curve.points[0], curve.points[curve.order], p1, p2)
        if intersect.isSome:
            yield intersect.get
    else:
        let aligned = curve.align(p1, p2)
        for t in roots(aligned.ys):
            yield curve.compute(t)

template splitTpl(curve, t: typed) =
    let calculated = deCasteljau(curve.points, t)
    forIndexed(i, point, left(calculated)):
        result[0].points[i] = point
    forIndexed(i, point, right(calculated)):
        result[1].points[i] = point

proc split*[N](curve: Bezier[N], t: float): (Bezier[N], Bezier[N]) =
    ## 在给定位置分割曲线，其中 `t` 是介于 0.0 和 1.0 之间的值。
    # 函数名：split - 分割曲线
    when N == 0: {.error("不能分割零阶曲线").}
    else: splitTpl(curve, t)

proc split*(curve: DynBezier, t: float): (DynBezier, DynBezier) =
    ## 在给定位置分割曲线，其中 `t` 是介于 0.0 和 1.0 之间的值。
    # 函数名：split - 分割曲线
    assert(curve.order > 0)
    result[0].points.setLen(curve.points.len)
    result[1].points.setLen(curve.points.len)
    splitTpl(curve, t)

# Legendre-Gauss abscissae with n=24 (x_i values, defined at i=n
# as the roots of the nth order Legendre polynomial Pn(x))
const Tvalues = [
    -0.0640568928626056260850430826247450385909,
    0.0640568928626056260850430826247450385909,
    -0.1911188674736163091586398207570696318404,
    0.1911188674736163091586398207570696318404,
    -0.3150426796961633743867932913198102407864,
    0.3150426796961633743867932913198102407864,
    -0.4337935076260451384870842319133497124524,
    0.4337935076260451384870842319133497124524,
    -0.5454214713888395356583756172183723700107,
    0.5454214713888395356583756172183723700107,
    -0.6480936519369755692524957869107476266696,
    0.6480936519369755692524957869107476266696,
    -0.7401241915785543642438281030999784255232,
    0.7401241915785543642438281030999784255232,
    -0.8200019859739029219539498726697452080761,
    0.8200019859739029219539498726697452080761,
    -0.8864155270044010342131543419821967550873,
    0.8864155270044010342131543419821967550873,
    -0.9382745520027327585236490017087214496548,
    0.9382745520027327585236490017087214496548,
    -0.9747285559713094981983919930081690617411,
    0.9747285559713094981983919930081690617411,
    -0.9951872199970213601799974097007368118745,
    0.9951872199970213601799974097007368118745,
]

# Legendre-Gauss weights with n=24 (w_i values, defined by a function linked to in the Bezier primer article)
const Cvalues = [
    0.1279381953467521569740561652246953718517,
    0.1279381953467521569740561652246953718517,
    0.1258374563468282961213753825111836887264,
    0.1258374563468282961213753825111836887264,
    0.121670472927803391204463153476262425607,
    0.121670472927803391204463153476262425607,
    0.1155056680537256013533444839067835598622,
    0.1155056680537256013533444839067835598622,
    0.1074442701159656347825773424466062227946,
    0.1074442701159656347825773424466062227946,
    0.0976186521041138882698806644642471544279,
    0.0976186521041138882698806644642471544279,
    0.086190161531953275917185202983742667185,
    0.086190161531953275917185202983742667185,
    0.0733464814110803057340336152531165181193,
    0.0733464814110803057340336152531165181193,
    0.0592985849154367807463677585001085845412,
    0.0592985849154367807463677585001085845412,
    0.0442774388174198061686027482113382288593,
    0.0442774388174198061686027482113382288593,
    0.0285313886289336631813078159518782864491,
    0.0285313886289336631813078159518782864491,
    0.0123412297999871995468056670700372915759,
    0.0123412297999871995468056670700372915759,
]

proc length*(curve: Bezier | DynBezier): float =
    ## 计算曲线的长度。计算开销较大，如果需要更快的版本，可以考虑使用 `approxLen`。
    # 函数名：length - 计算曲线长度（精确）
    result = 0
    when compiles(curve.derivative()):
        if curve.order > 0:
            const z = 0.5
            let deriv = curve.derivative()
            for i, tvalue in Tvalues:
                let t = z * tvalue + z
                let d = deriv.compute(t)
                let l = d.x * d.x + d.y * d.y
                result += Cvalues[i] * sqrt(l)
            result *= z

proc approxLen*(curve: Bezier | DynBezier, steps: Positive): float =
    ## 计算曲线的近似长度。这比直接调用 `length` 更快。
    # 函数名：approxLen - 计算曲线近似长度
    for (a, b) in curve.segments(steps):
        result += (b - a).length

proc lut*[T: Bezier | DynBezier](curve: T, steps: range[2..high(int)]): LUT[T] =
    ## 创建曲线的查找表，`steps` 是沿曲线采样的点数。
    # 函数名：lut - 创建查找表
    var distanceFrom0: float = 0.0
    result.table = newSeq[(float, Vec2, float)](steps)
    var previous: Vec2
    forIndexed(i, point, points(curve, steps)):
        if i > 0:
            distanceFrom0 += dist(previous, point.point)
        result.table[i] = (point.t, point.point, distanceFrom0)
        previous = point.point
    result.curve = curve

proc closest[T](lut: LUT[T], point: Vec2): int =
    ## 返回查找表上距离给定点最近的点索引
    # 函数名：closest - 查找最近点索引
    var distance = high(float)
    for i, (_, current, _) in lut.table:
        let currentDist = distSq(point, current)
        if currentDist < distance:
            distance = currentDist
            result = i

proc project*[T](lut: LUT[T], point: Vec2): float =
    ## 找到曲线上离给定点最近的位置。返回一个介于 0.0 和 1.0 之间的值，可传递给 `compute` 函数。
    # 函数名：project - 投影点至曲线
    let closestIdx = lut.closest(point)

    let tableLen = lut.table.len.float
    let t1 = (closestIdx - 1).float / tableLen
    let t2 = (closestIdx + 1).float / tableLen
    let step = 0.1 / tableLen


    # 精细检查
    var closestDist = distSq(lut.table[closestIdx].point, point) + 1
    var currentT = t1
    var closestT = currentT
    while currentT < t2 + step:
        let thisDistance = distSq(lut.curve.compute(currentT), point)
        if thisDistance < closestDist:
            closestT = currentT
            closestDist = thisDistance
        currentT += step

    return clamp(closestT, 0.0, 1.0)

proc approxLen*[T](lut: Lut[T]): float = lut.table[lut.table.len - 1].distanceFrom0
    ## 使用查找表确定曲线的近似长度。这有点不精确，但比调用 `length` 更快。
    # 函数名：approxLen - 使用 LUT 计算近似长度

iterator intervals*[T](lut: LUT[T], steps: Positive): Vec2 =
    ## 在曲线上生成几何上更均匀分布的点。不能保证完全均匀，但比使用 `segment` 更好。如果需要更高的精度，可以增加 LUT 的采样点数。
    ## 参数 `steps` 是要生成的间隔数，因此该迭代器将产生 `steps + 1` 个点。
    # 函数名：intervals - 迭代均匀间隔点
    let curveLen = lut.approxLen

    var pos = 0
    for i in 0..<steps:
        let targetDistance = i / steps * curveLen
        while lut.table[pos].distanceFrom0 < targetDistance: pos += 1
        yield lut.table[pos].point

    yield lut.table[lut.table.len - 1].point


when isMainModule:
    include bezier/cli
