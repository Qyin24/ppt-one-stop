# ppt-one-stop

一站式 PPT 制作技能。用户说「帮我做个汇报 PPT」，它会**一步步问你需求、确认意向**，然后走完「调研 → 大纲 → 版面设计 → 生成 `.pptx`」的完整流程。

为 [DeepSeek Harness](https://github.com/deepseek-ai)（DSH）编写，也兼容其他读取 `SKILL.md` 的 Agent 工具（Codex 等）。

---

## 包含三个技能

| 技能 | 作用 |
|---|---|
| **`ppt-one-stop`** | **主角**。五步流水线编排 + 第 4 步版面设计规范（独有） |
| `ppt-content-generation` | 大纲方法论：SCQA、三幕式、演讲备注 |
| `ppt-visual-design` | 视觉方法论：配色、字体、留白 |

后两个是依赖项，**必须一起安装** —— `ppt-one-stop` 在第 3 步会加载前者定大纲，在视觉环节会加载后者定配色版式。

---

## 安装

### 方式一：让 DSH 帮你装（推荐）

把下面这句话发给对方的 DSH：

```
把 https://github.com/Qyin24/ppt-one-stop 安装到我的 DSH 里，装到 ~/.dsh/skills/ 和 ~/.agents/skills/
```

DSH 会自动克隆仓库、拷贝三个技能、校验 `SKILL.md` 格式，并报告安装位置。装完**无需重启**。

> 仓库地址已填好，直接复制即可。

### 方式二：跑安装脚本

克隆后执行：

```bash
# macOS / Linux
./install.sh

# Windows PowerShell
.\install.ps1
```

可指定其他仓库地址或先做演练：

```bash
./install.sh --repo https://github.com/Qyin24/ppt-one-stop.git
./install.sh --local ./ppt-one-stop-repo --dry-run
./install.sh --home /custom/path

.\install.ps1 -Repo https://github.com/Qyin24/ppt-one-stop.git
.\install.ps1 -LocalDir .\ppt-one-stop-repo -DryRun
.\install.ps1 -TargetHome C:\custom\path
```

> 默认安装到当前用户主目录下的 `.dsh/skills/` 和 `.agents/skills/`。

### 方式三：手动拷贝

把 `skills/` 下的三个目录复制到 `~/.dsh/skills/` 和 `~/.agents/skills/`：

```
~/.dsh/skills/ppt-one-stop/            # 主角，含 references/
~/.dsh/skills/ppt-content-generation/
~/.dsh/skills/ppt-visual-design/
```

---

## 前置条件

- **DSH** —— 第 5 步要用内置的 `office-pptx` 技能和 python-pptx 运行时，DSH 自带，无需另行安装
- 第 2 步的资料调研需要 `web_search` 可用；如果你自带数据文件，可以跳过

---

## 使用

装好后直接对 DSH 说：

```
帮我做个项目汇报 PPT
```

```
做一份给投资人看的商业计划演示
```

```
我要在周会上汇报季度数据，做 10 页左右
```

它会这样跟你走：

```
第 1 步  问 4 个问题：主题与核心目标 / 目标听众 / 场合与时长 / 页数
         ↓  确认点 A ——「这样对吗？」
第 2 步  查资料、核实数据、记录来源（不打断）
第 3 步  用 SCQA / 三幕式写大纲，逐页写标题、要点、演讲备注
         ↓  确认点 B ——「结构可以吗？哪几页要改？」
第 4 步  定每页配什么图/表/图表、字号层级、元素坐标
         ↓  确认点 C ——「版面这样安排行吗？」
第 5 步  生成 .pptx + 写入演讲备注 + 校验 + 渲染核对
         交付
```

说「**都你来定，不用问**」就会跳过三个确认点直接做完。

### 只想要其中一部分

| 你说 | 会用哪个技能 |
|---|---|
| 帮我列个 PPT 大纲 | `ppt-content-generation` |
| 这个 PPT 用什么配色好看 | `ppt-visual-design` |
| 帮我把这份 .pptx 改一下 | `office-pptx` |
| 帮我做个 PPT | **`ppt-one-stop`** |

---

## 它解决什么问题

| 常见问题 | 这里的做法 |
|---|---|
| 大纲有了但每页配什么图说不清 | 第 4 步的**版式决策表**：按表达意图（量级差异/时间趋势/构成占比…）查首选、备选、禁忌 |
| 字号层级随手定，投出去看不清 | 字号层级表，**硬下限 12pt**，相邻层级差 ≥4pt |
| 元素贴边、越界、重叠 | 12 列网格 + **安全框** `x∈[0.6667,12.6667]` `y∈[0.375,7.125]` + 11 个标准版式的精确坐标 |
| 中文字体设了不生效 | 记录了 python-pptx 必须注入 `<a:ea>` 的原因和写法 |
| 生成出来是 4:3 | 记录了 python-pptx 默认画布是 10×7.5in，必须显式设 `Emu(12192000)` |
| 演讲备注漏写 | 记录了 `check_office.py` **不读备注**，必须另跑抽查脚本 |

---

## 目录结构

```
ppt-one-stop-repo/
├── README.md
├── LICENSE
├── install.sh                  # macOS / Linux 安装脚本
├── install.ps1                 # Windows 安装脚本
└── skills/
    ├── ppt-one-stop/
    │   ├── SKILL.md                    # 五步流水线编排
    │   └── references/
    │       ├── layout-design.md        # 版面设计规范（本项目独有）
    │       └── deck-plan.md            # 逐页计划表 + 交接契约 + 验收清单
    ├── ppt-content-generation/
    │   └── SKILL.md
    └── ppt-visual-design/
        └── SKILL.md
```

---

## 卸载

删掉三个目录即可：

```bash
rm -rf ~/.dsh/skills/ppt-one-stop ~/.dsh/skills/ppt-content-generation ~/.dsh/skills/ppt-visual-design
rm -rf ~/.agents/skills/ppt-one-stop ~/.agents/skills/ppt-content-generation ~/.agents/skills/ppt-visual-design
```

```powershell
Remove-Item -Recurse -Force ~/.dsh/skills/ppt-one-stop, ~/.dsh/skills/ppt-content-generation, ~/.dsh/skills/ppt-visual-design
Remove-Item -Recurse -Force ~/.agents/skills/ppt-one-stop, ~/.agents/skills/ppt-content-generation, ~/.agents/skills/ppt-visual-design
```

---

## 排障

**技能不出现？**
- 确认目录层级是 `~/.dsh/skills/<技能名>/SKILL.md`，不是多套了一层
- 确认 `SKILL.md` 的 frontmatter 里有 `name`（**必须 kebab-case**，全小写用 `-` 分隔）和 `description`
- DSH 设置 → Skills 面板能看到技能列表和来源徽章

**名字改了但没变化？**
- 文件监听是即时的，正常不需要重启；若异常，重开会话

**生成的中文变成方框或字体不对？**
- 见 `layout-design.md` §2：必须注入 `<a:ea typeface="微软雅黑"/>`

**`.pptx` 打开报错？**
- 跑一遍 `office-pptx` 的 `check_office.py`，它会检查 ZIP/XML 完整性

---

## 许可

MIT，见 [LICENSE](LICENSE)。