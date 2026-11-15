# 自然讲解音频

更新：2026-11-15

App 内置的 **391 篇文章、2,075 段**已全部使用“亲切向导”录音。本轮补录 388 篇、2,060 段，逐段完成本地转写对稿、时长和静音检查，并按 −18 LUFS 的目标统一新录音响度。正式音频随 App 离线打包，共约 12 小时 52 分钟。

## 首批交付

- 中国《中国的地势有什么不同？》、埃及《尼罗河流向哪里？》、南极洲《南极是一块大陆，还是一个点？》共 15 段独立听讲稿。保留正文的核心事实、限制和观察问题，缩短句子、增加口语衔接。正文不变。
- 阅读器优先使用整篇完整的审核配音；没有配音时用设备语音读听讲稿，其余文章仍读正文。
- 离线 MP3 播放器、段落自动衔接、上一段/下一段、暂停原位续播。设备语音暂停后继续仍从当前段开头播放。
- 根据文章 ID、revision、blockId 和原文 SHA-256 匹配；文章更新后不会误播旧音频。必须整篇各段齐全才启用，避免半篇换音色。
- 语速偏好映射为录音播放倍率（默认 1 倍，范围 0.75–1.35），设备朗读沿用原语速设置。暂停后改语速，会重新播放当前段。
- 页面区分“自然讲解”与“设备朗读”；加载失败回退设备朗读并明确提示。不把系统语音标成自然配音。

## 制作与接入记录

首批于 2026-11-15 接入 15 段“亲切向导”录音，覆盖中国地势、埃及尼罗河、南极洲三篇。

ElevenLabs 已成功查到普通话音色，候选为 Ladaisy（8RCmdqih4CKjJ7Bd3ZxT），模型 eleven_v4。首次中国地势试听生成返回免费通道繁忙：没有启动、没有扣费；服务要求本轮不再次发起生成。没有用系统录音冒充自然合成，也没有保存 API 密钥。

首批制作期间，清单中的 15 段讲稿先以 `awaitingAudio` 入库。`scriptReviewed` 记录讲稿本身的审核，录音启用状态由 `reviewStatus` 记录。

## 后续制作与接入

1. 按 manifest 中的 script 制作每段录音。统一读取 `tool/audio/voice_profile.json`，使用固定参考音频、CosyVoice3 模型与 instruct；讲稿正文不添加情绪标签。
2. 先实听一个段落，检查普通话、青藏/阿斯旺/卢克索等地名、问句停顿和音量；确认适合儿童后再完成整篇。不要把舞台指令当正文。
3. 文件放到 `assets/audio/<blockId>.mp3`。逐段确认无漏字、无多读标签、无截断和长静音，并记录生成 ID、音色、模型、审核日期。
4. 在录音检查完成并获准启用后，添加 `asset`（完整 assets/audio 路径）并将 `reviewStatus` 改成 `approved`，记录所用检查方式。文章各段齐备后会整篇启用。保留生成时对应的 `sourceHash`。
5. 在 Android 和 iOS 实机验证播放、暂停、返回页面、连续切段、锁屏/来电等系统中断。当前播放器未实现锁屏媒体控制，也不宣称支持后台连续讲解。

无云端运行依赖、无内容更新服务。模型只在内容制作阶段使用，App 不含服务商密钥。

## 代码与验证

