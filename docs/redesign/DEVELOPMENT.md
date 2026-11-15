# 世界大百科 · 新版开发文档

版本：设计规格 1.0 · 日期：2026-11-01  
工程：`/Users/penn/Projects/world_explorer`  
状态：开发依据；下述新版能力尚未全部实现。当前可运行 App 为 0.2.0+2。本次交付文档与模块界面设计，不变更运行代码。

## 1. 目标与范围

面向约 8 岁孩子的中文互动世界百科，支持独立探索与亲子共读。新版以国家百科、可交互地图和跨国专题为核心，使用用户已选择的“现代地理图鉴”视觉方向。

产品范围以 [70 项功能清单](../REDESIGN_FEATURES.md) 为准。本文约定模块边界、页面、模型、实现方式与验收条件；视觉规范见 [DESIGN.md](DESIGN.md)，逐页交互见 [SCREENS.md](SCREENS.md)。优先级 P0/P1/P2 沿用功能清单。

首发目标：世界基础目录、20 个深度国家包、至少 160 篇主题文章、100 处地标、160 张实景照片、8 个跨国专题及独立南极洲专题。内容数量是制作目标，不能直接当作现有内容展示。

P0 支持地图、搜索、阅读与朗读、理解题、笔记、收藏、续读、内容下载、离线使用、记录备份恢复。3D 地球、国家比较、语音搜索、云同步与智能问答按功能清单后续实施。内容不需要答题解锁。

## 2. 模块边界与追踪

| 模块 | 范围 | 对应功能编号 | 主要交付 |
| --- | --- | --- | --- |
| M01 发现 | 首次使用、精选、问题入口、续读 | A01–A07 | 首页与兴趣引导 |
| M02 地图 | 国家区域选择、定位、图层、地图详情 | B01–B12 | 图集与地点面板 |
| M03 国家百科 | 国家目录、十个栏目、时间线 | C01–C12 | 国家概览与栏目列表 |
| M04 地标风景 | 地标信息、图集、观察 | D01–D03、D07 | 地标页与图片查看器 |
| M05 跨国专题 | 专题目录、路线、关联知识 | D04–D06 | 专题列表与章节页 |
| M06 搜索 | 搜索、分类结果、别名 | E06、E09 | 搜索及结果页 |
| M07 阅读聆听 | 正文、目录、朗读、难词、来源 | E01–E05、E08、E10 | 阅读器与辅助面板 |
| M08 互动理解 | 题目、反馈、回读 | F01–F02、F06 | 题目与解释页 |
| M09 我的探索 | 收藏、足迹、笔记、个人回顾 | E07、F03–F05、F07 | 我的与笔记页 |
| M10 家长与离线 | 设置、休息、内容包、备份、资料说明 | G01–G09 | 家长中心、下载与备份 |
| 内容维护 | 结构、审核、许可、发布 | H01–H06 | P0 制作与校验工具；可视化后台为 P1 |

一个模块内可能同时含 P0 与后续功能，不能因表中列出整个编号范围就把所有项目纳入 P0。

## 3. 平台与技术决策

| 领域 | 新版方案 | 实施说明 |
| --- | --- | --- |
| 客户端 | Flutter / Dart | 沿用工程；README 记录的现有环境为 Flutter 3.47.6 / Dart 3.13.5，实际实施时再检查本机与 CI |
| 发布顺序 | Android、iOS；Web 用于预览与浏览 | Android 与 iOS 是完整离线包体验的首发验收平台。Web 提供相同内容结构，但存储配额与离线能力需独立验证 |
| UI 与状态 | 按功能分目录；View + 模块 ViewModel | ViewModel 使用 ChangeNotifier/Listenable，Repository 通过构造函数注入；不再让所有页面依赖同一个全局 Store |
| 路由 | go_router | 四个主入口各保留导航栈；详情支持稳定路径、深链和 Web 返回 |
| 结构化存储 | Drift / SQLite | 用户笔记、收藏、阅读位置、安装清单进入事务型存储；原生与 Web 使用不同数据库连接实现 |
| 轻量偏好 | shared_preferences | 仅保留字号、提醒等少量非关键偏好；迁移期读取旧记录 |
| 地图 | Flutter CustomPainter + 分级矢量资产 | 优先完成离线二维世界图集，数据、投影、命中检测、标注布局各自独立 |
| 朗读 | 封装现有 flutter_tts | 平台能力查询、缺语音降级、段落定位由 SpeechRepository 统一管理 |
| 内容交付 | 内置基础包 + HTTPS 静态内容包索引 | 首发不依赖账号服务；更新不要求重新发布 App |
| 搜索 | 本机索引 | 规范名称、别名、主题词优先；小规模语料使用预构建中文词条/二元词索引，无需在线搜索服务 |

