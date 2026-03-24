import std/math, vmath, options

iterator cubicRoots(pa, pb, pc, pd: float): float =
    # 卡尔丹算法求根
    # 迭代器名：cubicRoots - 三次方程求根（卡尔丹公式）
    block earlyReturn:
        let a = 3 * pa - 6 * pb + 3 * pc
        let b = (-3 * pa + 3 * pb)
        let c = pa
        let d = -pa + 3 * pb - 3 * pc + pd

        # 检查是否需要三次求解：
        if d.almostEqual 0:
            # 不是三次曲线。

            if a.almostEqual 0:
                # 也不是二次曲线。

                if b.almostEqual 0:
                    # 无解。
                    break earlyReturn

                # 线性解
                yield -c / b
                break earlyReturn

            # 二次解
            let q = sqrt(b * b - 4 * a * c)
            yield (q - b) / (2 * a)
            yield (-b - q) / (2 * a)
            break earlyReturn

        # 此时，我们知道需要三次求解。

        let ad = a / d
        let bd = b / d
        let cd = c / d

        let p = (3 * bd - ad * ad) / 3
        let p3 = p / 3
        let q = (2 * ad * ad * ad  - 9 * ad * bd + 27 * cd) / 27
        let q2 = q / 2
        let discriminant = q2 * q2 + p3 * p3 * p3

        # 三个可能的实根：
        if discriminant < 0:
            let mp3 = -p / 3
            let r = sqrt(mp3 * mp3 * mp3)
            let t = -q / (2 * r)
            let cosphi = t.clamp(-1, 1)
            let phi = arccos(cosphi)
            let t1 = 2 * cbrt(r)
            yield t1 * cos(phi / 3) - ad / 3
            yield t1 * cos((phi + TAU) / 3) - ad / 3
            yield t1 * cos((phi + 2 * TAU) / 3) - ad / 3

        # 三个实根，但有两个相等：
        elif discriminant == 0:
            let u1 = if q2 < 0: cbrt(-q2) else: -cbrt(q2)
            yield 2 * u1 - ad / 3
            yield -u1 - ad / 3

        # 一个实根，两个复根
        else:
            let sd = sqrt(discriminant)
            let u1 = cbrt(sd - q2)
            let v1 = cbrt(sd + q2)
            yield u1 - v1 - ad/3

iterator computeRoots[N: static[int]](entries: array[N, float]): float =
    ## 计算给定点的根
    # 迭代器名：computeRoots - 计算根（根据阶数）
    when N > 4:
        {. error("Cannot calculate roots for N over 4") .}

    elif N == 4:
        for root in cubicRoots(entries[0], entries[1], entries[2], entries[3]):
            yield root

    elif N == 3:
        let a = entries[0]
        let b = entries[1]
        let c = entries[2]
        let d = a - 2 * b + c
        if d != 0:
            let m1 = -sqrt(b * b - a * c)
            let m2 = -a + b
            yield -(m1 + m2) / d
            yield -(-m1 + m2) / d
        elif b != c and d == 0:
            yield (2 * b - c) / (2 * (b - c))

    elif N == 2:
        let a = entries[0]
        let b = entries[1]
        if a != b:
            yield a / (a - b)

iterator roots*[N: static[int]](entries: array[N, float]): float =
    ## 计算给定点的根
    # 迭代器名：roots - 计算根（过滤有效区间）
    for root in computeRoots(entries):
        if root ~= 0:
            yield 0
        elif root ~= 1.0:
            yield 1.0
        elif root >= 0 and root <= 1:
            yield root

template yieldAll*(iter: untyped) =
    # 模板名：yieldAll - 展开迭代器中的所有值
    for value in iter: yield value

template forIndexed*(i, value, iter, exec: untyped) =
    # 模板名：forIndexed - 带索引遍历
    block:
        var i = 0
        for value in iter:
            exec
            i += 1

