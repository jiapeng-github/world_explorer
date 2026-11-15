# 世界大百科

面向约 8 岁孩子的中文地理百科，使用 Flutter 开发。当前开发版本为 `0.8.0+8`，按已确认的“现代地理图鉴”原图实现浅色、深海蓝、橙色和大幅实景界面。

设计依据：[开发文档](docs/redesign/DEVELOPMENT.md)、[28 个页面规格](docs/redesign/SCREENS.md)、[原图总览](docs/redesign/index.html)。[运行截图](docs/redesign/implemented/index.html)与[实现记录](docs/redesign/IMPLEMENTATION.md)用于复核当前开发结果。规格中的 20 个深度国家、160 篇文章等是首发目标，不代表现有数量。

## 当前交付

已内置 12 个深度国家和南极洲专题，共 391 篇文章。所有文章已配齐“亲切向导”自然讲解，共 2,075 段，可离线播放；录制与校验流程见 [音频说明](docs/audio/README.md)。

2026-11-16 完成 34 条审核意见的逐项核实，修复或优化 30 项，另 4 项确认为正常滚动边界。静态分析通过，226 项测试通过。详见 [审核修复记录](docs/review/REVIEW_RESOLUTION.md)。

## 模块实现记录

美国模块已接入十栏目、30 篇正文、12 处地点、24 道题、6 项开放观察和三条探索路线。地图支持相连 48 州、阿拉斯加、夏威夷三幅区域图和华盛顿特区。见[美国实现记录](docs/countries/usa/IMPLEMENTATION.md)与[14 张运行截图](docs/countries/usa/implemented/index.html)。

埃及深度模块已接入：「沿着尼罗河」「走进今天」「追寻文明」三条路线，30 篇正文、12 处地点、24 道题、6 项开放观察。埃及区域地图包含离线地形、真实河线与运河、手机详情面板和平板右栏。见 [埃及实现记录](docs/countries/egypt/IMPLEMENTATION.md) 与 [运行截图](docs/countries/egypt/implemented/index.html)。

中国深度模块已接入：三条探索主线、十栏目、30 篇独立文章、12 个地点、24 道理解题与 6 个开放观察。地图加入真实长江/黄河折线、地点聚合与手机/平板详情面板；阅读加入六种教学图解、照片热点、证据回读和中国发现笔记。见 [中国实现记录](docs/countries/china/IMPLEMENTATION.md) 和 [28 张实际运行截图](docs/countries/china/implemented/index.html)。

- 发现、地图、百科、我的四入口；手机底部导航与较宽窗口导航轨。
- 兴趣引导、实景问题入口、国家与专题目录；国家详情、十栏目、文章、地标及图集。176 个国家基础条目，其中 12 国提供 367 篇文章、145 处地点、288 道理解题，另有 8 个跨国专题；南极洲另外提供 24 篇文章、12 处地点及 18 道理解题。
- 真实国家轮廓、NASA 地形、水系与地标图层，支持缩放、平移、选择与详情面板；提供 1:110m 概览和 1:50m 细节地图。
- 阅读目录、续读、词语解释、自然讲解、收藏、笔记和可回读正文的理解题；不需要答题解锁知识。
- SQLite 本机存储、旧记录迁移、备份导入预览与冲突处理；内容包下载、摘要校验及事务安装。
- 家长设置、字号、语速、休息提醒及来源许可。内置文章优先播放录制讲解；未配录音的其他文字及备用朗读依赖平台中文语音。

## 运行与检查

本机环境：Flutter 3.47.6 / Dart 3.13.5。

```bash
export PATH="/Users/penn/Development/flutter/bin:$PATH"
cd /Users/penn/Projects/world_explorer
flutter pub get
flutter run -d chrome
```

下载较慢时可为命令加 `PUB_HOSTED_URL=https://pub.flutter-io.cn FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn`。Web 使用 JavaScript 构建；当前朗读插件不支持 Wasm 构建。