新增依赖只在实际实施时解析兼容版本并提交锁文件，本次不改变 pubspec。架构分层参考 [Flutter 架构指南](https://docs.flutter.dev/app-architecture/guide)；离线读取由 Repository 协调本机和远端数据，参考 [Flutter 离线优先指南](https://docs.flutter.dev/app-architecture/design-patterns/offline-first)。

go_router 的路径与嵌套路由能力见 [官方包文档](https://pub.dev/packages/go_router)。Drift 的原生和 Web 实现见 [平台支持说明](https://drift.simonbinder.eu/platforms/)，Web 不能直接沿用原生文件路径。

## 4. 推荐目录

```text
lib/
  app/                 # bootstrap、router、依赖装配、主导航
  design/              # tokens、theme、通用组件、适配布局
  domain/              # 领域模型、Repository 契约、错误类型
  data/
    database/          # 表、查询、迁移、事务
    content/           # 本机内容包、manifest、关系索引
    downloads/         # 下载、校验、安装、恢复
    legacy/            # 0.2 数据映射与迁移
    speech/            # 平台语音适配
  features/
    discover/ atlas/ encyclopedia/ landmarks/ topics/
    search/ reader/ exercises/ journal/ family/
  map_engine/          # geometry、projection、hit_test、labels
assets/bootstrap/      # 基础国家目录、基础地图、首个示范内容包
content/               # 内容制作源数据；不直接塞入 lib
tool/content/          # schema、关系、媒体、地图、打包校验
test/                  # 领域、迁移、组件测试
integration_test/      # 阅读—地图—收藏、下载恢复等关键流程
docs/redesign/         # 本文、页面规格、设计规范、设计稿与提示词
```

数据方向：View → ViewModel → Repository → 本机数据库/文件与远端内容服务。View 不解析原始 JSON，也不拼接媒体下载地址。业务状态使用 loading/data/empty/error，内容可用状态单独建模。

## 5. 导航与上下文恢复

四个主入口：发现 `/discover`、地图 `/atlas`、百科 `/encyclopedia`、我的 `/me`。完整路由清单见 SCREENS.md。

- 切换主入口保留滚动位置、筛选、地图镜头；从详情返回仍回到原入口。
- 国家、地标、文章都使用稳定 ID。URL 不依赖中文标题或列表下标。
- 文章跳地图时保存 articleId、blockId 与段内位置，地图返回恢复原段；不能重新打开文章顶部。
- 地图进入地点详情时保存相机状态、图层与选中对象。外部深链没有返回来源时，返回其所属目录。
- 失效 ID 显示可返回的“内容暂不可用”页；内容包未安装时显示简介及下载动作。
- 搜索返回可恢复关键字、类型筛选和列表位置。浏览器历史与 App 返回路径保持一致。

## 6. 内容模型

所有内容实体含稳定 `id`、`schemaVersion`、`revision`、`locale`、`updatedAt`；事实来源和媒体许可分开引用。数据日期用 ISO 8601，界面按中文习惯显示。

| 实体 | 关键字段 | 约束 |
| --- | --- | --- |
| Country | id、name、aliases、regionIds、flagAssetId、capitalPlaceIds、geometryId、coverage、facts、sectionArticleIds、landmarkIds | `coverage` 是 basic/deep；不以文章数量临时推断 |
| CountryFact | key、value、unit、asOf、sourceIds | 人口等时变值必须有统计年份；未知值不补造 |
| Article | id、title、summary、countryIds、topicIds、blocks、glossaryIds、exerciseIds、sourceIds、reviewStatus | 可跨国家关联；只有 reviewed 内容进入正式包 |
| ContentBlock | id、type、payload | type 为 paragraph/heading/image/mapReference/callout/timeline；blockId 用于续读 |
| Place | id、kind、name、countryIds、geometryId 或 point、accuracy、articleIds | point 统一 `[longitude, latitude]`；区域示意点不能宣称精确位置 |
| Landmark | placeId、coverMediaId、galleryIds、summary、observation、sourceIds | 可关联多个国家；与同名城市通过类型区分 |
| Topic | id、title、question、coverMediaId、orderedNodes、relatedCountryIds | 节点引用内容，不复制正文 |
| MediaAsset | id、kind、variants、alt、caption、creator、sourceUrl、license、licenseUrl、depiction | depiction 为 realPhoto/diagram/creative；生成稿不能标作实拍 |
| Source | id、title、url、publisher、checkedAt、note | 与引用内容有关系；来源页面不是图片授权的替代 |
| Exercise | id、articleId、type、prompt、options、answer、explanation、evidenceBlockIds | 选择题、判断题、地图定位题均必须能回读依据 |
| UserBookmark | entityType、entityId、createdAt | 类型 + ID 唯一，重复收藏幂等 |
| ReadingProgress | articleId、blockId、fraction、contentRevision、completed、updatedAt | 字号变化后定位段落，不只保存像素偏移 |
| ExplorationNote | id、text、entityRefs、createdAt、updatedAt | 关联内容移除后仍保留笔记与内容标题快照 |
| InstalledPack | packId、version、status、bytes、installedAt、manifestHash | 安装状态与内容深度分别表示 |

本机数据库建议表：countries、places、articles、article_blocks、topics、topic_nodes、media_assets、sources、entity_sources、search_terms、bookmarks、reading_progress、notes、note_refs、exercise_attempts、installed_packs、migration_runs。用户数据与可重新下载的内容分别存储/管理。

## 7. 内容包与离线协议

客户端 Repository 契约（接口规格，不是已实现代码）：

```dart
abstract interface class ContentRepository {
  Future<CountryDetail> country(String id);
  Future<ArticleDetail> article(String id);
  Stream<ContentAvailability> watchAvailability(String entityId);
  Future<List<SearchHit>> search(SearchQuery query);
}

abstract interface class PackRepository {
  Stream<PackState> watch(String packId);
  Future<void> install(String packId);
  Future<void> cancel(String packId);
  Future<void> removeContent(String packId);
}
```

静态服务路径设计：`/content/v1/index.json` 返回包摘要；`/content/v1/packs/{packId}/{version}/manifest.json` 返回文件、大小、摘要和兼容范围；资源使用不可变的带版本路径。可用 ETag 检查索引变化。部署域名在实施发布阶段配置。

manifest 示例为协议占位数据，不是可发布包：

```json
{
  "schemaVersion": 1,
  "packId": "country-egypt-zh-cn",
  "contentVersion": "1.0.0",
  "minReaderSchema": 1,
  "countryIds": ["egypt"],
  "coverage": "deep",
  "files": [
    {"path": "articles.json", "bytes": 120000, "sha256": "<64 位摘要>"},
    {"path": "media/giza.webp", "bytes": 240000, "sha256": "<64 位摘要>"}
  ]
}
```

安装状态：notInstalled → queued → downloading → verifying → installing → installed；任何阶段可进入 failed，更新时可显示 updateAvailable。内容深度 basic/deep 不随断网改变。

安装流程：检查兼容版本与空间 → 暂存下载 → 校验长度、摘要及内容结构 → 导入独立内容版本 → 数据库事务切换 activeVersion → 清理旧版本。应用异常退出后恢复到旧可用版本或继续验证暂存文件。远端支持 Range 时续传，不支持时明确重新下载；不要假装续传。

取消保留已安装旧版；移除包只移除内容和搜索索引，不删除笔记与收藏。共享媒体按引用关系保留。包内路径只能写入本包目录，拒绝绝对路径与越级路径。

原生首次安装内置基础地图、国家目录和一个完整示范包，其余包按需下载。Web 首次使用需要加载站点；静态壳缓存与内容存储分开实现，浏览器清理或配额回收时检测缺失并提供重新下载。Web 离线能力通过明确验收后才标记可用。

## 8. 地图实现规格

### 8.1 数据与精度

新地图要保存 countryId/regionId、Polygon/MultiPolygon、内环、代表标注点与包围盒；不能沿用当前仅按洲归并的数据结构作为国家命中来源。地名与国家目录来自同一内容版本。

几何资产预处理为世界、大洲、国家三个细节等级；低缩放加载简化形状，选中国家才加载更高细节。河流、湖泊、山脉与沙漠使用独立图层，真实来源记录在资源清单中。首发最大缩放限制在教育图集尺度，不承诺街道导航。

`GeoProjection` 封装投影。P0 使用等经纬投影便于离线绘制与定位，说明高纬面积变形；面积比较使用资料数字。投影统一处理跨日期变更线、多岛国家、极地区域和洞。3D 地球在 P1 作为独立渲染适配器，不阻塞二维流程。

### 8.2 绘制与交互

- 绘制顺序：海洋 → 陆地/国家 → 自然地理 → 选中轮廓 → 地点 → 标签与控制器。
- 可见区域筛选后再绘制；离屏数据不参与标签布局。缓存投影路径并复用。
- 命中流程：屏幕点逆变换 → 包围盒候选 → 多边形包含判断 → 选择国家；孔洞与海域不误判。
- 小国提供屏幕尺寸固定的可点标注与搜索路径。多个近邻命中时显示可选择列表。
- 标注按“选中地点、首都、主要国家、一般地点”排序；碰撞避让，密集地点聚合。引线末端落在真实定位点。
- 缩放和平移时控制器与标签保持可读尺寸；国家边界线宽不随缩放无限变粗。
- fitBounds 同时考虑手机底部面板、平板侧栏、安全区域和跨日界线包围盒。
- 地图对象有语义标签；提供同步地点列表作为无障碍替代路径。

绘制与语义机制参考 [CustomPainter 官方 API](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html)。性能目标是常用地图操作平滑，在确定的中端 Android 真机和 iPad 上用 profile 模式记录帧耗时；不以桌面浏览器结果代替真机验收。

## 9. 阅读、朗读与搜索

阅读位置按 articleId + blockId + fraction 保存，滚动节流并在退出/生命周期变化时补写。文章更新移除 blockId 时按迁移映射恢复；无映射则回到最近章节并保留完成状态。

朗读状态：idle/playing/paused/completed/unavailable/error。只允许一个播放会话；跨页面时显示迷你播放器，离开文章可暂停或继续。平台不支持精确字级回调时按段落高亮，并在暂停后从该段恢复；UI 不展示无法兑现的逐字卡拉 OK 或精确秒级拖动。来电、耳机断开与 App 后台行为在真机上验证。

中文搜索先规范空格和大小写，再匹配规范名、别名与关键词，标题结果优先于正文。首发中文二元词/编辑词条索引由内容制作工具生成。输入防抖，保留最近输入供返回恢复；清空输入显示建议，零结果提供修改词语与分类浏览。只有基础资料的结果标注“基础资料”，未下载包标注“需下载”。搜索标题不泄露理解题答案。

## 10. 旧版迁移

现有数据位于 SharedPreferences 键 `world_explorer.progress.v1`，内部 schemaVersion 为 1。迁移必须保留原始 JSON 快照，写入新库并核验后再标记成功，过程可重复而不重复插入。

| 旧字段 | 新位置 | 处理方式 |
| --- | --- | --- |
| nickname、avatar、onboarded | profile/preferences | 保留已设置内容；旧昵称不强制重填 |
| favorites | bookmarks | 按旧国家 ID 转为 country 类型收藏 |
| visited、lastCountryId | exploration_history | 保留历史记录与最近国家 |
| readTopics | reading_progress | 通过固定 country/topic → article ID 表映射完成状态 |
| readingPositions | legacy_story_progress / 新文章位置 | 有对应故事段映射时转换；没有时保留旧进度归档 |
| questions | notes | 保留正文、时间和国家关联 |
| completed、quizPositions | legacy_achievements | 归档旧成就，不把旧答题完成解释为新版所有文章已读 |
| voiceEnabled、textScale、speechRate、breakMinutes | preferences | 合法范围内保留；不要覆盖系统文本缩放 |

非法 ID 保留在迁移报告中，不悄悄删除原始数据。迁移失败可重试并返回可阅读状态。删除旧主题和页面前，先完成新导航、迁移验证与基础流程。

## 11. 备份恢复

备份结构含 formatVersion、exportedAt、appVersion、profile、bookmarks、readingProgress、notes 和 preferences，不含可重新下载的媒体。导入前验证格式和字段、展示条目数，再选择合并或覆盖。合并按稳定 ID 去重，笔记冲突保留副本；未知内容引用保留标题快照。覆盖在事务中执行并先保存当前记录快照，失败可回滚。

## 12. 可用性、媒体和性能目标

- 交互点击区域至少 48×48 逻辑像素；主要阅读正文默认 18，字号可放大，说明文字不承担唯一关键信息。
- 大字体下主按钮、答案、长地名和底部栏不裁切；颜色之外还有文字或形状表示状态。参考 [Flutter 无障碍检查项](https://docs.flutter.dev/ui/accessibility)。
- 可用宽度 <600 使用底部导航；600–1023 使用紧凑导航轨与弹性内容；≥1024 支持地图/列表与详情分栏。布局依据窗口宽度而非设备名称，参考 [Flutter 自适应布局指南](https://docs.flutter.dev/ui/adaptive-responsive/general)。
- 资源采用缩略图、正文图、放大图三级；首次列表不解码全部大图。完整图按需读取，禁止把设计稿中的整页图片当作应用界面。
- 本机搜索 160 篇首发文章的 P95 目标 <200ms；首页可交互冷启动目标 <2.5s，须在约定真机、release 模式和既定内容包体积下测量。
- 图片、地图、搜索和下载都有加载、空状态、错误、重试；保留上次可用内容，错误提示不覆盖用户笔记。
- 产品默认不收集位置、麦克风和账号资料。语音搜索加入时再按操作请求权限；地图浏览不依赖设备定位。

## 13. 开发里程碑

| 阶段 | 工作 | 退出条件 |
| --- | --- | --- |
| D0 文档与视觉 | 本文、页面规格、10 模块设计稿 | 功能与画面可追踪，设计方向一致 |
| D1 基础工程 | 路由、主题、组件、Repository、数据库、旧数据迁移 | 四入口切换、深链返回、旧收藏笔记迁移通过 |
| D2 一个完整国家 | 目录、十栏目、阅读、地标、图集、来源、收藏续读 | 国家—文章—地标—地图往返完整可用 |
| D3 地图与搜索 | 国家命中、多层级资产、标注、过滤与本机搜索 | 小国、多岛、长地名和未下载状态均可操作 |
| D4 学习与个人 | 专题、理解题、笔记、设置、备份恢复 | 答案可回读、笔记不丢、恢复可预览及回滚 |
| D5 内容发布 | 下载更新、故障恢复、审核工具、20 国内容 | 包校验与更新通过；内容达到功能清单的深度标准 |
| D6 发布验证 | Android/iOS 真机、适配、朗读、性能、离线 | 发布清单全部通过；Web 能力单独标记 |

现有工程可以提供语音、素材许可与部分内容的参考；页面结构与主题依新设计实现。内容核验、照片收集与客户端开发可以在依赖明确后并行安排；本文不假定已具备全部首发内容。

## 14. 验证与完成定义

单元测试：schema、关联完整性、地图投影/命中、搜索排序、下载状态机、迁移幂等、备份冲突处理。组件测试：四入口、阅读恢复、图片来源、错误重试、长文本、大字体。流程测试：搜索→国家→文章→地图→返回；收藏/笔记重启保留；离线已安装包；中断更新后恢复旧版。

地图专项覆盖：Polygon/MultiPolygon/孔洞、跨日期变更线、极区、小国、近邻地标、相同名称不同地点、面板遮挡后的 fitBounds。内容专项覆盖：十栏目、图片许可、来源日期、真实图片与创作插画区分、题目答案能追溯正文。

实现后执行 `flutter analyze`、`flutter test`、相应平台构建与关键真机流程。本次文档和生图不计作这些检查已通过。现有 39 项测试作为回归基础，但新版规则需按实际变化补充，不能只修改数量断言。

发布完成需同时满足：P0 功能可用、内容包符合深度要求、迁移与备份验证通过、无空操作按钮、实机离线与朗读通过、地图和照片来源完整，以及无阻断级可用性问题。
