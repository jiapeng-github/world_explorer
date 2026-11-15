# 中国模块 · 生图提示词与原图记录

完成日期：2026-11-07。使用内置 `image_gen`，每组独立生成。共同参考为已认可的 `docs/redesign/images/03-encyclopedia.png`，仅用于风格约束。

原始生成图已原样复制到本目录 `images/`，无二次绘画、裁切或修改。六组共展示十二个界面状态（地图含一张平板和一张手机）。这些是概念设计，图内风景为生成的实景风格示意，不能作为正式地点照片或地图资产。地图位置、教学图形及细节文字在实现时按 DESIGN.md 校核。

## 1. 中国概览与栏目目录

- 成品：[01-china-overview.png](images/01-china-overview.png)
- 原图：`/Users/penn/.codex/generated_images/01a17387-e5ec-78d1-9384-997996b6e83a/exec-7ef77ee1-fe61-40e1-8c63-3bfde12f0e6f.png`
- 输入：已认可百科设计稿，style reference，不是待替换 App 截图。

```text
Use case: ui-mockup. Create a polished high-fidelity UI design board for the CHINA module of the existing Chinese children's geography encyclopedia app 世界大百科, for an 8-year-old reader. Reference image is STYLE ONLY: preserve its modern geographic editorial layout, white surfaces, navy #12395B and ink #12243A typography, pale canvas #F4F7FB, clear orange #FF9A3D actions, large realistic scenic photography, understated 16px card corners, calm generous spacing and readable Noto Sans SC Chinese. Do not reproduce Egypt or its country list. Do not use offline/content-completeness badges, rewards, coins, avatars, cartoon mascots, watermark, or dense tiny text. Photos are visual concept placeholders. All screen text is Chinese except CHINA. Flat front-facing screens, no perspective or decorative objects, subtle device outline only. Header back button and bookmark. Country details and readers have contextual bottom actions, NOT the global four-tab navigation. Every panel must have enough whitespace and readable large text. Follow requested Chinese copy exactly. Outside the screens put a tiny understated footer “中国模块 · 界面概念设计”. Square board with TWO tall mobile screens side by side, each approximately 430x932 proportional.
LEFT: country overview. Top 35% gorgeous realistic Jinshanling Great Wall winding through lush layered mountains and blue sky, slight dark gradient for white title “中国” and small “CHINA”, subtitle “从高山到大海，发现中国”. Rounded white sheet below titled “先认识中国”, short copy “沿着山川、生活与文明，读懂这片土地。” Compact three facts “亚洲” “北京” “人民币” each small icon and proper captions “位置”“首都”“货币”. Row of three rich photo tiles “山河” (mountain river), “生活” (canal town), “文明” (palace architecture). Editorial question heading “你想先发现什么？”, two question rows “为什么有的地方高，有的地方低？” and “一条运河怎样连接远方？”. A clear outlined map button “在地图上看看”. Orange fixed bottom full-width button “从山河开始” in navy.
RIGHT: scroll destination page white header “中国 · 探索目录”, lead headline “把好奇心带到每一站”, slim progress-free mini-banner showing mountain, city, panda photos. Ten readable category rows in two columns, 5 rows total with navy line icon and tiny thumbnail where room: “国家名片”“地理与气候”“人们与语言”“日常生活”“饮食与物产”“艺术与节日”“城市与地标”“动物与生态”“历史故事”“有趣问题”. Below a wide photo feature of Jiuzhaigou lake caption “今天，去九寨沟看一看”, short caption “从湖泊和森林寻找线索”. Bottom navy button “打开中国地图”. Visually richer yet not more crowded than the reference.
```

## 2. 中国地图与地点面板

- 成品：[02-china-map.png](images/02-china-map.png)
- 原图：`/Users/penn/.codex/generated_images/01a17387-e5ec-78d1-9384-997996b6e83a/exec-e7424ba0-fa20-4a4f-8b88-02faf7b35b6a.png`
- 输入：已认可百科设计稿，style reference，不是待替换 App 截图。

