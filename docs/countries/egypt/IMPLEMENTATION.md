# 埃及模块 · Flutter 实现记录

应用 0.5.0+5 · 内置内容 2026.11.8 · 2026-11-08

入口：「百科 → 埃及」，也可从发现页、搜索、世界地图或文章回到相同内容。世界地图上的埃及国家选择仍留在世界地图；从国家页的地图入口、埃及地点或带 country 参数的链接进入埃及区域地图。

- 国家概览、十栏目目录、三条可自由选择的路线、四条精选历史线索、任务目录及「我的埃及发现」均已接入。包含 30 篇独立文章、12 处地点、24 道题（选择、定位、读图）和 6 项开放观察。
- 区域地图以 NASA GIBS 的区域地形栅格和 Natural Earth 的真实水道线为底，显示尼罗河、两条主要入海支流和苏伊士运河。手机使用可收展的详情面板，平板使用右侧详情栏。列表能搜地点别名，地图返回保留缩放、图层和选点。
- 阅读、图解、照片热点与活动使用同一份资料。答题可回读指定段落，开放观察可恢复草稿，笔记和发现统计来自本机真实记录。原有文章、地点、题目及正确选项的 ID 保留；旧段落恢复至新版首段，原进度记录仍留存。
- 36 项照片、馆藏影像和卫星影像均为项目资源，来源和许可见[埃及素材记录](../../../tool/content/editorial/egypt_assets.json)。底图的坐标范围、分辨率与文件摘要见 [NASA GIBS 底图记录](../../../assets/atlas/egypt-relief-source.json)。地图适用于自然地理观察，不用于导航。

[14 个主要页面的运行截图](implemented/index.html)可与[已确认原图](index.html)对照。原稿照片位置已换为实际素材：尼罗河首图为 NASA 弯道影像，库沙里观察用两份成品，椰枣和灯笼对照图各自标明来源，吉萨热点按实际照片重新取点。示意图上的位置与比例只用于教学；地图上的标记使用地理坐标。阿布辛拜勒、菲莱均显示迁建后现址。

本地验收命令：

```sh
python3 tool/content/build_catalog.py
python3 tool/content/validate_catalog.py
python3 tool/packs/atlas_packs.py build --country egypt --version 2026.11.8
python3 tool/packs/atlas_packs.py validate build/content/2026.11.8
flutter analyze --no-pub
flutter test --no-pub
flutter test --no-pub test/egypt_experience_test.dart --dart-define=CAPTURE_EGYPT=true
```

截图覆盖标准手机和平板地图。布局测试另覆盖 430×932、1024×768、320×568（1.5 倍字号）。交互测试覆盖尼罗河路线、图上答题、证据回读、地图镜头返回、地点别名、吉萨近照进入观察、键盘与草稿保存。


本次验收：Flutter 静态分析无问题，94 项 Flutter 测试、23 项 Python 测试和埃及内容包校验通过。Web 正式构建已在本机浏览器验证从概览进入地图、切换水系、选中三角洲。Android 调试 APK 版本号为 0.5.0（5），已核对安装包包含区域地形图和水道，尚未在实体设备上安装验证。

- [Android 调试 APK](../../../build/app/outputs/flutter-apk/app-debug.apk)
- [Web 构建目录](../../../build/web/)
- [埃及内容包清单](../../../build/content/2026.11.8/egypt/manifest.json)
