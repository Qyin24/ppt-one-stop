# 高级视觉规范 · 默认生成标准

**这是 `ppt-one-stop` 的默认视觉档位。** 除用户明确要求「简洁/朴素/白底」外，一律按本文件执行。

本文件定义**怎么让 PPT 看起来贵**。选什么图、写什么结论，是 `layout-design.md` 的职责；两者配合使用。

所有数值都是确定值，已在 python-pptx 1.0.2 上实测通过。

---

## 1. 设计令牌（照抄，不要现选）

```python
# ── 主色阶 ──
INK      = RGBColor(0x14, 0x1C, 0x2E)   # 主文本，近黑蓝
PRIMARY  = RGBColor(0x0A, 0x24, 0x63)   # 海军蓝，主色 / 深色块底
PRIMARY2 = RGBColor(0x1B, 0x4F, 0xA8)   # 亮蓝，图表主色 / 强调
CYAN     = RGBColor(0x4E, 0x9F, 0xD9)   # 天蓝，第三级 / 渐变末端
GOLD     = RGBColor(0xC9, 0xA2, 0x27)   # 金，封面点缀 / 数字徽章

# ── 功能色 ──
CORAL    = RGBColor(0xE0, 0x54, 0x4B)   # 警示红，负值 / 高风险 / 核心数字
MUTED    = RGBColor(0x64, 0x74, 0x8B)   # 次要灰
FAINT    = RGBColor(0x94, 0xA3, 0xB8)   # 辅助浅灰

# ── 表面 ──
CARD_BRD = RGBColor(0xE2, 0xE8, 0xF0)   # 卡片描边
ON_DARK  = RGBColor(0xE8, 0xEE, 0xF7)   # 深底上的正文
ON_DARK2 = RGBColor(0xA8, 0xBC, 0xD8)   # 深底上的次要信息
WHITE    = RGBColor(0xFF, 0xFF, 0xFF)

# ── 字体 ──
FONT_T = "微软雅黑"   # 标题（Bold）
FONT_B = "微软雅黑"   # 正文
```

**配色纪律**
- 全篇只用一个色相家族（默认蓝），靠明度分层，不靠换色相。
- 强调色（金 / 红）**每页最多出现一次**，用于把视线钉在唯一重点上。
- 深色页只放标题和数字，不放正文段落。

---

## 2. 背景（分两种，按页型切换）

### 2.1 深色背景 —— 封面 / 章节页 / 结尾页

预渲染一张 1920×1080 PNG，铺满画布。用 numpy 算渐变 + Pillow 加质感：

```python
import numpy as np
from PIL import Image, ImageDraw

W, H = 1920, 1080

def mesh(w, h, c1, c2, tilt=0.6):
    """双向线性渐变网格，tilt 控制左上→右下的倾斜权重。"""
    yy, xx = np.mgrid[0:h, 0:w]
    t = np.clip((xx / w) * tilt + (yy / h) * (1 - tilt), 0, 1)
    c1, c2 = np.array(c1, float), np.array(c2, float)
    return (c1[None, None, :] * (1 - t[..., None])
            + c2[None, None, :] * t[..., None]).astype(np.uint8)

def glow(arr, cx, cy, r, color, strength=0.30):
    """叠加径向光晕。"""
    h, w = arr.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    d = np.sqrt(((xx - cx) / r) ** 2 + ((yy - cy) / r) ** 2)
    f = np.clip(1 - d, 0, 1) ** 2
    c = np.array(color, float) * strength
    return np.clip(arr + f[..., None] * c[None, None, :], 0, 255).astype(np.uint8)

# 深色底：海军蓝渐变 + 双光晕 + 细网格
bg = mesh(W, H, (8, 24, 56), (16, 54, 104), tilt=0.6)
bg = glow(bg, int(W * 0.78), int(H * 0.22), 760, (60, 120, 200), 0.30)
bg = glow(bg, int(W * 0.15), int(H * 0.88), 620, (20, 80, 150), 0.22)
img = Image.fromarray(bg)

# 细网格质感（alpha ≤ 12，只加纹理不抢视线）
layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(layer)
for x in range(0, W, 64):
    d.line([(x, 0), (x, H)], fill=(255, 255, 255, 9), width=1)
for y in range(0, H, 64):
    d.line([(0, y), (W, y)], fill=(255, 255, 255, 9), width=1)
img = Image.alpha_composite(img.convert("RGBA"), layer).convert("RGB")

# 左下角一道细金线
ImageDraw.Draw(img).rectangle([0, H - 6, int(W * 0.34), H], fill=(212, 175, 55))
img.save("assets/bg_dark.png")
```

