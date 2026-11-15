# 德国模块实现与验收

2026-11-11。按确认的 7 组生图效果图实现 Flutter 页面，未使用 Stitch。德国保留国家 ID `deu`，现已进入已开发国家百科，并可从世界地图进入完整内容。

[14 个实际页面截图](implemented/index.html) · [原始效果图](index.html) · [设计基线](DESIGN.md)

## 已实现

| 内容 | 交付 |
| --- | --- |
| 国家介绍 | 10 栏目 × 3 篇，共 30 篇；每篇五段、450–650 汉字；术语、资料来源与证据关联 |
| 地点 | 12 处完整地点，至少两张关联素材，科布伦茨与瓦登海照片热点 |
| 活动 | 12 道选择、6 道地图定位、6 道观察题，以及 6 项开放观察 |
| 阅读路线 | 河流与城市、森林与海岸、物件里的时间；每条三站，按真实阅读记录显示状态 |
| 教学图解 | 跨境河流、地形、换乘、食物流程、活字、节拍、倒木、潮汐共八类 |
| 素材 | 36 项：31 项真实照片／历史影像，5 张明确标注的原创教学资料卡 |
| 学习记录 | 收藏、阅读进度、答题保存、三栏观察、草稿恢复、真实发现计数、继续上次任务 |

首页、照片目录、地图、阅读、地点、历史、日常生活、探索任务、我的发现、路线与观察页全部接入实际内容。浅色、深海蓝、橙色、大幅照片与三路线卡按效果图还原。首次发现页为 0／0／0；地图点选不计为已访问，进入地点详情才记录。未填写观察时禁止保存。

## 地图与内容校正

- 使用 Natural Earth 1:10m 国界、岛屿与原始河线，NASA Blue Marble 地形背景；WGS84 输入转换为 ETRS89 / LAEA Europe（EPSG:3035）。Dart 投影使用独立 PROJ 坐标样本验证。
- 德国全国范围、邻国参照、莱茵河、摩泽尔河、易北河与多瑙河；搜索、缩放、地点聚合、切层、世界位置与手机可拖动抽屉。平板依确认图使用左详情、右地图。
- 河流保留跨境和原始分段，不在缺口间虚构水道。摩泽尔河的来源 ID 为 Q1667，易北河为 Q1644；测试覆盖科布伦茨汇合处和汉堡附近河线。
- 北部低地与阿尔卑斯教学区域来自 Natural Earth 自然区与德国范围相交；中部山地和德国境内劳西茨为明确标注的概略教学范围，不表示法定边界。16 州行政边界未列入首发图层。慕尼黑目前仅作定位题参考点，完整地图检索以已开发的 12 处地点为准。
- 所有路线标注“阅读顺序，不是交通路线”。照片代表点与摄影点分开说明，不提供实时潮汐、交通班次或现场导航。
- 历史正文包含纳粹政权迫害、大屠杀和战争责任，明确区分 1989 年开放边界与 1990 年统一。印刷页采用拉丁字母金属活字实拍，教学图展示镜像印面与正向纸面，说明东亚更早的印刷实践。
- 商品标签统一为虚构食品标签，名称／单位／产地字段相互一致。森林倒木实拍来自耶拿附近阿尔特格莱斯贝格保护区；图注明确它不是亚斯蒙德，避免不同森林混称。

## 与效果图的差异

生成图中的概念摄影、历史资料、地图已替换为有出处的真实素材和 GIS。构图、季节与生成图不完全相同；布局、视觉层次和交互遵循批准设计。1933—1945 节点使用明确标注的原创资料类型卡，正文链接真实历史资料，不把教学卡冒充档案。使用现有 App 标识；按钮禁用态、路线说明、字体换行及史实以开发文档为准。

## 验证结果

- `flutter analyze --no-pub`：无问题。
- 全项目 Flutter 回归：164 项通过，包含德国页面、地图、全部练习、记录持久化和八类图解交互检查。
- 德国布局：390×844、430×932、1194×834；320×568 下 1.5 倍字体，无溢出。14 张实际截图保存在 `implemented/`。
- Python 内容工具 9 项、地图工具 4 项、发布包工具 10 项，合计 23 项通过；内容 schema、引用、文章长度、证据块、素材字节与 SHA-256 校验通过。
- Android ARM64 debug 构建通过；解压安装包核对 30 篇德国文章、36 项素材哈希以及最新地图 JSON，均一致。未进行 Android 真机安装验收。
- Web JavaScript release 构建通过；核对打包后的德国文章、36 项素材哈希及地图 JSON，均一致。输出为 `build/web/`。上游 `flutter_tts` 在 Wasm 预检查中产生互操作提示，当前交付为成功编译的 JavaScript 版本，未声称 Wasm 可用。
- 全项目旧测试已改为动态选择真正无文章的国家，继续验证“即将上线”禁用态，避免以已上线澳大利亚作为失效样本。

## 交付与维护

App 版本沿用工程的 `0.8.0+8`。德国独立内容包版本为 `2026.11.11-deu.1`，内容资源 6,563,944 字节，位于 `build/germany-release/2026.11.11-deu.1/deu/`。地图及新交互代码随 App 打包，仅安装内容包不能升级旧版地图代码。

Android 安装包：`build/germany-release/2026.11.11-deu.1/android/world-explorer-germany-arm64-debug.apk`（200,922,634 字节，包含整个 App）。SHA-256：`59a5d65e694395790d0bc905549e880b56a5e0b595ffdcaa462a99d588978768`。

主要入口：

- 页面：`lib/features/encyclopedia/deu_overview.dart`、`deu_experience.dart`。
- 地图：`lib/features/atlas/deu_atlas_screen.dart`、`lib/map_engine/deu_map_data.dart`、`deu_learning_map.dart`。
- 练习／图解：`lib/features/exercises/deu_exercise_map.dart`、`lib/features/reader/deu_diagrams.dart`。
- 正文：`tool/content/sources/deu_articles.txt`；生成器：`tool/content/author_deu.py`。
- 素材：`tool/content/editorial/deu_assets.json` 记录署名、许可、原地址、拍摄日期、处理方式及哈希；`tool/content/sources/deu_commons.json` 保留 31 项完整来源元数据。
- GIS：`tool/maps/build_deu_regions.py`；`assets/atlas/deu-regions.json` 保留投影参数、来源哈希、教学区域说明及坐标校验样本。

重新生成内容与检查：

```bash
python3 tool/content/author_deu.py
python3 tool/content/build_catalog.py
python3 tool/content/validate_catalog.py
flutter test --no-pub test/deu_experience_test.dart test/deu_diagrams_test.dart
```

重新生成截图时增加 `--dart-define=CAPTURE_DEU=true`。地图重建需要原始 Natural Earth Map Units、Rivers、Geography Regions ZIP 和 NASA EPSG:4326 背景图；输入文件哈希及重投影参数见地图 JSON。正式内容打包工具见 `tool/packs/README.md`，每次修改使用新的发布目录或版本。
