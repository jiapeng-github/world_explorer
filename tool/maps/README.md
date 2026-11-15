# 地图细节数据

概览地图使用 Natural Earth 1:110m；`assets/atlas/countries-detail.geojson` 提供 1:50m 国家细节。它们表示数据源中的国家与地区，不是主权实体的完整清单，也不是导航或测量地图。

```bash
curl --fail --location https://naciscdn.org/naturalearth/50m/cultural/ne_50m_admin_0_countries.zip --output /tmp/ne_50m_admin_0_countries.zip
python3 tool/maps/build_detail.py /tmp/ne_50m_admin_0_countries.zip
python3 -m unittest discover -s tool/maps -v
```

转换器只需 Python 标准库。它读取官方 SHP/DBF，按 `ADM0_A3` 对应既有目录，保留稳定 ID、MultiPolygon 多岛与内环，转为 GeoJSON 右手定则，坐标保留 5 位小数。输出记录源版本、压缩包 SHA-256 和回退实体。当前来源版本 5.1.1，177 个实体均有 50m 几何，没有比例尺回退。

来源：[Natural Earth 1:50m countries](https://www.naturalearthdata.com/downloads/50m-cultural-vectors/50m-admin-0-countries-2/)，[Public domain 使用条款](https://www.naturalearthdata.com/about/terms-of-use/)。

## 中国自然地理地图

`assets/atlas/china-rivers.geojson` 从 Natural Earth 1:10m 官方河流 SHP/DBF 提取，版本 5.0.0。长江包含长江与金沙江的原始河道段（1538 个顶点）；黄河 1925 个顶点。保留 MultiLineString 分段，不跨缺口人为连线；地图点击按真实折线距离计算，不使用截图坐标。

```bash
curl --fail --location https://naciscdn.org/naturalearth/10m/physical/ne_10m_rivers_lake_centerlines.zip --output /tmp/world-explorer-ne-rivers.zip
python3 tool/maps/build_china_rivers.py /tmp/world-explorer-ne-rivers.zip
```

来源：[Natural Earth 1:10m rivers](https://www.naturalearthdata.com/downloads/10m-physical-vectors/10m-rivers-lake-centerlines/)，公有领域；下载归档 SHA-256 与来源原始 ID 随 GeoJSON 保留，核查日期 2026-11-07。此比例尺仅支持自然地理观察，不能作为真实导航、工程河道或省级行政地图。主图保留原始陆地、海岸与岛屿几何，取景至北纬 3–55 度、东经 72–138 度；部分小岛不在现有数据比例尺中，不绘制猜测边界或虚构海岛。

`CountryLearningMap` 提供地图、阅读与定位题共用画布，`CountryMapController` 在图层切换、详情进入返回时保留镜头。可选对象为真实河流 ID、内容包地点 ID 和明示为示意位置的自然区域标签。区域标签的圆点不是区域边界。


## 埃及自然地理地图

用同一份 Natural Earth 官方河流归档生成 `assets/atlas/egypt-waterways.geojson`：

```bash
python3 tool/maps/build_egypt_waterways.py /tmp/world-explorer-ne-rivers.zip
```

保留尼罗河主干、罗塞塔及达米埃塔主要支流和苏伊士运河的原始折线及分段。人工航道画虚线。图上地标为观察点，不代表地理对象的外边界。比例尺为 1:10m，适合区域地理学习。区域地形图来自 [NASA GIBS](https://nasa-gibs.github.io/gibs-api-docs/access-basics/)，WGS84 栅格西 22°E、南 20°N、东 39°E、北 35°N，署名、请求与摘要见 [底图记录](../../assets/atlas/egypt-relief-source.json)。