proc toArray[T](input: seq[T], N: static int): array[N, T] =
    # 函数名：toArray - 序列转数组
    for i in 0..<N: result[i] = input[i]

iterator roots*(entries: seq[float]): float =
    ## 计算给定点的根
    # 迭代器名：roots - 计算根（序列版本）
    assert(entries.len <= 4, "Can't yet calculate roots for N = " & $entries.len)
    if entries.len == 2: yieldAll(roots(entries.toArray(2)))
    elif entries.len == 3: yieldAll(roots(entries.toArray(3)))
    elif entries.len == 4: yieldAll(roots(entries.toArray(4)))

proc isOnLine*(point, p1, p2: Vec2): bool =
    # 返回 `point` 是否在 `p1` 和 `p2` 的连线上
    # 函数名：isOnLine - 判断点是否在线段上
    dist(p1, point) + dist(point, p2) == dist(p1, p2)

proc linesIntersect*(p1, p2, p3, p4: Vec2): Option[Vec2] =
    ## 返回两条直线的交点
    # 函数名：linesIntersect - 计算两条直线交点
    let d = (p1.x - p2.x) * (p3.y - p4.y) - (p1.y - p2.y) * (p3.x - p4.x)
    if d != 0:
        let nx = (p1.x * p2.y - p1.y * p2.x) * (p3.x - p4.x) - (p1.x - p2.x) * (p3.x * p4.y - p3.y * p4.x)
        let ny = (p1.x * p2.y - p1.y * p2.x) * (p3.y - p4.y) - (p1.y - p2.y) * (p3.x * p4.y - p3.y * p4.x)
        return some(vec2(nx / d, ny / d))

iterator forDistinct*[T](input: seq[T]): T =
    ## 遍历输入序列中的唯一值，假定已预先排序
    # 迭代器名：forDistinct - 遍历去重值（需预排序）
    var prev: Option[float]
    for value in input:
        assert(isNone(prev) or isSome(prev) and unsafeGet(prev) <= value, "Input must be sorted")
        if isNone(prev) or isSome(prev) and unsafeGet(prev) != value:
            yield value
        prev = some(value)

type DeCasteljau* {.byref.} = object
    ## 对一组点执行 de Casteljau 算法的结果
    # 类型名：DeCasteljau - de Casteljau 算法结果
    points: seq[Vec2]
    originalLen: Positive

proc deCasteljau*(points: openarray[Vec2], t: float): DeCasteljau =
    ## 使用 de Casteljau 算法确定曲线上 't' 的位置
    # 函数名：deCasteljau - 执行 de Casteljau 算法
    var buffer = newSeq[Vec2](points.len * (points.len + 1) div 2)

    # 用输入点填充缓冲区
    for i, value in points: buffer[i] = value

    var inputs = (start: 0, len: points.len)

    while inputs.len > 1:
        let newBlockStart = inputs.start + inputs.len
        for i in 0..<(inputs.len - 1):
            let pointIdx = inputs.start + i
            buffer[newBlockStart + i] = buffer[pointIdx] + (buffer[pointIdx + 1] - buffer[pointIdx]) * t
        inputs.len -= 1
        inputs.start = newBlockStart

    return DeCasteljau(points: buffer, originalLen: points.len)

proc finalPoint*(calculated: DeCasteljau): Vec2 = calculated.points[calculated.points.len - 1]
    ## 返回运行 de Casteljau 算法的计算结果
    # 函数名：finalPoint - 获取最终点

iterator left*(calculated: DeCasteljau): Vec2 =
    ## 生成分割曲线的左侧点集
    # 迭代器名：left - 获取左侧点集
    var index = 0
    for step in countDown(calculated.originalLen.int, 1):
        yield calculated.points[index]
        index += step

iterator right*(calculated: DeCasteljau): Vec2 =
    ## 生成分割曲线的右侧点集
    # 迭代器名：right - 获取右侧点集
    var index = calculated.points.len - 1
    for step in 1..calculated.originalLen:
        yield calculated.points[index]
        index -= step
