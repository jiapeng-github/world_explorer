# 日本模块 · 实现与验收记录

主题：**日本 · 从岛屿读懂山海与生活**。Flutter 实现采用浅色、深海蓝与橙色，大幅实景封面、图鉴式阅读和分区地图。

## 已实现范围

| 模块 | 内容与行为 |
| --- | --- |
| 国家首页 | 富士山实景、三项基本信息、三个探索主题、继续阅读、收藏、地图与个人发现入口 |
| 探索目录 | 10 个栏目，每栏 3 篇文章；全部 30 篇正文为 450–650 字左右 |
| 三条学习路线 | 岛屿与山海、城市的一天、物件里的时间；每条 3 站，链接到真实文章 |
| 地图 | 主要列岛、西南岛屿、小笠原三个范围；缩放、搜索、图层、地点列表、详情抽屉、相机状态保留、动态比例尺 |
| 水系 | Natural Earth 1:10m 石狩川、利根川、最上川原始河段，保留源数据的分段和缺口 |
| 地点 | 东京隅田川、富士山、京都鸭川、姬路城、琵琶湖、广岛和平纪念公园、白老 Upopoy、钏路湿地、樱岛、屋久岛、那霸、西表岛 |
| 实景观察 | 每处地点独立说明、实景图片、2–3 个可点选观察点、关联阅读与笔记入口 |
| 阅读 | 30 篇文章、术语、来源、段落、关联地点、阅读进度、收藏与现有朗读入口 |
| 原创图解 | 火山剖面、换乘、稻谷到米饭、发酵、木版套印、森林层次、地图尺度、水流关系；每个图解 3 个可选步骤 |
| 学习任务 | 12 道选择、6 道定位、6 道观察，共 24 道闭合题；每题有正文证据、提示、解释与持久化记录 |
| 开放观察 | 6 项开放任务，“我看见 / 我猜想 / 我还想知道”，支持草稿与保存 |
| 历史线索 | 陶器、1945 年战争记忆、1964 年新干线、2013 年富士山文化遗产；可切换线索与年代 |
| 我的发现 | 使用现有国家发现页汇总阅读、收藏、答题与观察记录 |

## 内容与媒体边界

- 12 处地点均使用对应实景：11 张新引入的 Commons 照片，加已有富士山照片。媒体记录保留作者、来源、许可及文件校验值。
- 10 张原创学习卡用于语言、校园、餐桌、表演协作、标签、陶器、稻米、味噌、木版套印、折纸。它们明确标作图示，不代替历史原物或实景照片。
- 8 个动态图解由 Flutter 绘制，表达关系，不按实际层厚、距离或时间比例。换乘站名与市场标签为虚构练习。
- 森林照片是山地远景；正文明确区分照片可见的山脊、树冠与图解中的林下层次。
- 阿伊努内容介绍当代传承，并区分阿伊努语与日语。冲绳内容保留地区与语言差异。战争内容采用适龄、非血腥说明，并纳入日本侵略战争背景。
- 地图沿用共享的 Natural Earth 50m 国土轮廓及 NASA 底图；小岛形状经过概化。三个分区使用独立比例，比例尺按视窗中心纬度计算横向近似距离。它是百科学习地图，不提供实时交通或导航。
- 地理要素没有对应实景时，地图卡片显示文字说明，不借用其他地点照片。

## 数据与兼容

国家修订号为 `4`，文章修订号为 `4`。保留原有 8 篇文章和段落 ID，旧收藏、笔记与阅读引用继续可解析。原有日语文字与富士山文化题保留选项 ID；旧地理选择题归档，新定位题使用独立 ID `japan-kushiro-location-check`，避免把旧答案当作新定位答案。

主要源文件：

- `tool/content/sources/japan_legacy.json`：原有内容快照。
- `tool/content/sources/japan_expansion.json`：新增 22 篇文章基础段落。
- `tool/content/sources/japan_details.py`：深入阅读、术语、来源、地点介绍与已目视核对的照片观察点。
- `tool/content/sources/japan_media_manifest.json`：Commons 原始图片元数据。
- `tool/content/author_japan.py`：无网络、确定性的日本内容生成器；读取已提交素材，不依赖临时下载目录。
- `tool/content/render_japan_cards.swift`：原创学习卡生成器。
- `tool/maps/build_japan_rivers.py`：保留原始顶点的河流提取器。
- `tool/content/editorial/japan.json` / `japan_assets.json`：编译输入。

来源覆盖 UNESCO 世界遗产中心、Upopoy、日本环境省、东京大学博物馆、武藏野美术大学、日本消费者厅、农林水产省、JR 东海及地方官方资料。来源链接在文章和应用来源页中可查看；图片许可与百科事实来源分开记录。

## 路由

```
/countries/japan
/countries/japan/contents
/countries/japan/journeys/islands
/countries/japan/journeys/daily
/countries/japan/journeys/objects
/atlas?country=japan
/atlas?country=japan&place=japan-naha
/atlas?country=japan&feature=japan-chichijima
/countries/japan/sections/{sectionId}
/articles/{articleId}
/places/{placeId}
/countries/japan/timeline
/countries/japan/explore
/exercises/{exerciseId}
/countries/japan/observe/{articleId}
/countries/japan/observe/place/{placeId}
/me/countries/japan
```

## 可复现检查

```sh
python3 tool/content/author_japan.py
python3 tool/content/build_catalog.py
python3 tool/content/validate_japan.py
flutter test --no-pub test/japan_experience_test.dart test/japan_diagrams_test.dart --dart-define=CAPTURE_JAPAN=true
flutter analyze --no-pub
python3 tool/packs/atlas_packs.py build --version 2026.11.11-japan-r4 --country japan
python3 tool/packs/atlas_packs.py validate build/content/2026.11.11-japan-r4
```

`validate_japan.py` 校验数量、栏目均衡、字数、引用、图解、题型、证据、热点、图片文件与 SHA-256，并比较最终目录和编辑源。它独立于其他正在开发的国家。

页面测试覆盖 390×844 手机、1194×834 平板地图、320×568 / 1.5 倍字体，全部文章、地点和练习，答题保存、笔记保存，以及三分区切换。图解测试验证全部 8 类的步骤切换与大字体。

生成的实现截图见 [预览图册](implemented/index.html)。测试运行结果与 APK 构建结果见 [验收记录](VALIDATION.md)。自动化检查不代替真机手势、系统朗读和逐像素视觉验收。