### 2.2 浅色背景 —— 所有正文页

```python
bg2 = mesh(W, H, (250, 251, 253), (232, 238, 248), tilt=0.75)
bg2 = glow(bg2, int(W * 0.12), int(H * 0.10), 700, (255, 255, 255), 0.55)
img2 = Image.fromarray(bg2)
# 极淡网格（深色，alpha ≤ 6）
layer2 = Image.new("RGBA", (W, H), (0, 0, 0, 0))
d2 = ImageDraw.Draw(layer2)
for x in range(0, W, 80):
    d2.line([(x, 0), (x, H)], fill=(10, 36, 99, 5), width=1)
for y in range(0, H, 80):
    d2.line([(0, y), (W, y)], fill=(10, 36, 99, 5), width=1)
img2 = Image.alpha_composite(img2.convert("RGBA"), layer2).convert("RGB")
img2.save("assets/bg_light.png")
```

### 2.3 半透明装饰 —— 正文页右侧

用 Pillow 画几何拼接，**只叠在正文页右半侧**，alpha ≤ 26。目的是打破空白，不是当主体。

```python
motif = Image.new("RGBA", (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(motif)
d.polygon([(int(W*0.62), 0), (W, 0), (W, int(H*0.46))], fill=(10, 36, 99, 26))
d.polygon([(int(W*0.74), int(H*0.30)), (W, int(H*0.10)),
           (W, int(H*0.72)), (int(W*0.86), H)], fill=(78, 159, 217, 20))
d.ellipse([int(W*0.88), int(H*0.62), int(W*1.02), int(H*0.92)], fill=(212, 175, 55, 16))
motif.filter(ImageFilter.GaussianBlur(1.2)).save("assets/motif.png")
```

### 2.4 铺底要放进最底层

`add_picture` 默认加在形状栈顶，会盖住文字。必须手动下移：

```python
def bg(slide, path, prs):
    pic = slide.shapes.add_picture(path, 0, 0, prs.slide_width, prs.slide_height)
    slide.shapes._spTree.remove(pic._element)
    slide.shapes._spTree.insert(2, pic._element)   # 2 = nvGrpSpPr 之后，即最底层
    return pic
```

---

## 3. 卡片系统

正文页承载内容的默认容器。**卡片是高级感的主要来源**。

### 3.1 参数

| 属性 | 值 |
|---|---|
| 圆角 | `adjustments[0] = 0.055`（小圆角，别做成胶囊） |
| 填充 | `WHITE` |
| 描边 | `CARD_BRD`，`Pt(0.75)` |
| 投影 | blur 22px / dist 7px / dir 90° / alpha 13% |
| 阴影色 | `0A1F3D` |

### 3.2 实现

python-pptx 没有投影 API，必须注入 XML：

```python
from lxml import etree
A = "{http://schemas.openxmlformats.org/drawingml/2006/main}"

def shadow(shape, blur=22, dist=7, alpha=13, color="0A1F3D"):
    eff = etree.SubElement(shape._element.spPr, A + 'effectLst')
    sh = etree.SubElement(eff, A + 'outerShdw')
    sh.set('blurRad', str(int(blur * 12700)))   # px → EMU，1px = 12700 EMU
    sh.set('dist',   str(int(dist * 12700)))
    sh.set('dir',    '5400000')                 # 5400000 = 90° 向下
    sh.set('rotWithShape', '0')
    c = etree.SubElement(sh, A + 'srgbClr'); c.set('val', color)
    al = etree.SubElement(c, A + 'alpha'); al.set('val', str(int(alpha * 1000)))

def card(slide, x, y, w, h, fill=WHITE, radius=0.055, brd=CARD_BRD):
    sh = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE,
                                Inches(x), Inches(y), Inches(w), Inches(h))
    sh.adjustments[0] = radius
    sh.fill.solid(); sh.fill.fore_color.rgb = fill
    if brd is None:
        sh.line.fill.background()
    else:
        sh.line.color.rgb = brd; sh.line.width = Pt(0.75)
    sh.shadow.inherit = False        # 必须先关掉主题默认阴影
    shadow(sh)
    return sh
```

> `sh.shadow.inherit = False` 要在 `shadow()` 之前调用，否则会被主题样式覆盖。

### 3.2b 两个基础绘制函数

卡片、色条、竖条、徽章、文字全部由这两个函数生成。**整个 deck 不要再用裸 `add_textbox` / `add_shape`**。