```text
Use case: ui-mockup. Create a polished high-fidelity UI design board for the CHINA module of the existing Chinese children's geography encyclopedia app 世界大百科, for an 8-year-old reader. Reference image is STYLE ONLY: preserve its modern geographic editorial layout, white surfaces, navy #12395B and ink #12243A typography, pale canvas #F4F7FB, clear orange #FF9A3D actions, large realistic scenic photography, understated 16px card corners, calm generous spacing and readable Noto Sans SC Chinese. Do not reproduce Egypt or its country list. Do not use offline/content-completeness badges, rewards, coins, avatars, cartoon mascots, watermark, or dense tiny text. Photos are visual concept placeholders. All screen text is Chinese except CHINA. Flat front-facing screens, no perspective or decorative objects, subtle device outline only. Header back button and bookmark. Country details and readers have contextual bottom actions, NOT the global four-tab navigation. Every panel must have enough whitespace and readable large text. Follow requested Chinese copy exactly. Outside the screens put a tiny understated footer “中国模块 · 界面概念设计”. Wide landscape board showing ONE large tablet landscape screen on left and ONE slender mobile screen on right. Similar composition to reference atlas screen, but updated China exploration. TABLET: top white toolbar back, headline “中国探索地图”, search “找一座城、一条河或一处风景”. Left 68% large finely shaded terrain map centered on East Asia/China, terrain visibly high rugged ochre plateau in west, greener eastern lowlands, blue rivers and coastal ocean; include sensible mainland/islands geography, no decorative fictional polygon border. This is a conceptual map; outside UI footer also says “地图构图示意”. Avoid dense national/province borders. Selected filter chips “地形” orange, “河流”, “地标”. Sparse clear labels “青藏高原”, “长江”, “黄河”, “北京”, “九寨沟”, “太平洋” placed approximately correctly. Orange selected marker in Sichuan for 九寨沟. Small terrain color legend “海拔由低到高” green / tan / brown plus “河流” blue line; compass and +/- controls lower right. Right 32% white fixed panel with very large realistic turquoise Jiuzhaigou lake and pine forest image, title “九寨沟”, location “四川 · 自然风景”, text “湖泊、森林和瀑布，彼此有什么联系？”, primary navy “走进九寨沟” and secondary “看看附近的发现”. No routes navigation or road map.
MOBILE: matching same selected state, top “中国探索地图”, map fills upper 55%, bottom white draggable sheet heading “九寨沟”, turquoise lake photograph, short question “湖水之外，还要保护什么？”, navy “走进九寨沟”. Global navigation only here: “发现”“地图”“百科”“我的” with 地图 selected. Large labels and touch targets, avoid tiny lorem ipsum.
```

## 3. 地理阅读与长城观察

- 成品：[03-china-geography-landmark.png](images/03-china-geography-landmark.png)
- 原图：`/Users/penn/.codex/generated_images/01a17387-e5ec-78d1-9384-997996b6e83a/exec-583f9d48-6d79-4515-bd2a-e43c62e405f4.png`
- 输入：已认可百科设计稿，style reference，不是待替换 App 截图。

```text
Use case: ui-mockup. Create a polished high-fidelity UI design board for the CHINA module of the existing Chinese children's geography encyclopedia app 世界大百科, for an 8-year-old reader. Reference image is STYLE ONLY: preserve its modern geographic editorial layout, white surfaces, navy #12395B and ink #12243A typography, pale canvas #F4F7FB, clear orange #FF9A3D actions, large realistic scenic photography, understated 16px card corners, calm generous spacing and readable Noto Sans SC Chinese. Do not reproduce Egypt or its country list. Do not use offline/content-completeness badges, rewards, coins, avatars, cartoon mascots, watermark, or dense tiny text. Photos are visual concept placeholders. All screen text is Chinese except CHINA. Flat front-facing screens, no perspective or decorative objects, subtle device outline only. Header back button and bookmark. Country details and readers have contextual bottom actions, NOT the global four-tab navigation. Every panel must have enough whitespace and readable large text. Follow requested Chinese copy exactly. Outside the screens put a tiny understated footer “中国模块 · 界面概念设计”. Square board with TWO tall mobile screens side by side.
LEFT is an interactive geography reader. Header “中国 · 地理与气候”. Big title split into two lines “中国的地势
有什么不同？”. Small “读图 · 约 4 分钟”. Large educational landscape cross-section of a rugged snowy plateau on the left, mountains/basin in middle, green plains and blue sea at right. Labels “高原”“山地与盆地”“平原与海岸”; arrow “西 → 东”, small “地势示意” caption. No exact elevation values. Short paragraph “从整体看，中国的地势大体西高东低。‘三级阶梯’是概括，并不是整齐的台阶。” Heading “动手找一找”, a spacious orange-soft question “哪一边的地势更高？” with two large outlined choice buttons “西部”“东部”, neither preselected. Bottom reading toolbar “目录”“听讲解”“收藏”“笔记”.
RIGHT is landmark observation page “金山岭长城”, top half realistic cinematic green mountain ridges with authentic brick Great Wall winding along ridge, no fantasy towers. Image has two unobtrusive numbered hotspots 1 and 2 on wall and watchtower. Title on white sheet “长城为什么顺着山走？”, pill “河北 · 人文地标”. Three concise horizontal illustrated identifiers “墙体”“敌楼”“山脊” using photo crops. Text “先看照片，再说说你发现的线索。” Navy border observation question box “如果沿着山脊修建，会有什么好处？”. Bottom two actions “在地图上找它” and orange “记下我的发现”. Match actual reference editorial visual polish.
```

