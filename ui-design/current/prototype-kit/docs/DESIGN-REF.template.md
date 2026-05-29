# 〈项目名〉设计规范 · AI 速查手册（DESIGN-REF）

> 本文件是**给 AI / 开发快速复用的索引**，不是给人看的展示文档（展示见 `〈设计规范〉.html`）。
> **复用任何组件前先读本文件**：直接抄类名与最小 HTML 片段，不必重读 CSS。
> 黄金规则：**只引用 `var(--*)`，绝不写死颜色 / 字号 / 间距**；改完若定档，按 `CHANGELOG.md` 规矩记录。

## 文件结构
```
项目根/
├── CLAUDE.md             # 项目说明（必须在根目录，自动加载）
├── docs/
│   ├── DESIGN-REF.md     # 本文件 · AI 速查
│   ├── PROTOTYPE-ARCH.md # 页面原型架构（来自 prototype-kit）
│   └── CHANGELOG.md      # 更新日志（按天 + 模块标签）
├── 〈设计规范目录〉/
│   ├── 〈设计规范〉.html   # 人看的展示文档（含实时主题/明暗切换）
│   └── assets/
│       ├── tokens.css    # 所有设计变量（唯一真源）
│       └── spec.css      # 布局 + 组件样式
└── pages/                # 页面设计（原型 + 画布双呈现，来自 prototype-kit）
```

## Token 速查
> 数值唯一真源在 `tokens.css`；下表只做语义索引。改了 tokens.css 必须同步本表。

### 颜色（中性 · 随 data-mode）
| token | 语义 |
|---|---|
| `--bg` / `--bg-2` | 页面底 / 次级底 |
| `--surface` / `--surface-2` | 卡片面 / 次级面 |
| `--ink` / `--ink-2` / `--ink-3` / `--ink-4` | 正文 / 次要 / 占位 / 极弱 |
| `--hairline` / `--hairline-2` | 分隔线 / 次级线 |

### 颜色（强调 · 随 data-theme + data-mode）
| token | 语义 |
|---|---|
| `--accent` | 主强调（按钮/选中/链接） |
| `--accent-strong` | 加重强调 |
| `--accent-soft` / `--accent-soft-2` | 浅底/更浅底 |
| `--accent-ink` | 强调底上的文字 |
| `--on-accent` | 实色强调上的文字 |

### 字体 / 间距 / 圆角 / 阴影
| 类别 | token | 说明 |
|---|---|---|
| 字体 | `--font-sans` / `--font-serif` / `--font-mono` | UI / 正文 / 等宽 |
| 间距 | `--sp-1`…`--sp-16` | 4px 基准 |
| 圆角 | `--r-xs`…`--r-xl` / `--r-full` | |
| 阴影 | `--shadow-sm` / `--shadow-md` / `--shadow-lg` | |

## 组件目录
> 每个可复用组件一条：类名 + 一句用途 + 最小 HTML。**没登记的组件视为临时草稿。**

### 〈组件名示例：按钮〉
〈用途〉
```html
<button class="〈类名〉">…</button>
```

<!-- 按此格式继续追加组件 -->

## 图标与贡献约定
- 图标：〈线性/填充、stroke-width、来源库〉。
- 新增组件先在本目录登记（类名 + 最小 HTML），再写进 CHANGELOG。
