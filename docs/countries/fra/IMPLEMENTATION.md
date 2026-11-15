# 法国模块实现记录

2026-11-11验收；App 0.8.0+8，内容版本2026.11.10.1。按确认的生图设计制作 Flutter 页面，未使用 Stitch。

已接入30篇正文（每篇450–650汉字、五段）、十个栏目、12处地点、24道练习、6项开放观察、三条阅读路线、历史时间线、收藏和本机笔记。36项素材保留署名、许可、来源、日期和哈希，三个文字练习卡明确标注原创示意。科学关系图由 Flutter 绘制。

地图使用 Natural Earth 10m 真实轮廓和河流，NASA 地形背景。欧洲部分采用 Lambert-93；五个海外地区使用独立局部投影与比例尺。科西嘉为真实岛面，法属圭亚那保留大陆范围；马约特注明实际管辖和主权主张。地图支持搜索、地区切换、缩放、点线面选择和手机可拖动详情面板。海外世界定位图提供范围说明，定位题支持文字等价选项。

视觉保留浅色、深海蓝与橙色、实景主图、照片目录卡、三路线卡和阅读页图解。正式照片采用获许可的真实材料，构图、季节与设计生成图不会完全一致。图解为教学关系示意，不提供实时潮汐或火山状态。历史影像不被用作未经校准的冰川前后测量。

验收：Flutter静态分析无问题；117项Flutter测试通过，含法国7项布局/地图/练习/持久化测试；23项Python测试通过；内容与法国发布包引用、字节、哈希校验通过。未做Android真机安装验收。

[实际页面截图](implemented/index.html) · [设计基线](DESIGN.md)

主要代码：`lib/features/encyclopedia/fra_overview.dart`、`lib/features/atlas/fra_atlas_screen.dart`、`lib/map_engine/fra_*`、`lib/features/reader/fra_diagrams.dart`。正文及元数据生成器为 `tool/content/author_fra.py`，素材导入脚本为 `tool/content/import_fra_media.py`。

发布包位于 `build/france-release/2026.11.10.1`，约6.9MB。地图资源随App打包，不能只安装内容包来升级旧版地图代码。
