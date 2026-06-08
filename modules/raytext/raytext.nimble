# RayText — Nim 中文文本渲染模块
# 基于 raylib，支持 CJK / Unicode，动态按需加载字形

version       = "0.1.0"
author        = "lyj"
description   = "基于 raylib 的中文/Unicode 文本渲染模块，支持按需动态加载字形"
license       = "MIT"
srcDir        = "."
skipDirs      = @["examples", "tests"]

requires "nim >= 2.2.0"
requires "naylib >= 25.42.0"
