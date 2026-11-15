# 肯尼亚模块实现与验收

2026-11-12。依据确认的七组生图效果图实现 Flutter 页面，沿用现代地理图鉴的白底、深海蓝、橙色和现有 App 标识。

[14 个实际页面及效果图对照](implemented/index.html) · [原始效果图](index.html)

## 交付范围

| 内容 | 实现 |
| --- | --- |
| 正文 | 十栏目 × 三篇，共30篇，每篇五段、450–650汉字，术语和来源入口 |
| 地点 | 12处，每处两幅实景照片；肯尼亚山、拉穆木门具有实际照片热点 |
| 闭合题 | 12道选择、6道定位、6道观察，答案与本篇证据段落关联 |
| 开放观察 | 6项，三栏空白输入、草稿恢复、保存真实记录 |
| 阅读路线 | 高山与水、城市与海岸、生命的空间，每条三站 |
| 教学图解 | 海拔、裂谷、水流、换乘、玉米加工、四拍、栖息连通、红树林潮位 |
| 素材 | 36项：29幅有来源与许可的真实照片，7张明确标注的原创教学卡 |

首页、目录、地图、地点、阅读、历史、日常生活、任务、发现、路线和观察页已经接入内容。任务有四类筛选和真实继续记录。发现页首次为0／0／0；地图选中不记为看过地点，进入详情后才记录。空观察不能保存，路线标注为阅读顺序。

## 地图与事实校正

地图由 Natural Earth 1:10m 的 Map Units、Lakes、Land Boundary Lines、Disputed Areas 构建，背景使用NASA Blue Marble。WGS84椭球LAEA投影中心为北纬0°、东经38°，单位公里、屏幕Y为负北坐标；Dart坐标用独立PROJ样本核验。

保留真实海岸和岛屿、五个邻国背景、完整跨境维多利亚湖和图尔卡纳湖；赤道由纬度0°生成。伊莱米三角地区以斜纹和虚线独立标示，附争议说明。支持三图层、搜索、中英文别名、缩放、比例尺、地点聚合、手机抽屉及平板左侧详情。

本次来源没有足够细的奈瓦沙湖面，L03使用图尔卡纳湖与维多利亚湖两个真实面；奈瓦沙仍有完整地点和照片。未虚构47郡边界、裂谷行政区或动物迁徙路线。NASA局部WMS请求失败后使用已随项目保留的全球背景重新投影；放大时地形影像细节有限，矢量轮廓与地点仍独立清晰。

肯尼亚山主图为巴蒂安岩峰真实摄影，不是乞力马扎罗山。Isukuti采用具体活动现场照片并注明语境，四拍为原创练习，不冒充原曲。1963独立与1964成为共和国分开说明；2010宪法和独立资料使用明确标注的原创摘记，不伪造档案。

## 兼容性与设计差异

保留八个旧文章ID：geography、people、daily、food、culture、nature、history、questions，均加kenya前缀。保留旧地点kenya-mount-kenya、kenya-lamu、kenya-amboseli，设计草案中的kenya-mountain统一改为既有ID。正文revision为2，重写段落使用v2标识；旧阅读快照存档并重置，收藏与笔记不删除。三道旧题进入归档索引并指向新题。旧revision=1内容包不会覆盖新版内置内容。

生成概念图中的照片和地图已换为真实素材，因此构图、季节和地图位置与生图不完全相同；页面层次、图鉴卡片和主要交互按批准设计实现。M36用于独立红茶阶段卡，对比观察使用已有森林两照片，明确不能推定同地点季节变化。使用原有品牌栏和全局导航规范。

## 验证记录

- 全项目Flutter回归184项通过，覆盖既有国家；最终视觉调整后另复测肯尼亚全部13项。
- 页面尺寸390×844、430×932、1194×834；320×568下1.5倍文字，无布局溢出。
- 肯尼亚30篇文章、12地点、全部24闭合题及6开放观察均打开验证；零进度、答题保存、观察保存、旧版收藏笔记保留与旧包保护通过。
- Python内容工具9项、地图工具4项、内容包工具10项，共23项通过。内容引用、正文长度、证据段落与36项资源SHA256校验通过。
- `flutter analyze --no-pub`无问题；最终肯尼亚13项复测通过。
- Android ARM64 debug与Web JavaScript release构建成功；逐字节比对两端30篇正文、12地点、24题、36素材及地图JSON／底图，与最终源码一致。
- 安装包：`build/kenya-release/world-explorer-kenya-debug-arm64.apk`；Web：`build/web/`；核验记录：`build/kenya-release/artifact-verification.json`。
- 最终独立内容包：`build/kenya-release/2026.11.12-kenya.3/kenya/`，资源11,596,927字节。早期`.1`、`.2`为候选快照，以`.3`为准。
- 未进行Android真机安装与断网语音验收。现有flutter_tts的Kotlin插件迁移及Wasm预检查提示未阻止本次Android和JavaScript构建；不声称Wasm可用。

## 维护入口

- 正文：`tool/content/sources/kenya_articles.txt`；生成器：`tool/content/author_kenya.py`。
- 素材：`tool/content/editorial/kenya_assets.json`；原始署名及许可记录：`tool/content/sources/kenya_commons.json`。
- 地图：`tool/maps/build_kenya_regions.py`；坐标样本、来源哈希与争议说明：`assets/atlas/kenya-regions.json`。
- 页面：`lib/features/encyclopedia/kenya_overview.dart`、`kenya_experience.dart`，以及atlas、exercises、reader对应Kenya模块。
- 测试：`test/kenya_experience_test.dart`、`test/kenya_diagrams_test.dart`；内容契约：`tool/content/kenya_validation.py`。

```bash
python3 tool/content/author_kenya.py
python3 tool/content/build_catalog.py
python3 tool/content/validate_catalog.py
flutter test --no-pub test/kenya_experience_test.dart test/kenya_diagrams_test.dart --dart-define=CAPTURE_KENYA=true
```

地图、新图解和界面代码随App发布，仅导入内容包不能更新这些功能。语音复用设备已有TTS能力；本轮不声称提供新增斯瓦希里语原生录音或完成Android真机断网验收。
