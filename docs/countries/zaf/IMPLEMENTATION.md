# 南非模块实现

2026-11-11。视觉基线：`images/01-core-pages.png`。正式入口：`/countries/zaf`；百科和世界地图已使用正式 editorial 内容。

## 已实现

- 10个栏目、30篇完整正文。每篇5段，约406—456个正文字符，另含词语解释、来源、地图或观察入口。
- 24道有正文证据的练习：12道选择、6道地图定位、6道观察；6项开放观察。
- 12个地点、3条阅读路线、4个历史节点。阅读进度、收藏、练习记录、观察草稿和已保存笔记接入现有持久化系统。
- 11种可点击的教学图解：海岸与高原、两个海角、企鹅栖息地、食物关系、水与湿地、虚构换乘、语言卡、练习标签、配方、重复图案、历史顺序。示意材料与实景照片明确区分。
- 专属地图：Natural Earth 1:10m南非及6个邻国国界、奥兰治河与林波波河原始河段、NASA区域地形影像、地点搜索、聚合、缩放和详情跳转。
- 14张授权实景摄影，具备作者、许可、拍摄日期说明、原始来源、下载地址及SHA-256。照片是具体地点和时刻的记录，不代表实时景象或所有人的生活。
- 精修首页、照片目录、阅读页、日常生活页、地图地点面板与观察记录页，统一浅色、深海蓝、橙色和现有App标识。

## 内容与地图边界

- 12种官方语言包含南非手语；三个首都按职能概括，同时说明宪法法院在约翰内斯堡。
- 莱索托和埃斯瓦蒂尼保持独立国界，南非多边形保留内环；德拉肯斯山相关遗产跨越南非与莱索托。
- 非洲大陆最南端是厄加勒斯角，好望角不是最南端。大洋地理分界不渲染成固定海水双色线。
- 自然地点使用公开代表点，不标出具体巢穴；全国地图不用于现场导航。
- 1994年历史内容区分参与权利的进步与后续持续建设，不使用歧视角色扮演。
- 页面构图参考效果图，但摄影使用可追溯的真实素材，地图使用真实地理数据；没有把生成图当实景或地图。

## 文件与再生成

- 正文：`tool/content/sources/zaf_articles.txt`
- 编译器：`tool/content/author_zaf.py`
- 媒体恢复清单与校验工具：`tool/content/sources/zaf_media_manifest.json`、`tool/content/restore_zaf_media.py`
- 正式内容与媒体：`tool/content/editorial/zaf.json`、`zaf_assets.json`
- 首页：`lib/features/encyclopedia/zaf_overview.dart`
- 交互图解：`lib/features/reader/zaf_diagrams.dart`
- 专属地图配置：`lib/map_engine/country_map_profile.dart` 的 `southAfricaMapProfile`
- 国界与河流构建：`tool/maps/build_zaf_detail.py`、`build_zaf_rivers.py`
- 校验：`tool/content/zaf_validation.py`，已接入通用目录校验。
- 页面、笔记、练习与地理测试：`test/zaf_experience_test.dart`

```sh
python3 tool/content/author_zaf.py
python3 tool/content/build_catalog.py
python3 tool/content/validate_catalog.py
flutter analyze --no-pub
flutter test --no-pub test/zaf_experience_test.dart test/zaf_preview_test.dart
```

国界与河流构建脚本接收官方Natural Earth ZIP路径，保留源数据片段；只更新南非专用资源，不替换共享世界底图。区域地形的下载地址、投影、范围与哈希记录在 `assets/atlas/zaf-relief-source.json`。

## 兼容与交付

旧 `/preview/zaf` 开发入口保留，原预览草稿与答案键未删除。正式内容使用独立稳定ID，预览练习不会冒充正式学习进度；正式观察记录通过“我的南非发现”管理，保存后开启新的观察会清空输入框，未保存草稿则恢复。

本地内容包：`build/content/2026.11.11-zaf.1/zaf`，包含30篇文章、12个地点、24题及14张媒体。地图与交互组件随App提供，内容包本身不替代App代码升级。未向外部服务发布。

真实Flutter截图见 `implemented/index.html`；验证结果见 `VALIDATION.md`。
