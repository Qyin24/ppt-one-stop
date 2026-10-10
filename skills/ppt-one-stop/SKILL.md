---
name: ppt-one-stop
description: 当用户需要制作PPT、演示文稿、幻灯片、汇报材料时使用。覆盖从需求澄清、资料调研、大纲撰写、版面设计到生成 .pptx 文件的一站式完整流程，与用户逐步确认意向。当用户只说"做PPT""汇报一下""做份演示"而未指明只要大纲或只要配色设计时，优先使用本技能。
version: 1.0.0
whenToUse: 用户要一份完整的演示文稿成品（.pptx），需要从需求到成品走完整流程；若用户只要大纲或演讲稿用 ppt-content-generation，只要配色排版建议用 ppt-visual-design，修改已有 .pptx 用 office-pptx。
---

# PPT 一站式制作

把「做一份 PPT」从一句话变成一个可交付的 `.pptx` 文件。

## 角色定位

本技能是**编排器**，不生产方法论。三个环节各有权威来源：

| 环节 | 权威来源 | 说明 |
|---|---|---|
| 大纲 / 演讲稿 / 叙事逻辑 | **`ppt-content-generation`** | SCQA、三幕式、金字塔原理、演讲备注规范 |
| 配色 / 字体 / 视觉风格 | **`ppt-visual-design`** | 配色方案、字体搭配、留白原则 |
| 生成 / 读写 .pptx | **`office-pptx`** | python-pptx 用法、check_office.py、渲染核对 |

**第 4 步「版面设计」由本技能独有** —— 逐页决定配什么图/表/图表、用什么版式、字号取多少、元素落在哪里。这块规范见 `references/layout-design.md`，另两个技能都没有。

> 三个原技能保持独立可用，本技能只做编排与衔接，不复制它们的内容。

### 触发消歧

| 用户诉求 | 交给谁 |
|---|---|
| 只要大纲 / 演讲稿 / 逻辑结构 | `ppt-content-generation` |
| 只要配色 / 排版建议 / 设计评审 | `ppt-visual-design` |
| 已有 .pptx 要改内容或查结构 | `office-pptx` |
| **要一份完整成品** | **本技能** |

---

## 核心原则：先问再做

用户说「做个 PPT」时，**第一件事是发问，不是沉默开工**。

用 `ask_user_question` 给带选项的问题，用户点选即可，也保留自由输入。全程在 **3 个确认点**停下等回复，其余步骤不打断。

### 用户豁免

用户说「都你来定」「不用问，直接开干」时，**跳过全部确认点**，全程不打断，只在交付说明中列出所有假设。

---

## 五步流水线

### 第 1 步 · 需求澄清

用 `ask_user_question` 一次问 4 项：

1. **PPT 的主题和核心目标**（文字题）—— 说什么、想让听众记住什么
2. **目标听众**（选项题）—— 公司管理层 / 客户或投资人 / 团队同事 / 老师学生 / 公开演讲
3. **场合与时长**（选项题）—— 5 分钟快闪 / 10-15 分钟常规汇报 / 20-30 分钟深度汇报 / 40 分钟以上培训
4. **页数**（选项题）—— 6-8 页精简 / 10-12 页标准 / 15-20 页详细

同时确认：有没有必须包含的内容？有没有现成的数据文件或图片素材？交付 `.pptx` 还是要 PDF？

**产出**：一份需求卡（主题 / 受众 / 时长 / 页数 / 素材情况）。

#### 确认点 A

复述你的理解，并把资料来源方式说清楚（用户自带 vs 我用 `web_search` 查），然后问「这样对吗，有没有要补的必含内容」。

用户确认后进入第 2 步。

---

### 第 2 步 · 资料调研

- 用户提供了文件就直接读；没有就用 `web_search` 查。
- **每个进入 PPT 的数字必须带来源**，来源记下来，最后汇总到末页「数据来源」和图表页脚注。
- 查不到关键数据时**不编造**：把该页改成定性对比表述，或明确标注「示意数据」并告知用户。

**中间不打断**。用户在你调研途中补充信息，正常接收并在后续步骤中并入。

---

### 第 3 步 · 大纲撰写

**加载 `ppt-content-generation` 技能**，按它的方法论执行：

- 用 SCQA 或三幕式定整体结构（开场 10% / 主体 70% / 结尾 20%）。
- 标题写成结论式（「华东贡献 62% 增量」而非「区域分析」）。
- 逐页给出：页码 / 标题 / 核心信息 / 要点 / 演讲备注 / 预计时长。
- 演讲备注按它的规范写（时间 + 重点 + 语气 + 技巧）。

**产出**：完整逐页大纲。

#### 确认点 B

把大纲给用户看，问「结构可以吗，哪几页要调整」。

