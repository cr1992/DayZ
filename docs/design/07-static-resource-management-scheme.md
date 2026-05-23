# 07-静态资源管理方案

## 1. 静态资源类型安全管理

在 Flutter 项目中，内置的静态资源（如图片、图标、字体、本地 Web 网页等）如果通过硬编码字符串引用（如 `Image.asset('assets/images/logo.png')`）极易引发拼写错误，且无法在重构时通过静态分析发现问题。

为解决此痛点，采用 **`flutter_gen`** 自动生成类型安全的资源引用代码。

*   **配置**：在 `pubspec.yaml` 中添加 `flutter_gen_runner` 依赖。
*   **使用方式**：执行代码生成命令 `dart run build_runner build`，自动生成 `lib/gen/assets.gen.dart` 文件。
*   **应用效果**：在代码中使用强类型的类引用，例如 `Assets.images.logo.image()`，使得开发过程获得 IDE 的全自动补全和编译期的类型检查支持。

## 2. 资源目录结构规范

为了维持工程结构的清晰，所有应用层级的内置资源统一组织在根目录下的 `assets/` 中，并严格按以下子目录分类管理：

```text
assets/
├── editor/               # 富文本编辑器 WebView 依赖的本地静态网页 (TipTap HTML/JS/CSS)
├── fonts/                # 字体文件 (.ttf)
├── icons/                # 自定义单色或多色图标 (推荐 SVG 格式)
├── images/               # 静态图片/插画 (PNG / JPG / WEBP)
│   ├── welcome_bg.png    # 默认 1.0x 尺寸
│   ├── 2.0x/
│   │   └── welcome_bg.png  # 2.0x 屏幕适配
│   └── 3.0x/
│       └── welcome_bg.png  # 3.0x 屏幕适配
└── lotties/              # 动效文件 (如有需要)
```

## 3. 图标与矢量图规范

*   **多色图标与复杂插图**：优先使用 **SVG** 格式，并搭配 `flutter_svg` 库进行解析加载。SVG 支持无损缩放，能够大幅减小包体积。
*   **单色系统级图标（Icon Font）**：对于基础操作图标（如返回、设置、编辑、日历等），建议通过类似 `FlutterIcon.com` 的工具，将一组 SVG 打包为一个单独的 **`.ttf` 字体文件**。这比加载零散的 SVG 文件更省空间，并能像普通的 `IconData` 一样通过代码灵活变更颜色与大小。

## 4. 包体积优化策略

日记 App 对包体积（APK/IPA）比较敏感，应严格控制 Assets 大小：
*   所有图片资源（PNG、JPG）在入库前，必须经过图片无损压缩工具（如 TinyPNG, image_optim 等）进行压缩。
*   只有需要高精细度呈现的大型背景图或插画，才放入 `2.0x/` 和 `3.0x/` 目录；普通的图标必须全部矢量化处理（SVG 或 Icon Font），以避免提供多套多倍率图片造成体积膨胀。
*   动效避免使用传统的 GIF 格式，推荐采用基于矢量的 Lottie (JSON) 或 Rive 格式，不仅体积小，渲染质量也更高。
