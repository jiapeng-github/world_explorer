# 美国 · 界面原稿与开发交接

2026-11-08 · [原稿画廊](index.html) · [提示词与原图尺寸](imagegen-manifest.json)

| 原图 | 状态 | 实装对照 |
| --- | --- | --- |
| [01 概览与十栏目](images/01-usa-overview.png) | US01、US02 | 首图保留高峡谷视角和遮罩上的白色标题。三张路线图分别用南缘、纽约和费城独立厅。事实行的「50 个州」与「华盛顿特区」分开。目录补实际篇数与「下一站，去五大湖」来路。 |
| [02 平板与手机地图](images/02-usa-map.png) | US03、US04 | 取平板左画布、右详情、手机底部面板的比例。导航沿用 App 的平板侧栏和手机底栏。真实州界、水道、湖面和点位从 GIS 数据绘制。阿拉斯加和夏威夷的插图独立放缩，注明各自比例。地图缩放与摄像机聚焦以实际地理坐标为准。 |
| [03 大峡谷阅读与地点](images/03-usa-geography.png) | US05、US06 | 阅读保留「横图 → 剖面图 → 读图题」顺序。题目默认未选中，并补禁用确认。侵蚀图须体现下切、风化与岩壁退缩。热点用实际照片中的岩层条带和谷底河道，两个点都有等价文字。 |
| [04 历史与爵士乐](images/04-usa-history-culture.png) | US07、US08 | 原住民族的入口放在年代线之外，阅读引用族群自己的公开介绍。年代卡用可验证的实拍或档案。历史页和爵士乐阅读采用本页返回与工具；取消原稿中重复的 App 级按钮。爵士乐用原创两组节奏展示「一句乐句 / 另一句回应」。 |
| [05 城市日常与黄石](images/05-usa-daily-nature.png) | US09、US10 | 日常首图用可核对站点的纽约地铁或街景，三行分别进入三篇正文。底部保留「看看纽约在地图哪里」。黄石首图用老忠实间歇泉。剖面以蓝色水、受限通道和橙色热箭头表现条件，加简短的压力解释。 |
| [06 任务和我的发现](images/06-usa-explore-discoveries.png) | US11、US12 | 首屏活动依次对应 `usa-locate-arizona`、`usa-canyon-find-strata`、`usa-seen-or-guessed`。其余同类活动从分类进入。发现页数字读取本机，零记录时展示空态。 |
| [07 路线与观察表单](images/07-usa-journey-observation.png) | US13、US14 | 路线三个站点都可选。黄石卡片用老忠实间歇泉照片。表单使用来路的观察图，标签在窄屏移到输入框上方。草稿提示、禁用保存和任意一项填写后启用均为实装验收项。 |

图片参考以布局、层级、留白和控件尺寸为主。原稿中的地形、岩层画面、演出、档案文字和城市照片均为设计占位。正式内容与交互文案按[详细设计](DESIGN.md)和[内容计划](CONTENT_PLAN.md)核对。主按钮使用深色文字配橙色填充，交互控件有可访问标签。读图题和表单的禁用、反馈、重试及键盘状态由 Flutter 组件实现。

大峡谷地形表现依据 NPS 地质资料。黄石采用 NPS 说明的水、热和地下通道机制。历史节点所用档案以美国国家档案馆条目为准。 [大峡谷地质](https://www.nps.gov/grca/learn/nature/grca-geology.htm) · [黄石地热系统](https://home.nps.gov/yell/learn/nature/hydrothermal-systems.htm) · [第十三修正案](https://www.archives.gov/milestone-documents/13th-amendment) · [民权法案](https://www.archives.gov/milestone-documents/civil-rights-act)
