# 南非验证记录

2026-11-11。为避免其他开发任务清理共享构建缓存，最终Flutter验证在 `/private/tmp/zaf-final-verify` 的工程副本执行；副本保留当时全部模块，未删除其他国家以绕过编译。

## 结果

- `flutter analyze --no-pub`：No issues found。
- 36项Flutter测试全部通过：南非正式页面与旧预览、共享中国地图、笔记持久化、内容目录。
- 390×844手机、1194×834平板地图、320×568与1.5倍文字：无布局异常。
- 30篇文章及24道练习逐项打开；11种图解支持点击及大字体。
- 空白笔记禁用保存；未保存草稿可恢复；保存后记录仍存在，新观察表单为空。
- 企鹅阅读作答进入正式journal记录。
- 地图选中厄加勒斯角后，“查看地点”打开对应详情。
- 10m南非多边形包含布隆方丹，排除莱索托和埃斯瓦蒂尼的内部测试点；两条河道保留源数据段，区域地形可读取。
- 通用内容校验通过；南非专用校验检查30篇、10栏目、12地点、24题、6观察、3路线、证据引用、图片哈希和国界内环。
- 内容包构建及验证通过：`2026.11.11-zaf.1`，4,101,218字节，14张媒体。

```sh
flutter test --no-pub \
  test/zaf_experience_test.dart \
  test/zaf_preview_test.dart \
  test/china_map_test.dart \
  test/atlas_persistence_test.dart \
  test/catalog_test.dart \
  --dart-define=CAPTURE_ZAF=true
```

## Android 构建

调试APK已构建成功，使用既有代理完成sqlite3原生库下载。APK中已核对正式南非目录、30篇文章、专属国界、河流、区域地形和企鹅近景资源。

交付位置：`build/zaf-delivery/world-explorer-zaf-debug.apk`。校验信息：同目录 `build-info.json`。未安装到用户设备，未改动Android Studio配置。

## 视觉检查

真实截图保存在 `implemented/`，总览 `implemented/index.html`。已逐次修订首页主图高度、品牌栏、目录照片卡、日常生活标题、观察输入提示、国界描边、邻国标注、地图地点卡与聚合文字。摄影以真实授权素材替换生成效果图里的概念画面。

本轮未在实体Android设备上测试，也未向外部服务器发布。模拟输入与截图验证不代表触屏手感和系统语音服务已经完成真机验收。