## 4. 历史线索与文化手艺

- 成品：[04-china-history-culture.png](images/04-china-history-culture.png)
- 原图：`/Users/penn/.codex/generated_images/01a17387-e5ec-78d1-9384-997996b6e83a/exec-c044f3a6-15d9-489b-89d1-0cd3b37a85b9.png`
- 输入：已认可百科设计稿，style reference，不是待替换 App 截图。

```text
Use case: ui-mockup. Create a polished high-fidelity UI design board for the CHINA module of the existing Chinese children's geography encyclopedia app 世界大百科, for an 8-year-old reader. Reference image is STYLE ONLY: preserve its modern geographic editorial layout, white surfaces, navy #12395B and ink #12243A typography, pale canvas #F4F7FB, clear orange #FF9A3D actions, large realistic scenic photography, understated 16px card corners, calm generous spacing and readable Noto Sans SC Chinese. Do not reproduce Egypt or its country list. Do not use offline/content-completeness badges, rewards, coins, avatars, cartoon mascots, watermark, or dense tiny text. Photos are visual concept placeholders. All screen text is Chinese except CHINA. Flat front-facing screens, no perspective or decorative objects, subtle device outline only. Header back button and bookmark. Country details and readers have contextual bottom actions, NOT the global four-tab navigation. Every panel must have enough whitespace and readable large text. Follow requested Chinese copy exactly. Outside the screens put a tiny understated footer “中国模块 · 界面概念设计”. Square board with TWO tall mobile screens side by side.
LEFT historical timeline. Header “中国 · 历史故事”. Big heading “从留下的东西
走近过去”. Wide photo strip of terracotta warriors and old canal bridge, realistic museum documentary style. Segmented control “看线索” active navy and “看时间”. Elegant vertical orange-dot timeline, 4 spaced image-and-text nodes with small photographic square each: “秦汉 · 城墙与道路”, “隋唐 · 水路与往来”, “宋元明清 · 手艺与城市”, “今天 · 研究与保护”. Tiny subtitle above timeline “四组线索，继续打开更多故事”. Small information link “年代怎么看？”. Bottom navy button “从长城的故事开始”. Present as selected thematic examples, not a complete or continuous history textbook.
RIGHT cultural reading. Header “中国 · 艺术与节日”. Big title “一张纸
怎样变成艺术？”. Hero realistic close-up of red intricate symmetrical Chinese paper-cut on pale tabletop and skilled adult hands, no inappropriate fingers/scissors pointing at child. Small photo caption “剪纸里的形状与故事”. Short paragraph “折起来、剪出形状，再展开。不同地方的人，把熟悉的生活放进纸里。” A three-step diagram “对折”“剪形”“展开” showing paper visually, not elaborate prose. Orange-soft observation box “找一找：哪些图案是对称的？”. Bottom toolbar “目录”“听讲解”“收藏”“笔记”. Red is only artwork; UI stays white/navy/orange.
```

## 5. 地方生活与自然生态

- 成品：[05-china-life-nature.png](images/05-china-life-nature.png)
- 原图：`/Users/penn/.codex/generated_images/01a17387-e5ec-78d1-9384-997996b6e83a/exec-f7184d17-d8e4-436e-b2c1-ceac432fe132.png`
- 输入：已认可百科设计稿，style reference，不是待替换 App 截图。

