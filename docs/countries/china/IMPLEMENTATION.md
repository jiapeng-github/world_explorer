# 中国深度百科 · 实现记录

日期：2026-11-07。Flutter 版本 `0.4.0+4`，内容版本 `2026.11.7`，中国内容修订 `2`。

入口：[实际运行截图](implemented/index.html) · [原设计稿](index.html) · [内容与设计差异](CONTENT_PLAN.md) · [照片许可与地点来源](MEDIA_CREDITS.md)。

## 已实现

| 模块 | 运行行为 |
| --- | --- |
| 中国概览 | 长城实景、国家资料、山河/生活/文明三条主线、编辑问题、地图预览、精选地点与历史线索；按真实进度续读 |
| 十栏目与主线 | 十栏目各三篇不同文章；路线共用稳定文章 ID，不复制阅读记录；手机与大字号自适应布局 |
| 中国地图 | 地形/河流/地标三层，真实长江与黄河折线、地点聚合、搜索和同步列表、全图复位；手机三挡面板，1024 及以上侧栏；返回保留镜头 |
| 阅读 | 30 篇独立正文，每篇五段，491–585 个汉字；词语解释、目录、系统朗读、收藏、笔记、地图入口及证据段落回读；平板文章目录侧栏 |
| 教学图解 | 地势、剪纸、生态、水路、食物、观察证据六种代码绘制的教学示意；可点选解释，剪纸三步使用同一图样 |
| 地点与照片 | 12 处独立地点，区域和定位依据、关联文章、图集与署名；19 个照片观察热点，与文字入口同步；观察照片可缩放、复位 |
| 历史、文化、生活与生态 | 精选历史线索与年代解释；剪纸、端午、茶、稻鱼、城市和栖息地分别有独立正文及适配图片 |
| 理解题 | 12 道选择/判断、6 道真实地图定位、6 道照片/图示观察；先选择再提交，反馈可回读证据；地图有等价文字选项 |
| 开放观察与发现页 | 六个观察任务，三格任选填写；草稿恢复、保存真实笔记、编辑及删除撤销；阅读/地点/笔记分别统计 |
| 兼容与内容包 | 原七篇文章、三处地点 ID 保留；重写正文不沿用旧完成状态，旧阅读记录留存快照，笔记与收藏保留；旧安装包不会覆盖更新的内置中国内容 |

当前全 App 有 177 个基础国家与地区条目，其中六国提供 68 篇文章、24 处地点、39 道理解题。中国占 30 篇、12 处、24 道，另有六个开放任务。未研发国家仍从百科隐藏，在地图中显示不可点击的“即将上线”；没有恢复“离线百科”标签。

中国资产库包含 36 张真实照片和一幅作者授权的剪纸作品图。当前正文与图库实际引用 35 张照片和这幅作品，另一张熊猫照片是备选；六种图解由 Flutter 绘制，不冒充实拍或测量地图。所有照片均有署名、许可、实际尺寸与校验值。

## 验证结果

- `flutter analyze --no-pub`：无问题。
- 完整 Flutter 测试：83 项通过。包含原有模块回归、中国 14 路由的手机/平板/1.5 倍字号检查、短屏阅读弹窗、观察草稿、笔记保存与删除撤销、题目证据跳转、内容修订迁移与旧包覆盖保护。
- 地图测试覆盖真实折线命中、分段不跨线、候选目标限制、地点聚合、全图范围、切层镜头保持、三挡面板及地图到地点后返回；小屏与 1024/1194 布局通过。
- Python 工具测试：内容 9 项、内容包 10 项、地图资产 4 项，共 23 项通过。完整内容目录和 37 项媒体文件校验通过。
- Android arm64 调试 APK 构建通过；Web JavaScript release 构建通过。两个构建产物中的 catalog 与最终源数据一致，Web 版本为 `0.4.0+4`。
- Web 浏览器已实际打开中国概览，验证“从山河开始 → 地势文章 → 中国地图”可运行，地图目标与平板侧栏正确显示。
- 28 张运行截图已导出：14 页 × 手机 390×844 / 平板 1194×834；截图为真实 Flutter 控件渲染，内容为空时显示真实空状态。

复现命令：

```sh
export PATH="/Users/penn/Development/flutter/bin:$PATH"
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
flutter analyze --no-pub
flutter test --no-pub
python3 tool/content/validate_catalog.py
python3 tool/content/fetch_china_media.py
python3 -m unittest discover -s tool/content
python3 -m unittest discover -s tool/packs
python3 -m unittest discover -s tool/maps
flutter test --no-pub test/china_experience_test.dart --dart-define=CAPTURE_CHINA=true
flutter build apk --debug --target-platform android-arm64 --no-pub
flutter build web --release --no-web-resources-cdn --no-pub
```

## 产物与使用

- Android：`build/app/outputs/flutter-apk/app-debug.apk`，arm64 调试包；本轮没有替换 Android Studio 正在运行的模拟器实例。
- Web：`build/web/`。可执行 `python3 -m http.server 5371 --bind 127.0.0.1 --directory build/web`，打开 `http://127.0.0.1:5371/#/countries/china`。
- 源稿：`tool/content/editorial/china.json` 与 `china_assets.json`；运行目录：`assets/atlas/catalog.json`。
- 新版中国离线包已在本机完成制作和校验，约 12.9 MB；没有发布到远程内容服务。

## 实装边界

自然地理底图与国家轮廓来自既有 NASA / Natural Earth 资产，河流使用 Natural Earth 10m 真实线段。当前不是省级行政地图、街道导航或精确海拔剖面，小岛显示受原始比例尺限制。六种教学图解均明确标为示意。

真实图片替代概念稿中的生成风景；历史线索、位置题和部分观察文案根据可核实资料与已提供图片调整，逐项记录在内容计划第 8 节。没有伪造采访、方言音频、实时天气或未提供的连续照片；朗读依赖设备或浏览器的中文语音。

本轮验证了 Android 构建、Web 构建及 Flutter 交互/布局测试，未完成新 APK 的真实 Android 平板运行验收或 iOS/macOS 构建。Web 首次访问需要加载站点，断网重新启动和浏览器回收存储仍需单独验收。构建中现有 `flutter_tts` 插件提示未来 Kotlin 与 Wasm 兼容性事项，当前 Android 与 JavaScript Web 构建成功。
