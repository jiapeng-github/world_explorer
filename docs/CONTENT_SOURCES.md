# 首批内容包与核验记录

内容文件：`assets/content/catalog.json`。核验日期：2026-10-26。

面向约 8 岁儿童，首批包括埃及、中国、巴西三个目的地。每国包含 8 张基础资料卡、6 篇百科文章（每篇 3 个小节）、3 处地标、4 个时间线节点、1 篇三段故事和 3 道练习题；另有河流、自然和生活三个跨国主题。叙述为重新组织的中文儿童读物文案，未复制来源中的长段原文。

## 来源与内容对应

| 目的地 | 内容范围 | 一手资料 |
| --- | --- | --- |
| 埃及 | 非洲东北部、西奈半岛与海洋位置 | [埃及国家信息服务](https://africa.sis.gov.eg/english/african-countries/egypt/)；[埃及官方旅游机构地理介绍](https://www.experienceegypt.eg/en/home/Geography) |
| 埃及 | 尼罗河、农田与城镇的位置关系 | [NASA：Nile Bend, Egypt](https://science.nasa.gov/earth/earth-observatory/nile-bend-egypt-8770/) |
| 埃及 | 灌溉与沙漠农业 | [欧盟 Copernicus：Desert agriculture in Egypt](https://eu-space.europa.eu/components/earth-observation-copernicus/image-of-the-day/desert-agriculture-egypt) |
| 埃及 | 椰枣树的传统用途与手艺 | [埃及民俗档案：Date Palm](https://www.nfa-eg.org/En/Inventory_Details.aspx?ID=278) |
| 埃及 | 金字塔与古代陵墓遗迹 | [UNESCO：Memphis and its Necropolis](https://whc.unesco.org/en/list/86/) |
| 中国 | 亚洲东部、太平洋西岸 | [中国政府网：中华人民共和国版图](https://www.gov.cn/govweb/guoqing/2005-06/15/content_2615215.htm) |
| 中国 | 地形多样性 | [生态环境部转载国务院全国主体功能区规划](https://www.mee.gov.cn/zcwj/gwywj/201811/t20181129_676510.shtml) |
| 中国 | 长江搬运泥沙进入东海 | [NASA：Heavy Sediment from the Yangtze River](https://science.nasa.gov/earth/earth-observatory/heavy-sediment-from-the-yangtze-river-9428/) |
| 中国 | 大运河的人工水道、分期建设与运输 | [UNESCO：The Grand Canal](https://whc.unesco.org/en/list/1443/) |
| 中国 | 端午龙舟活动与地区差异 | [UNESCO：Dragon Boat festival](https://ich.unesco.org/en/RL/dragon-boat-festival-00225)；[国务院英文网：Traditional, modern customs merge](https://english.www.gov.cn/news/202406/10/content_WS6666c0bdc6d0868f4e8e7f7b.html) |
| 中国 | 长城的分期建设和建筑组成 | [UNESCO：The Great Wall](https://whc.unesco.org/en/list/438/) |
| 巴西 | 南美洲、赤道与大西洋 | [IBGE Educa：Território](https://educa.ibge.gov.br/jovens/conheca-o-brasil/territorio/20591-introducao.html) |
| 巴西 | 亚马孙雨林并非全部位于巴西 | [巴西旅游部：Investment Guide to Brazil，Brazil in Numbers](https://www.gov.br/turismo/pt-br/acesso-a-informacao/acoes-e-programas/programas-projetos-acoes-obras-e-atividades/portal-de-investimento/arquivos/investment-guide-to-brazil-2019-final-5-mb-1.pdf/%40%40download/file)；仅采用地理事实，不采用该报告中的旧人口统计 |
| 巴西 | 洪泛森林、高地森林、河湖与水生动物 | [UNESCO：Central Amazon Conservation Complex](https://whc.unesco.org/en/list/998/) |
| 巴西 | 河边社区、船与流动诊所 | [巴西卫生部：Serviços](https://www.gov.br/saude/pt-br/composicao/saps/equidade-em-saude/povos-e-comunidades-tradicionais/servicos/servicos) |
| 巴西 | 卡波耶拉与音乐、动作、文化传承 | [UNESCO：Capoeira circle](https://ich.unesco.org/en/RL/capoeira-circle-00892)；[巴西文化部介绍](https://www.gov.br/cultura/pt-br/assuntos/noticias-defeso-eleitoral/roda-de-capoeira-patrimonio-cultural-do-brasil-une-luta-danca-e-musica/) |
| 巴西 | 欧鲁普雷图历史城镇与遗留建筑 | [UNESCO：Historic Town of Ouro Preto](https://whc.unesco.org/en/list/124/) |

UNESCO 非遗页面的直接读取遇到验证码时，仅使用其官方搜索索引中可核对的条目内容，并辅以公开可读的官方机构资料；未绕过验证码。文中不包含有争议的长城“从月球可见”说法、人口排名、河流长度排名或会随时间改变的统计数字。

## 内容约定

- `checkedAt` 表示本次资料核验日期，不表示原网页的发布日期。
- 地图点为教学用代表点：埃及 `26.8, 30.8`，中国 `35, 105`，巴西 `-10, -52`，顺序为纬度、经度。它们不是测量得到的国家质心，也不是国界或首都位置。
- `continent` 是目的地筛选标签；埃及资料卡另行说明其跨越非洲和亚洲的地理情况。
- 国家介绍只选择少量观察主题。文中使用“一些地方”“部分社区”等限定语，不把某项习俗或生活方式归给全国每个人。
- 每国首题 `type=location`，选项 ID 是国家 ID；后两题是单选题。`answerId` 必须存在于对应题目的 `options` 中。
- 自主画图、设计水道等活动是原创教学提示，不作为事实来源。
- 国家百科与地图预览采用实景照片，署名见 [PHOTO_CREDITS.md](PHOTO_CREDITS.md)。故事、欢迎和主题旅程保留 AI 插画，并继续标注其用途。
- `greeting` 是中文欢迎语，不表示当地语言教学或真实人物发言。

## 扩充内容时

沿用每国六主题与故事、练习、来源的结构；先核验知识，再写儿童能理解的短句。每道题的解释应能从已读内容中找到依据。新增图片时记录来源与使用许可，勿将搜索缩略图、合成图或不同地点的照片当成实地证据。

## 0.2 版补充核验（2026-10-26 至 2026-10-27）

### 埃及

百科扩展为 18 个小节，并增加国家概览、地标观察和历史时间线。

- [埃及国家信息服务：地理位置](https://africa.sis.gov.eg/english/african-countries/egypt/)
- [NASA：尼罗河弯道与沿岸农田](https://science.nasa.gov/earth/earth-observatory/nile-bend-egypt-8770/)
- [欧盟 Copernicus：埃及沙漠农业](https://eu-space.europa.eu/components/earth-observation-copernicus/image-of-the-day/desert-agriculture-egypt)
- [埃及民俗档案：椰枣树的知识与手艺](https://www.nfa-eg.org/En/Inventory_Details.aspx?ID=278)
- [UNESCO：孟菲斯及其金字塔遗址](https://whc.unesco.org/en/list/86/)
- [埃及国家信息服务：基本国情](https://sis.gov.eg/en/egypt/basic-information/)
- [UNESCO：努比亚遗址保护](https://whc.unesco.org/en/list/88/)
- [埃及官方旅游：地理环境](https://www.experienceegypt.eg/en/home/Geography)

### 中国

百科扩展为 18 个小节，并增加国家概览、地标观察和历史时间线。

- [中国政府网：地理位置](https://www.gov.cn/govweb/guoqing/2005-06/15/content_2615215.htm)
- [生态环境部：自然地理与地形](https://www.mee.gov.cn/zcwj/gwywj/201811/t20181129_676510.shtml)
- [NASA：长江入海口的泥沙](https://science.nasa.gov/earth/earth-observatory/heavy-sediment-from-the-yangtze-river-9428/)
- [UNESCO：中国大运河](https://whc.unesco.org/en/list/1443/)
- [UNESCO：端午节](https://ich.unesco.org/en/RL/dragon-boat-festival-00225)
- [UNESCO：长城](https://whc.unesco.org/en/list/438/)
- [中国国情：位置与基本资料](https://www.locpg.gov.cn/fwzn/zggq.htm)
- [中国政府：地形地貌](https://www.gov.cn/lianbo/bumen/202312/P020231230296808058475.pdf)
- [UNESCO：九寨沟](https://whc.unesco.org/en/list/637/)
- [教育部：国家通用语言文字法](https://qspfw.moe.gov.cn/html/sublaws/20260104/23773.html)

### 巴西

百科扩展为 18 个小节，并增加国家概览、地标观察和历史时间线。

- [巴西 IBGE 教育：领土与位置](https://educa.ibge.gov.br/jovens/conheca-o-brasil/territorio/20591-introducao.html)
- [巴西旅游部：巴西与亚马孙地区](https://www.gov.br/turismo/pt-br/acesso-a-informacao/acoes-e-programas/programas-projetos-acoes-obras-e-atividades/portal-de-investimento/arquivos/investment-guide-to-brazil-2019-final-5-mb-1.pdf/%40%40download/file)
- [UNESCO：亚马孙中心保护区](https://whc.unesco.org/en/list/998/)
- [巴西卫生部：河边社区与流动诊所](https://www.gov.br/saude/pt-br/composicao/saps/equidade-em-saude/povos-e-comunidades-tradicionais/servicos/servicos)
- [UNESCO：卡波耶拉圆圈](https://ich.unesco.org/en/RL/capoeira-circle-00892)
- [巴西文化部：卡波耶拉的动作、舞蹈与音乐](https://www.gov.br/cultura/pt-br/assuntos/noticias-defeso-eleitoral/roda-de-capoeira-patrimonio-cultural-do-brasil-une-luta-danca-e-musica/)
- [UNESCO：欧鲁普雷图历史城镇](https://whc.unesco.org/en/list/124/)
- [联合国粮农组织：巴西的生态区域](https://www.fao.org/brasil/fao-no-brasil/glance/pt)
- [UNESCO：伊瓜苏国家公园](https://whc.unesco.org/en/list/355/)
- [UNESCO：巴西利亚](https://whc.unesco.org/en/list/445/)
- [巴西驻美使馆：国家概览](https://www.brasilemb.org/brazil-at-a-glance-3/)

面积使用便于儿童理解的近似值，不混用海域面积或最新人口统计。时间线只是选取的观察窗口，不代表完整国家历史；自然区域标记为教学参考点。地图按 Natural Earth 的大洲分类做视觉分组，不表示精确大洲分界、海拔或气候。

地图还使用 [Natural Earth 1:110m Rivers](https://www.naturalearthdata.com/downloads/110m-physical-vectors/110m-rivers-lake-centerlines/) 与 [Lakes](https://www.naturalearthdata.com/downloads/110m-physical-vectors/110m-lakes/)，来自官方维护者仓库 nvkelso/natural-earth-vector。水系几何与陆地使用相同投影；缩放后仍为简化数据，不用于导航或测量。