```text
Use case: ui-mockup. Create a polished high-fidelity UI design board for the CHINA module of the existing Chinese children's geography encyclopedia app 世界大百科, for an 8-year-old reader. Reference image is STYLE ONLY: preserve its modern geographic editorial layout, white surfaces, navy #12395B and ink #12243A typography, pale canvas #F4F7FB, clear orange #FF9A3D actions, large realistic scenic photography, understated 16px card corners, calm generous spacing and readable Noto Sans SC Chinese. Do not reproduce Egypt or its country list. Do not use offline/content-completeness badges, rewards, coins, avatars, cartoon mascots, watermark, or dense tiny text. Photos are visual concept placeholders. All screen text is Chinese except CHINA. Flat front-facing screens, no perspective or decorative objects, subtle device outline only. Header back button and bookmark. Country details and readers have contextual bottom actions, NOT the global four-tab navigation. Every panel must have enough whitespace and readable large text. Follow requested Chinese copy exactly. Outside the screens put a tiny understated footer “中国模块 · 界面概念设计”. Square board with TWO tall mobile screens side by side.
LEFT is a curated life/food exploration hub. Header “中国 · 日常生活”. Large title “一日生活里，
藏着哪些地理？” Hero photograph of Jiangnan canal town with white walls, dark roofs and people at a morning riverside market, caption “从一座水边的城镇开始”. Three horizontal editorial article rows with appealing realistic photo thumbnails (canal boat, rice/wheat ingredients, tea hands): “水路怎样连接远方？” / “米和面，从哪里来？” / “一片茶叶怎样走上餐桌？”. Quiet orange-soft callout “一个地方的例子，不代表所有人的生活。” Two compact category buttons “人们与语言” and “饮食与物产”. Bottom navy button “记录我家的一个习惯”.
RIGHT ecological reader. Header “中国 · 动物与生态”. Hero upper 40% real-looking giant panda naturally eating bamboo in mountain bamboo forest, NOT cartoon. White sheet title “大熊猫需要
怎样的家？”. Small “从一种动物，看见一片森林”. Three pictured need chips “竹林”“水源”“栖息空间”. Short paragraph “保护大熊猫，也要关注它生活的森林和周围环境。” Simple nature connection diagram of bamboo, panda, forest with subtle navy arrows labeled “食物”“家园”. Orange-soft observation prompt “如果森林被隔开，可能会发生什么？”. Bottom reading toolbar “目录”“听讲解”“收藏”“笔记”. Warm, scientifically grounded, no zoo-show imagery.
```

## 6. 探索任务与发现笔记

- 成品：[06-china-exploration.png](images/06-china-exploration.png)
- 原图：`/Users/penn/.codex/generated_images/01a17387-e5ec-78d1-9384-997996b6e83a/exec-2f774c6a-e49f-4f9b-bb3d-83e1d0527235.png`
- 输入：已认可百科设计稿，style reference，不是待替换 App 截图。

```text
Use case: ui-mockup. Create a polished high-fidelity UI design board for the CHINA module of the existing Chinese children's geography encyclopedia app 世界大百科, for an 8-year-old reader. Reference image is STYLE ONLY: preserve its modern geographic editorial layout, white surfaces, navy #12395B and ink #12243A typography, pale canvas #F4F7FB, clear orange #FF9A3D actions, large realistic scenic photography, understated 16px card corners, calm generous spacing and readable Noto Sans SC Chinese. Do not reproduce Egypt or its country list. Do not use offline/content-completeness badges, rewards, coins, avatars, cartoon mascots, watermark, or dense tiny text. Photos are visual concept placeholders. All screen text is Chinese except CHINA. Flat front-facing screens, no perspective or decorative objects, subtle device outline only. Header back button and bookmark. Country details and readers have contextual bottom actions, NOT the global four-tab navigation. Every panel must have enough whitespace and readable large text. Follow requested Chinese copy exactly. Outside the screens put a tiny understated footer “中国模块 · 界面概念设计”. Square board with TWO tall mobile screens side by side.
LEFT exploration task page. Header “中国 · 有趣问题”. Big title “像小小地理学家
一样找线索”. Subline “看地图 · 看照片 · 说发现”. Rich panoramic thumbnail triptych of mountain river, Great Wall and panda forest. Clearly readable activity rows with 1,2,3 circular navy step numbers: “找一找：长江在哪里？” / “看一看：长城怎样顺着山走？” / “想一想：大熊猫需要什么？”. No lock icons, no countdown, no scores. Below expanded currently active task with wide real Great Wall photo, prompt “照片里，你能找到哪些线索？”, two large choice chips “墙体跟着山脊起伏” and “所有墙体都一样高”. Neutral feedback area “可以回到照片，再观察一次。” Bottom orange button “记下一个发现”; secondary text action “先去看看别的内容”.
RIGHT discovery journal recap white page. Header “我的中国发现”. Big title “把好奇心
留在这一页”. Small illustrated travel-note accent only (orange pencil and navy outline notebook), no mascot. Large white note card with Great Wall photo thumbnail and text “我看见：长城沿着山脊起伏。”, divider, “我还想知道：人们怎样把材料运上山？”. Clearly labeled “示例笔记” small subdued chip because mock content. Below two sections “还想继续探索” with photo links “一条运河的故事”“竹林里的邻居”. Bottom navy primary “继续探索中国”, small outlined secondary “编辑笔记”. No public share button, rankings, experience points, arbitrary completion percentage or completed-country stamp.
```

