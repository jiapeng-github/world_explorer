# 新版实景、地图与字体来源

记录日期：2026-11-06。运行界面引用真实照片和地理数据；生成设计稿用于视觉还原参考，不作为整页背景或地理事实素材。图片作者、来源与许可保存在 `assets/atlas/catalog.json` 的 `media` 字段及应用内来源面板。

## 实景照片

| 文件 | 画面说明 | 作者 | 来源及许可 |
| --- | --- | --- | --- |
| `assets/atlas/nile-aswan.jpg` | 尼罗河沿岸水域与景观 | Eszter Kisgyura | [原图](https://unsplash.com/photos/7ObNCbySGGc) · [Unsplash License](https://unsplash.com/license) |
| `assets/atlas/tree-frog.jpg` | 哥斯达黎加的蛙类 Duellmanohyla uranochroa；不是巴西实拍 | Antony Abarca Zuniga | [原图](https://unsplash.com/photos/close-up-of-a-green-frog-with-bright-red-eyes-w2qPD1JHs40) · [Unsplash License](https://unsplash.com/license) |
| `assets/atlas/mount-fuji.jpg` | 日本富士山与湖面倒影 | CHEN HENG | [原图](https://unsplash.com/photos/mount-fuji-reflects-beautifully-on-a-tranquil-lake-Yktjlc6322Y) · [Unsplash License](https://unsplash.com/license) |
| `assets/atlas/geiranger.jpg` | 挪威盖朗厄尔峡湾 | Alex Korolkoff | [原图](https://unsplash.com/photos/scenic-view-of-a-fjord-with-mountains-and-ships-cajBHH285sc) · [Unsplash License](https://unsplash.com/license) |
| `assets/atlas/school.jpg` | 印度金奈一间学校教室；不代表所有学校或其他国家 | Haseeb Modi | [原图](https://unsplash.com/photos/a-group-of-children-sitting-at-desks-in-a-classroom-OcDJhBm8Jnc) · [Unsplash License](https://unsplash.com/license) |
| `assets/atlas/florence.jpg` | 意大利佛罗伦萨城市景观 | Jonas Smith | [原图](https://unsplash.com/photos/top-view-of-florence-italy-WCGyAnAcCiA) · [Unsplash License](https://unsplash.com/license) |
| `assets/atlas/elephant.jpg` | 肯尼亚安博塞利的大象与幼象 | Neil and Zulma Scott | [原图](https://unsplash.com/photos/brown-elephant-on-green-grass-field-during-daytime-pHztxoXCvAw) · [Unsplash License](https://unsplash.com/license) |
| `assets/photos/egypt-giza.jpg` | 吉萨金字塔群 | Ricardo Liberato；后期 Ikiwaner | [原图](https://commons.wikimedia.org/wiki/File:All_Gizah_Pyramids.jpg) · [CC BY-SA 2.0](https://creativecommons.org/licenses/by-sa/2.0/) |
| `assets/photos/china-wall.jpg` | 金山岭长城 | Severin.stalder；调色 Brandmeister | [原图](https://commons.wikimedia.org/wiki/File:The_Great_Wall_of_China_at_Jinshanling-edit.jpg) · [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/) |
| `assets/photos/brazil-iguazu.jpg` | 伊瓜苏瀑布，巴西一侧 | Mariordo（Mario Roberto Durán Ortiz） | [原图](https://commons.wikimedia.org/wiki/File:Iguazu_Falls_Panorama_2009.jpg) · [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) |

照片以下载时取得的尺寸存入工程，界面按容器裁切展示，不增加或改造景物。Commons 照片的既有缩放处理记录见 [PHOTO_CREDITS.md](../PHOTO_CREDITS.md)。派生图片继续遵循各自许可；不将照片独立出售或宣称为自有摄影作品。

## 地图与地形

- `assets/atlas/countries.geojson`、`country-properties.json`：Natural Earth 1:110m 国家几何与属性，用于当前 177 个国家与地区基础条目。[数据页面](https://www.naturalearthdata.com/downloads/110m-cultural-vectors/110m-admin-0-countries/)。
- `assets/atlas/countries-detail.geojson`：Natural Earth 5.1.1 的 1:50m 国家几何，通过 `tool/maps/build_detail.py` 转换并保留稳定 ID。[数据页面](https://www.naturalearthdata.com/downloads/50m-cultural-vectors/50m-admin-0-countries-2/)。
- `assets/maps/` 河流、湖泊和概览陆地：Natural Earth 1:110m。[物理地理数据](https://www.naturalearthdata.com/downloads/110m-physical-vectors/)。以上数据均为 [Public domain](https://www.naturalearthdata.com/about/terms-of-use/)。
- `assets/atlas/earth-relief.jpg`：NASA Blue Marble Next Generation，NASA Earth Observatory / Reto Stöckli，2004 年地球影像合成与地形可视化。[项目资料](https://science.nasa.gov/earth/earth-observatory/blue-marble-next-generation/base-topography-bathymetry/)。这是历史合成底图，不是实时天气或当天卫星照片。

地图适合地理概览。比例尺会省略小岛和局部细节；名称与边界继承数据源，不能用于精确导航或距离测量。

- 埃及区域地形及水道见[埃及底图记录](../../assets/atlas/egypt-relief-source.json)与[地图数据说明](../../tool/maps/README.md)，埃及 36 项照片和影像见[素材清单](../../tool/content/editorial/egypt_assets.json)。

## 字体与软件

`assets/images/NotoSansSC.ttf` 为 Noto Sans SC，SIL Open Font License 1.1；分发时保留 [FONT_LICENSE.txt](../FONT_LICENSE.txt)。Flutter 及依赖许可可在应用“来源与许可 → 开源软件许可”查看。新增媒体须同步记录图注、作者、来源和许可，发布工具会拒绝缺失字段的包。
