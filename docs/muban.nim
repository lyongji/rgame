## nimib 快速模板：带目录的文档
import nimib, std/[strutils, strformat, json]

nbInit
# nb.darkMode
# ---------- 目录相关 ----------
var
  nb目录: NbText   # 存储目录的文本块

template add目录 =
  nb目录 = newNbText(text = "# 目录：\n\n")
  nb.add nb目录

# ---------- 带目录的标题 ----------
template nb段落(heading: string) =
  ##   nb段落 "# 一级标题"
  let titleText = heading.strip(chars = {'#'}).strip()      # 提取纯文本
  let anchorName = titleText.toLower.replace(" ", "-")      # 锚点 ID
  nbText "<a name=\"" & anchorName & "\"></a>\n" & heading & "\n\n---"
  nb目录.text.add "1. <a href=\"#" & anchorName & "\">" & titleText & "</a>\n"

# ========== 文档正文从这里开始 ==========
add目录()
# 示例：
nb段落 "# 简介"
nbText "这里是一些普通文本。"
nb段落 "## 安装"
nbText """
- 方式
----
[图片]: ../src/test.png "测试图片"

![测试图片](../src/test.png)
![链接2][图片]

"""

nb段落 "### 用法"
nbText "更多内容……"

nbSave