Android Studio 的 `main.dart` 运行配置已单独保存这两个镜像环境变量。若新建运行配置，请在 **Run → Edit Configurations → Environment variables** 中同样设置；仅在终端里设置不会自动应用到 IDE 的 Run。缺少 `FLUTTER_STORAGE_BASE_URL` 时，Android 引擎下载可能让运行长时间停留在 `assembleDebug`。

```bash
flutter analyze --no-pub
flutter test --no-pub
flutter build web --release --no-web-resources-cdn
flutter build apk --debug --target-platform android-arm64
```

产物在 `build/web/` 和 `build/app/outputs/flutter-apk/`。当前验收结果见 [审核修复记录](docs/review/REVIEW_RESOLUTION.md)。Apple 平台的构建与签名需单独验证。

本地预览与截图：

```bash
python3 -m http.server 5291 --bind 127.0.0.1 --directory build/web
flutter test --no-pub test/atlas_screens_test.dart --dart-define=CAPTURE_SCREENS=true
```

打开 `http://127.0.0.1:5291/`；56 张手机/平板截图位于 `docs/redesign/implemented/`，可打开其中的 `index.html` 按模块对照原图。

## 内容与离线包

```bash
python3 tool/content/build_catalog.py
python3 tool/packs/atlas_packs.py build --version 2026.11.8-dev
python3 tool/packs/atlas_packs.py validate build/content/2026.11.8-dev
python3 -m unittest discover -s tool/packs -v
python3 -m unittest discover -s tool/maps -v
```

配置 `--dart-define=CONTENT_BASE_URL=<版本目录 URL>/` 后可连接内容服务；未配置时已有内容仍能阅读，界面会说明暂无下载地址。包格式、CORS 本地服务及更新限制见 [内容包工具说明](tool/packs/README.md)。原生内置资源可离线访问；Web 首次访问需要加载站点，离线重启及浏览器存储回收需单独验收。

## 本地记录

收藏、阅读进度、笔记、练习和设置保存在设备或浏览器的本地数据库。首次运行迁移旧版 `world_explorer.progress.v1`，保留原始快照并避免重复导入。家长中心可导出 JSON 备份，导入前预览并选择合并或覆盖；冲突笔记保留副本，覆盖前保留可恢复快照。备份不含可重新下载的媒体。卸载或清理站点数据前应保存个人备份。

## 工程结构

```text
lib/app/                   路由、导航、服务装配
lib/design/                主题与共用组件
lib/domain/                内容模型
lib/data/                  内容、SQLite、下载、朗读
lib/features/              十个功能模块
lib/map_engine/            地理投影、绘制与命中
assets/atlas/              新版目录、地图与照片
tool/content/              内容输入与目录生成
tool/packs/                包制作、校验、本地服务
tool/maps/                 50m 地图转换
test/                      数据、交互、布局与回归
docs/redesign/             开发文档、原图与实现记录
```

旧版代码保留在 `lib/legacy_main.dart` 和旧目录，用于迁移与回归；正式入口为 `lib/main.dart`。新增内容需保持稳定 ID、注明来源及核验日期并校验关联。实景、地图、字体与许可见 [ASSET_CREDITS.md](docs/redesign/ASSET_CREDITS.md)。

## 英国内容

新增英国十栏目 30 篇正文、12 处地点、24 道练习、6 项开放观察和三条探索路线。区域地图支持四组成部分与两座岛屿范围对照。见 [英国实现记录](docs/countries/gbr/IMPLEMENTATION.md)。

## 南极洲自然专题

南极洲以独立地域专题接入，不计入国家数量。包含 24 篇阅读、12 地点、真实极地地图、18 道任务、6 项开放观察和 3 条阅读路线。

- [实现与验收说明](docs/regions/antarctica/IMPLEMENTATION.md)
- [原设计与实际 Flutter 页面对照](docs/regions/antarctica/implemented/index.html)
- 专项测试：`flutter test --no-pub test/antarctica_experience_test.dart`

## 仓库内容

提交源码、测试、正式离线图片/地图/讲解、设计文档及审核引用截图。构建目录、音频生产缓存、重复打包文件和未被审核引用的批量巡检截图不入库，原文件仍保留在本机。正式资源位于 `assets/`，克隆后无需运行内容生成脚本即可构建。