- `lib/data/speech/narration_catalog.dart`：录音与讲稿匹配。
- `lib/data/speech/narration_player.dart`：audioplayers 离线播放器适配。
- `lib/data/speech/speech_repository.dart`：播放、回退、取消、续播与段落状态。
- `test/natural_narration_test.dart`：版本/哈希/完整性、讲稿回退、暂停续播、加载中取消、文件失效、段落切换。
- 播放库依据：[audioplayers 官方文档](https://github.com/bluefireteam/audioplayers/blob/main/getting_started.md)。

2026-11-14 验证结果：静态分析无问题；自然讲解与持久化 14 项测试、页面回归 6 项测试通过（390/1024/320 像素，含窄屏大字体的播放中与暂停状态）；Android debug APK 构建成功。音色与录音实机听感尚未验证，因为生成未启动。

## 本地 CosyVoice3 生成环境（2026-11-14）

已在 `/Users/penn/Documents/Codex/VoiceStudio` 安装官方 VoiceStudio WebUI + CosyVoice3，网页为 http://127.0.0.1:3900 。完整说明在该目录的 `local/README.zh-CN.md`，启动入口为 `启动 VoiceStudio.command`。已生成 24 kHz、10.84 秒中文试听，生成阶段约 17.4 秒（不含首次模型加载），当前 M5 使用 CPU 推理。未把试听自动作为正式讲解音频入库，后续需定稿音色、逐段实听并校对后再标为 approved。

## 已确认的固定声线（2026-11-14）

用户已试听并确定：全部百科自然讲解统一使用 **亲切向导** 的声线与风格。

- 制作配置：`tool/audio/voice_profile.json`；声线 ID：`friendly-guide-v1`。
- 参考音频固定副本：`tool/audio/friendly_guide_reference.wav`，配置记录 SHA-256，避免上游更新影响声线。
- 固定指令：请用温暖亲切的普通话讲解，像带着小朋友参观的向导，自然交流，句间留出停顿。
- CosyVoice3，中文，seed=42，raw，无降噪、无背景音乐，与已选 demo 的生成参数一致。不同文案仍可能产生韵律变化。
- 15 段待制作讲稿已改用该 voiceId/modelId；用户确认的是声线与风格，不代表尚未生成的录音已审核。
- 配置与参考音频仅供制作使用，不打包进 App。后续录音不得自行切换声线或演绎方向。

## 首批录音制作完成（2026-11-15）

已使用固定“亲切向导”配置生成全部 15 段现有听讲稿：

| 文章 | 段数 | 整篇试听时长（含段间停顿） |
| --- | --- | --- |
| 中国的地势有什么不同？ | 5 | 2 分 7 秒 |
| 尼罗河流向哪里？ | 5 | 2 分 13 秒 |
| 南极是一块大陆，还是一个点？ | 5 | 2 分 19 秒 |

- 试听页：`tool/audio/generated/index.html`，含三篇整篇试听及逐段讲稿、音频。
- 原始录音：`tool/audio/generated/*.wav`（24 kHz 单声道），同时提供 128 kbps MP3。
- 下载包：`tool/audio/friendly-guide-narrations.zip`，包含 MP3、试听页和生成记录。
- 每段 `.json` 保存完整配置、生成时间、讲稿、sourceHash、音频哈希及技术检查结果。
- 已验证 15 段数量、文章/版本/段落/原文哈希/讲稿对应、非静音、数值有效性、采样率和 WAV 哈希；全部 MP3 转码成功。
- 尚未逐段实听确认发音、漏读和韵律。制作记录状态为 `awaitingReview`；App manifest 暂保留 `awaitingAudio`、不添加正式 asset、不标 approved，播放器继续原有回退逻辑。试听通过后再迁入 assets/audio 并启用。
- 复现：使用 VoiceStudio 的 Python 运行 `tool/audio/generate_narrations.py`（本地服务需已启动），再运行 `tool/audio/package_narrations.py`。

## 正式接入（2026-11-15）

用户明确要求“替换 App 正式讲解”，现已将 15 个分段 MP3 放入 `assets/audio/`，对应 manifest 条目设为 approved，记录批准依据、日期、生成 ID 和时长。上述待审核/未接入描述为此前阶段记录，以本节状态为准。启用依据是用户要求正式替换，并非声称已完成逐字人工听审。

首批启用时，三篇文章使用“自然讲解”。当时已确认全部段落匹配文章版本和原文哈希，且 Flutter 资源包可读取首批 MP3。模拟器媒体音量也由 5/15 调整到 10/15。

## 批量制作内置文章讲解

制作工具从 App 阅读器使用的两份目录中查找缺少录音的段落。沿用“亲切向导”配置，以段落标题和正文为讲稿，并将年份和小数按普通话读法处理。每段导出为 24 kHz 单声道 MP3，使用 −18 LUFS 的响度目标。`assets/audio/narrations.json` 记录段落的原文指纹、音色、生成信息和正式资源路径。文章的录音齐备后整篇启用。

`python3 tool/audio/complete_catalog.py --status` 查看覆盖情况，`--verify` 检查所有内置文章的正式录音。以后补录可使用 VoiceStudio 的 Python 执行 `tool/audio/complete_catalog.py --publish YYYY-MM-DD`。工作文件放在 `tool/audio/.production/`，同一稿件已生成的文件在继续制作时可复用。

全量验证已通过。216 项 Flutter 测试通过，Android 调试包内的 2,075 个 MP3 与项目清单逐一匹配。在 Pixel Tablet 模拟器安装后，用巴西《怎样发现雨林中的联系？》验证了播放、自动切段、暂停和原段续播。