- 用户否决 → 回到第 3 步重写，再次确认。**不带旧大纲进入第 4 步。**
- 用户改需求 → 联动重跑第 4 步。

---

### 第 4 步 · 版面设计

**读 `references/layout-design.md`**，逐页定：

- **版式代号** —— `COVER` / `SECTION` / `BULLETS-3|4|5` / `SPLIT-60-40` / `SPLIT-50-50` / `CHART-HERO` / `TABLE` / `QUOTE` / `CLOSING`
- **视觉类型** —— `none` / `text` / `chart` / `table` / `image` / `quote`
- **字号层级** —— 按规范的层级表取值
- **坐标** —— 按规范对应版式的坐标表

选视觉形态时用 `references/layout-design.md` §4 的**版式决策表**（按表达意图查首选/备选/禁忌）。

**产出**：填满 `references/deck-plan.md` §1 的逐页计划表。

#### 确认点 C

按 `references/deck-plan.md` §5 的紧凑格式把计划表给用户看，问「版面这样安排行吗」。

- 用户否决 → 回到第 4 步重排。
- 用户确认后进入第 5 步。

---

### 第 5 步 · 生成 .pptx

**加载 `office-pptx` 技能**，用 `load_workspace_dependencies` 返回的 Python + python-pptx 生成。

生成脚本写在会话工作目录 `output/<deck-name>/build_deck.py`，按第 4 步的坐标落形状。

#### 交接要点（易错，实测确认）

**1. 必须显式设画布** —— python-pptx 默认是 4:3：

```python
from pptx.util import Emu
prs.slide_width  = Emu(12192000)   # 13.333in，不要用 Inches(13.333)
prs.slide_height = Emu(6858000)    # 7.5in
```

**2. 中文字体必须注入 `<a:ea>`** —— `run.font.name` 只写 `<a:latin>`，中文字符不生效：

```python
from pptx.oxml.ns import qn
rPr = run._r.get_or_add_rPr()
rPr.append(rPr.makeelement(qn('a:ea'), {'typeface': '微软雅黑'}))
```

**3. 空白版式** —— 用 `slide_layouts[6]`；换新模板时先确认该索引仍是空白版式。

**4. 演讲备注**：

```python
slide.notes_slide.notes_text_frame.text = "备注内容"
```

**5. 图表用原生对象** —— `add_chart` 写入真实数据，保留可编辑的嵌入工作簿，不贴图片。

**6. 交付前跑两个检查**：

```text
<python> <skill-directory>/../scripts/check_office.py <deck>.pptx --contains "关键标题" --count <页数> --out checks.json
```

`check_office.py` **不读演讲备注**（只存在于备注的文本不会通过 `--contains`）。必须另跑备注抽查：

```python
from pptx import Presentation
p = Presentation("<deck>.pptx")
missing = [i for i, s in enumerate(p.slides, 1) if not s.notes_slide.notes_text_frame.text.strip()]
print("缺备注页:", missing)   # 期望 []
```

**7. 渲染核对** —— 按 `office-pptx` 的说明用 bundled LibreOffice 渲染图片，逐页检查溢出、遮挡、裁切，再跑 `references/deck-plan.md` §4 的验收清单。

**中间不打断**，完成后一次性汇报。

---

## 边界与失败模式

| 情况 | 处理 |
|---|---|
| 用户说「都你来定/不用问」 | 跳过全部确认点，不打断，只在交付说明列假设 |
| 用户中途改需求 | 回到对应步骤，**联动重跑受影响的后续步骤**（改大纲 → 版面计划作废重做） |
| 关键数据查不到 | 不编造：改定性对比页，或明示标注「示意数据」并告知用户 |
| 需要图片但无素材且不能生图 | 改选无图版式，在交付说明说明原因，**页面内不留占位提示文字** |
| 页数超出时长 | 压缩正文，超出的移入附录页；附录不计入正文页数 |
| 大纲被否决 | 回第 3 步重写再确认，不带旧大纲下行 |
| 版面被否决 | 回第 4 步重排 |
| 渲染发现溢出/遮挡 | 改该页文案或降字号一档（不低于 12pt）；版面本身不合适则换版式代号 |
| python-pptx 不支持的特性 | 记录限制并说明，不谎称完全保真 |
| 用户要 PDF | 附加产物，用 `office-pptx` 提供的 bundled LibreOffice `convert` 生成，不另找系统 soffice |

---

## 资源索引

| 文件 | 内容 |
|---|---|
| `references/layout-design.md` | 画布与安全边距、12 列网格、字号层级、元素间距、版式决策表、标准版式坐标表、检查清单 |
| `references/deck-plan.md` | 逐页计划表模板、版式代号表、交接契约、验收清单、确认点 C 呈现格式 |