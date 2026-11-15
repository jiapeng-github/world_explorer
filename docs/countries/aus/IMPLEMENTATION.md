# 澳大利亚模块实施记录

设计基线：2026-11-11，主题「从海岸走向红土大陆」。已接入正式国家百科；地图、搜索、目录、文章与个人记录使用同一份内容。

## 已实现

- 10栏目、30篇文章，每篇6段、468–514汉字，含独立词语解释和来源。
- 12处地点：悉尼港、堪培拉、墨尔本、Flynn Reef、丹特里、卡卡杜、乌鲁鲁、墨累河亚拉旺加河段、十二使徒岩、珀斯、袋鼠岛、摇篮山。
- 24道闭合题：12证据选择、6地图定位、6观察判断；每题指向正文证据。6项开放观察使用「我看见／我猜想／我还想知道」记录并保存。
- 三条阅读路线：海岸与城市、红土与水、动物的家。显示阅读进度，可继续未完成文章。
- 国家首页、目录、手机／平板地图、阅读、地点观察、人文栏目、日常栏目、历史线索、探索任务、我的发现、路线与笔记，共14种核心页面状态。
- 8种可切换图解：珊瑚、季节、海岸变化、电车换乘、食品标签、小麦到面包、袋鼠育幼、鸭嘴兽。
- 收藏、阅读进度、答题结果、笔记及草稿复用本地持久化；正文沿用现有朗读能力。

## 地图

国家范围展示大陆与塔斯马尼亚，不包含全部外部领地。海岸线使用现有Natural Earth地理底图，地形使用现有NASA底图；没有生成式地理图片。

墨累河679顶点、达令河396顶点，保留Natural Earth 1:10m源数据分段。东北沿海礁体使用116段Natural Earth 1:10m原始礁体线段，绿色绘制，可选取；这是概化礁体分布，不是大堡礁海洋公园行政边界，也不代表健康状况。Flynn Reef为具体照片观察点。

地点、河流、海峡、礁体支持搜索或点选。定位题使用真实地图；国家与地点ID分开，墨累河观察地点使用`aus-murray-yarrawonga`，避免与河流`aus-murray`冲突。

## 图片与内容边界

初始设计的媒体位由17张核验过的实景和5张原创学习卡复用，另有8种矢量图解；没有宣称36张独立实景素材全部齐备。来源、作者、许可、拍摄日期和字节校验见 [SOURCES.md](SOURCES.md)。

首页使用已核验授权的悉尼黄昏实景，概念稿中的日景未作为素材直接使用。保持原有品牌、浅色背景、深海蓝、橙色和大幅图片布局。

乌鲁鲁使用地图与公开资料、原创文字卡，未展示未经核验使用条件的照片。原住民族内容区分Aboriginal peoples和Torres Strait Islander peoples，不生成文化图案或编写神圣故事。历史卡明确标注为原创学习卡，不冒充历史影像。

袋鼠照片为竖幅；阅读与观察页完整展示，避免裁掉成年个体和幼崽。市场照片记录入口建筑，正文明确不把它当成商品标签或摊位证据。

## 可复现构建

```sh
python3 tool/content/author_aus.py
swift -module-cache-path /private/tmp/aus-swift-cache tool/content/render_aus_cards.swift
python3 tool/content/finalize_aus.py
python3 tool/content/build_catalog.py
python3 tool/content/aus_validation.py
python3 tool/content/validate_catalog.py
```

照片下载由`tool/content/prepare_aus_media.py`完成，需要网络和本机代理。地图提取分别使用`tool/maps/build_aus_rivers.py`与`tool/maps/build_aus_reefs.py`，输入Natural Earth原始zip；源地址、版本与哈希保存在GeoJSON中。

## 验证记录

- 澳大利亚内容数量、正文字数、图文引用、题目证据、地图选项、媒体SHA-256：通过。
- 全库内容结构、引用与打包素材校验：通过。
- Flutter静态分析：No issues found。
- 澳大利亚及共享地图、数据、持久化回归：39项通过。
- 页面测试覆盖390×844手机、1194×834平板地图、320×568与1.5倍字号；30篇文章、12地点、24道题逐页渲染。
- 文章收藏、珊瑚内嵌答题与开放观察保存通过；14张真实界面截图位于[implemented](implemented/)。
- Android调试APK构建成功：`build/app/outputs/flutter-apk/app-debug.apk`。已打开APK核对30篇文章、22份媒体的SHA-256、礁体数据和袋鼠岛坐标。尚未在实体手机上验收，朗读音色取决于设备语音引擎。

### 构建环境记录

SQLite原生库下载首次直连停滞。只停止本次SQLite下载子进程后，使用现有本机代理重试，13.4秒完成Gradle构建；没有修改Android Studio运行配置。

```sh
https_proxy=http://127.0.0.1:7897 http_proxy=http://127.0.0.1:7897 FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn flutter build apk --debug --no-pub
```