```python
def bar(slide, x, y, w, h, color, radius=None):
    """色条。radius=None 出直角；给 0.5 出胶囊（用于竖条、徽章、分隔线）。"""
    shape = MSO_SHAPE.ROUNDED_RECTANGLE if radius else MSO_SHAPE.RECTANGLE
    sh = slide.shapes.add_shape(shape, Inches(x), Inches(y), Inches(w), Inches(h))
    if radius:
        sh.adjustments[0] = radius
    sh.fill.solid(); sh.fill.fore_color.rgb = color
    sh.line.fill.background(); sh.shadow.inherit = False
    return sh


def tb(slide, x, y, w, h, anchor=None):
    """文字框。边距归零——默认值会让所有元素比坐标右移 0.1in，是最常见的错位来源。"""
    box = slide.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h))
    tf = box.text_frame
    tf.word_wrap = True
    tf.margin_left = tf.margin_right = Inches(0.02)
    tf.margin_top = tf.margin_bottom = 0
    if anchor:
        tf.vertical_anchor = anchor
    return box, tf


def cn(run, text, size, bold=False, color=INK, font=FONT_B, italic=False):
    """写中文 run。必须注入 <a:ea>，否则中文回退到主题字体。"""
    run.text = text
    f = run.font
    f.size, f.bold, f.italic = Pt(size), bold, italic
    f.color.rgb = color
    f.name = font
    run._r.get_or_add_rPr().append(run._r.makeelement(qn('a:ea'), {'typeface': font}))
```

### 3.3 三等分布局（最容易算错，务必按公式）

**不要硬编卡片宽度。** 按下式算：

```
安全框净宽 = 11.9999 in
N 张卡片、gutter g：单张宽 w = (11.9999 − (N−1) × g) / N
第 i 张起点 = 0.6667 + i × (w + g)
```

| N | gutter | 单张宽 w | 起点间隔 |
|---|---|---|---|
| 2 | 0.20 | 5.9000 | 6.1000 |
| 3 | 0.20 | 3.8666 | 4.0666 |
| 4 | 0.20 | 2.8500 | 3.0500 |

> **反面案例**：硬编 `w = 3.85`、间距 `4.05`。算下来第三张右缘 = `0.6667 + 2×4.05 + 3.85 = 12.617`，
> 比右安全边界 `12.6667` 少 0.05in，右侧留白比左边窄，肉眼可见地"没对齐"。
> 正确值是 `w = 3.8666`，右缘 `12.6665`。

### 3.4 卡片内的强调竖条

卡片左侧压一条彩色竖条，是让卡片"有重点"的低成本手法：

```python
bar(slide, x + 0.30, y, 0.055, h, color, radius=0.5)   # radius 拉满 = 胶囊
```

竖条颜色取该卡片的语义色（`CORAL` 表核心数字，`PRIMARY2` 表常规，`CYAN` 表补充）。

---

## 4. 图表样式（原生 add_chart，必配）

### 4.1 统一样式函数

```python
def style_chart(chart, series_colors, labels=True, label_size=11, gap=55):
    chart.has_legend = False          # 单系列图例是冗余信息
    chart.font.size = Pt(11)
    chart.font.name = FONT_B
    chart.font.color.rgb = MUTED

    plot = chart.plots[0]
    plot.gap_width = gap               # 条间距，55–80 之间，别用默认 150（太散）
    plot.vary_by_categories = False    # 否则单系列会按类目变色，破坏配色

    for ser, col in zip(plot.series, series_colors):
        ser.format.fill.solid()
        ser.format.fill.fore_color.rgb = col
        ser.format.line.fill.background()

    if labels:
        plot.has_data_labels = True
        dl = plot.data_labels
        dl.font.size = Pt(label_size)
        dl.font.bold = True
        dl.font.color.rgb = INK
        dl.font.name = FONT_B
        dl.position = XL_LABEL_POSITION.OUTSIDE_END
        dl.number_format = '0'
        dl.number_format_is_linked = False   # 必须设，否则自定义格式被主题覆盖

    # 网格线：淡到几乎看不见，只留横向参考线
    va = chart.value_axis
    va.has_major_gridlines = True
    va.major_gridlines.format.line.color.rgb = RGBColor(0xEC, 0xF0, 0xF5)
    va.major_gridlines.format.line.width = Pt(0.75)
    va.format.line.fill.background()
    va.tick_labels.font.size = Pt(10)
    va.tick_labels.font.color.rgb = FAINT

    ca = chart.category_axis
    ca.format.line.color.rgb = RGBColor(0xCB, 0xD5, 0xE1)
    ca.tick_labels.font.size = Pt(12)
    ca.tick_labels.font.color.rgb = MUTED
```

