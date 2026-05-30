# DayZ · App Icon 导出（B · 暖纸底 · 雾紫 Lavender）

方案：**B · 暖纸底** —— 暖白纸渐变 + 雾紫 `#786CAD` 描边书签本。
描边/书签强调色 = `#786CAD`，底为 `#FFFFFF → #FAF7F1 → #F4EFE6` 暖纸渐变。

> 主图真源：`icon-master-1024.png`（1024×1024）。所有尺寸由同一矢量绘制光栅化，未经二次缩放。

## iOS — `ios/AppIcon.appiconset/`
直接拖进 Xcode 的 Assets，或替换工程里的 `AppIcon.appiconset`。已含 `Contents.json`，覆盖 iPhone / iPad / App Store(1024) 全套尺寸。
图标为**满版方形**（无圆角、无透明），圆角由系统遮罩——这是 iOS 规范要求。

## Android — `android/`
**自适应图标（API 26+）**：`mipmap-anydpi-v26/ic_launcher.xml` 引用
- `ic_launcher_foreground.png` —— 前景（仅书签本，留出安全区，也用作 monochrome 主题图标）
- `ic_launcher_background.png` —— 背景（暖纸渐变）

**传统启动图标**：各密度下的 `ic_launcher.png`（方形）与 `ic_launcher_round.png`（圆形遮罩）。
密度：mdpi 48 · hdpi 72 · xhdpi 96 · xxhdpi 144 · xxxhdpi 192（前/背景为 108dp 同比：108/162/216/324/432）。

**Play 商店**：`ic_launcher-playstore.png`（512×512）。

Flutter 工程对应位置：把 `android/mipmap-*` 整体覆盖到 `android/app/src/main/res/`；iOS 覆盖到 `ios/Runner/Assets.xcassets/AppIcon.appiconset`。

## 预览
打开 `Icon Export Preview.html` 看明/暗背景、iOS 圆角遮罩、Android 自适应圆形遮罩下的实际观感。
