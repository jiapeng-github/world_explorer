# 世界大百科 · App 图标

采用用户在 2026-11-06 选定的最后一款方案：**微缩地球与橙色纸飞机**。

- 原图：`assets/branding/world-atlas-icon-master.png`（1254 × 1254，无透明通道）
- 通用大图：`assets/branding/world-atlas-icon-1024.png`
- 图像生成方式：内置 image_gen；原图内容保持完整，平台文件仅按尺寸导出。
- 已接入 Android launcher、iOS AppIcon、macOS AppIcon、Web/PWA 与 favicon。
- 导出命令：`python3 tool/branding/export_icons.py`（使用 macOS 自带 sips）。

## 平台适配

- Android 本轮替换五组现有 launcher PNG（48、72、96、144、192 px），保留现有 `@mipmap/ic_launcher` 引用，未新增自适应前景/背景图层。
- iOS / macOS 保留已有 AppIcon 文件名与资源清单；原图为不透明正方形，未预制圆角。
- Web 的 `Icon-maskable-*.png` 沿用原项目文件名，但导出的是完整原图，不保证中央直径 80% 圆形安全区。因此 manifest 将其声明为 `purpose: any`，不将它们当作可任意裁切的 maskable 图标。与普通尺寸图标内容一致，仅为兼容原有文件路径保留。
- 原图和各平台缩放图均保持选定设计完整；未更换插画或添加边框。

## 验证记录（2026-11-07）

- 33 个导出 PNG 的像素尺寸与资源清单引用检查通过；主图与用户选定的生成原图逐字节一致。
- Android arm64 debug APK 构建成功：`build/app/outputs/flutter-apk/app-debug.apk`。解包核对五个密度的 `ic_launcher.png`，与项目导出文件逐字节一致。
- Web release 构建成功：`build/web/`。构建产物中的五个 PNG 与 manifest 均与源文件一致。
- 构建命令：`flutter --no-version-check build apk --debug --target-platform android-arm64 --no-pub`；`flutter --no-version-check build web --no-pub --no-web-resources-cdn`。
- Android 构建仍提示现有 `flutter_tts` Kotlin Gradle 插件迁移提醒；Web 的 Wasm 预检查仍提示该插件的 JS 类型转换兼容性问题，未影响本次常规 Web 构建。
- 未安装到模拟器或设备，未运行 iOS / macOS 构建；这两个平台仅验证了 AppIcon 文件尺寸和引用。

## 设计

蓝绿色海洋、山峰、金字塔与建筑组成微缩世界，橙色纸飞机表达主动探索。采用鲜艳色彩和立体材质，与孩子的世界百科主题对应。图中地貌为品牌插画，不用于呈现准确地理位置。

## 原始生成提示词

```text
Use case: logo-brand. Create one exceptionally polished, colorful App icon concept for 世界大百科, a world geography and culture encyclopedia for an eight-year-old. Completely original fresh direction: "a tiny world of wonders", a premium playful miniature 3D diorama with a single strong spherical silhouette. Center a beautiful slightly tilted turquoise-and-cobalt miniature planet, with sculpted emerald green land, curved clear ocean, a sunny ochre pyramid, one little terracotta-roofed architectural cluster, and a blue-white mountain with tiny green forest. These 3 landmark groups are broad iconic shapes, integrated into the planet surface, not a random busy collage. A small orange paper airplane and one smooth ivory trail partially orbit the planet to add discovery and motion. Composition has clear large-to-small hierarchy, asymmetrical but balanced, emblem occupies around 75% of square with ample safe margins. Art direction: expensive tactile 3D editorial illustration, sculpted matte resin with subtle glossy water, soft sunlit ambient occlusion, clean rounded contours, sophisticated Pixar-like material quality WITHOUT faces or characters. Rich vivid cyan, leaf-green, warm orange, cream, and coral, carefully balanced. A luminous pale aqua-to-sky background with gentle atmospheric depth; do not use a single flat orange fill. Slight elevated 3/4 view. Entire image is the full square icon artwork, not a presentation board or phone mockup. Avoid text, letters, badges, logo watermarks, books, globe grid lines, shields, fine scattered detail, realistic national borders, flat vector styling. Make it imaginative and full of depth while readable as an app icon. No separate rounded-square tile floating inside the frame.
```

