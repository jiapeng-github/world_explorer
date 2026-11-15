# 美国模块 · Flutter 实现记录

应用 0.6.0+6 · 内容包 2026.11.8.1 · 2026-11-09

从「百科 → 美国」进入「从大峡谷出发」。世界地图点选美国后，可从国家卡片进入同一套内容。国家页的「在地图上看看」和目录的「打开美国地图」通往美国区域图。

- 十栏各 3 篇，共 30 篇正文。提供「沿着山河走」「走进城市」「循着历史找」三条路线、12 处可读地点、24 道闭合题和 6 项开放观察。大峡谷地点另有自由笔记。
- 区域地图显示相连 48 州、阿拉斯加、夏威夷及华盛顿特区。相连各州和阿拉斯加采用各自的 Albers 投影，夏威夷采用局部等距圆柱投影。州面、河道、湖面和地点可点选，搜索区分华盛顿州与华盛顿特区。切换区域时保留各自的镜头、图层和选点。
- 大峡谷照片观察带入所选图，读图题可回到原文证据。开放观察保存本机草稿，发现页根据实际阅读、地点浏览和笔记计数。爵士练习在点按后显示两组四拍，可跟随亮起的拍子练习，系统点击音受设备设置影响。
- 36 项实拍、卫星影像和档案随包提供。金门海峡、街牌、铜管乐队和峡谷的热点按实拍重新定位。基拉韦厄图片使用公园管理局的观景点实拍，作品页未标注拍摄日期。 [图片、署名与许可](../../../tool/content/editorial/usa_assets.json)

州界采用美国人口普查局 2025 年 1:20m 制图边界。湖面与两条河的原始几何来自 Natural Earth 1:10m，地形来自 NASA Blue Marble。夏威夷区域全图以该州界数据所载岛屿为准，插图分别计算比例。 [美国人口普查局州界](https://www.census.gov/geographies/mapping-files/time-series/geo/cartographic-boundary.2025.html) · [Natural Earth 水文](https://www.naturalearthdata.com/downloads/10m-physical-vectors/) · [NASA Blue Marble](https://science.nasa.gov/earth/earth-observatory/blue-marble-next-generation/)

[14 张运行截图](implemented/index.html)覆盖手机和宽屏地图，可与[确认原稿](index.html)逐屏对照。布局测试另覆盖 320×568 和 1.5 倍字号。交互测试覆盖峡谷路线与证据、州面命中、跨日期变更线、夏威夷区域定位题、州和特区别名以及观察草稿。未发布国家的世界地图「即将上线」禁用状态也通过了回归测试。

Flutter 静态检查通过，102 项 Flutter 测试、23 项 Python 测试和美国内容包校验通过。Web JavaScript 版和 Android arm64 调试包已生成。本机浏览器验证了「美国概览 → 大峡谷读图题 → 水系地图」、夏威夷区域切换及返回时恢复大峡谷选点。APK 已检查版本与离线资产，真机安装仍待验证。

- [Android arm64 调试 APK](../../../build/app/outputs/flutter-apk/app-debug.apk)
- [Web 构建目录](../../../build/web/)
- [美国离线内容包清单](../../../build/content/2026.11.8.1/usa/manifest.json)

```sh
python3 tool/content/build_catalog.py
python3 tool/content/validate_catalog.py
python3 tool/packs/atlas_packs.py validate build/content/2026.11.8.1
flutter analyze --no-pub
flutter test --no-pub
flutter test --no-pub test/usa_experience_test.dart --dart-define=CAPTURE_USA=true
```