### 4.2 图表页布局（7.9 + 3.95 分栏）

图表不要通栏。**图表 7.9in + 右侧解读卡 3.95in**，中间 0.15 gutter：

| 元素 | left | top | width | height |
|---|---|---|---|---|
| 图表 | 0.6667 | 1.92 | 7.90 | 4.42 |
| 解读卡 | 8.72 | 1.92 | 3.95 | 4.42 |

解读卡里放 3 条「读图要点」，每条一个粗体数字/关键词 + 一句解释。这是把图表从"数据罗列"变成"论证"的关键。

### 4.3 matplotlib 不可用

DSH 运行时**没有装 matplotlib**，画图只能用原生 `add_chart`。这不是缺陷——原生图表带内嵌工作簿，收件人能在 PowerPoint 里直接改数据。

样式能力上限：单系列配色、数据标签、gap_width、网格线、轴样式。多系列堆叠、趋势线、自定义标注不支持，此时改用表格。

---

## 5. 表格样式

| 部位 | 样式 |
|---|---|
| 表头行 | `PRIMARY` 底纹 + `WHITE` Bold 13pt |
| 数据行 | 隔行 `WHITE` / `F7FAFC` 交替 |
| 行高 | 0.88in（不要低于 0.72in，否则中文换行撑破） |
| 单元格内边距 | 左右 ≥0.16in，上下 ≥0.06in |
| 垂直对齐 | `MIDDLE`（枚举值 3） |
| 语义列 | 风险等级等列按值配色：`高` → `CORAL`，`中` → `GOLD` |

```python
cell.vertical_anchor = 3      # MSO_ANCHOR.MIDDLE
cell.margin_left = Inches(0.16)
cell.margin_top = cell.margin_bottom = Inches(0.06)
```

---

## 6. 深色页排版规则

封面 / 章节 / 结尾页：

- 左侧压一条金色竖条：`bar(slide, 0, 0, 0.16, 7.5, GOLD)`
- 小标签（`PRODUCT · STRATEGY · 2026`）用 `GOLD` 12pt，位于主标题上方 0.46in
- 主标题 `WHITE` Bold 44–54pt
- 副标题 `ON_DARK` 18–21pt
- 短分隔线 `GOLD`，宽 1.8–2.2in，高 0.035in
- 底部可放 3 组 KPI：`WHITE` Bold 26pt 数字 + `ON_DARK2` 12pt 标签

**封面底部留白**：`y = 6.34` 放落款，`y = 5.06–5.90` 放 KPI。不要把 KPI 压到 `y > 6.0`，会贴到安全边界。

---

## 7. 常见失败与对策

| 现象 | 原因 | 对策 |
|---|---|---|
| 背景盖住文字 | `add_picture` 默认加在栈顶 | `spTree.insert(2, pic._element)` 推到最底层 |
| 卡片没有投影 | 主题默认阴影覆盖了注入的 `effectLst` | `sh.shadow.inherit = False` 放在 `shadow()` 之前 |
| 中文变成方框 | 只写了 `<a:latin>` | 额外注入 `<a:ea typeface="微软雅黑"/>` |
| 卡片右侧看着没对齐 | 硬编宽度，不是栅格算出来的 | 用 §3.3 公式重算 |
| 数据标签不生效 / 格式丢失 | 主题覆盖 | `number_format_is_linked = False` |
| 单系列图每个类目颜色不同 | `vary_by_categories` 默认 True | 显式设 `False` |
| 标题被裁 | 页脚带做到 0.25in 高 | 页脚 `height = 0.15in`（见 `layout-design.md` §1） |
| 预览图看着被裁右边 | 对话界面图片缩放造成的错觉 | **量坐标**：`check_bounds.py` 报告 0 越界就是真没问题 |

> 最后一条尤其重要：**肉眼判断不可靠，量坐标才可靠**。生成后必须跑越界检测。

---

## 8. 最低交付门槛

生成后逐项确认，任何一项不过就返工：

- [ ] 深色页用了 `bg_dark.png`，正文页用了 `bg_light.png`
- [ ] 正文页右侧叠了 `motif.png`（可省，但省了就要留白干净，不能一半装饰一半空）
- [ ] 每张卡片都有投影，且圆角 ≤0.06
- [ ] 所有图表调用了 `style_chart()`
- [ ] 强调色每页最多出现一次
- [ ] 越界检测报告 **0 越界**
- [ ] 备注页齐全（`check_office.py` 不读备注，必须单独查）
