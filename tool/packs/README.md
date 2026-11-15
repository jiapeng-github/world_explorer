# 内容包制作与本地服务

当前客户端协议为 `schemaVersion: 1`。工具只写本地目录，不会向外部网站发布内容。依赖 Python 3.9 或更新版本的标准库，无须安装 Python 包。

## 制作并校验

从工程根目录执行：

```bash
python3 tool/content/build_catalog.py
python3 tool/packs/atlas_packs.py build --version 2026.11.6-dev
python3 tool/packs/atlas_packs.py validate build/content/2026.11.6-dev
python3 -m unittest discover -s tool/packs -v
```

默认导出所有已有文章的国家。`--country japan --country norway` 可以只导出指定国家。输出为 `build/content/<version>/<country>/manifest.json`、`articles.json`、`credits.json` 和实际引用的媒体文件。版本目录已存在时会拒绝覆盖；修改内容后使用新版本号。

工具验证文件字节数、SHA-256、150 MiB / 500 文件上限、路径安全、唯一 ID、国家归属、文章及图片引用、题目答案、作者及许可。资料的事实正确性、照片与文意是否一致、中文适龄程度仍需编辑审核；这些检查不能由摘要校验代替。

文章、地点与练习保留稳定 ID。旧版已保存的 9 个地标 ID 通过明确白名单保留。共享图片在发布包中加入国家前缀，并同步改写媒体引用；图片作者、许可和来源不会改变。每个包含其全部文章、地点和练习，客户端安装时替换该国的内容集合，不能用只含新增文章的“差量包”更新。

## 本地联调

先启动只包含公开百科内容的开发服务器：

```bash
python3 tool/packs/atlas_packs.py serve build/content --port 5292
```

另开终端启动应用，并把地址指向具体版本目录，末尾必须保留 `/`：

```bash
flutter run -d chrome --dart-define=CONTENT_BASE_URL=http://127.0.0.1:5292/2026.11.6-dev/
```

该服务器加入 CORS 响应头，让不同本地端口的 Web 预览可以读取内容。默认仅监听 `127.0.0.1`。Android 模拟器通常通过 `10.0.2.2` 访问宿主机；真机需要可访问的 HTTPS 地址。不要把开发服务当作生产服务，也不要把个人备份文件放到内容发布目录。

应用内“家长中心 → 离线内容”可查看安装状态。当前随应用提供的国家会显示“内置”；它们没有卸载按钮。下载服务地址未配置时会明确说明，已有内容仍可阅读。

## 协议与发布边界

客户端当前直接读取 `<CONTENT_BASE_URL>/<packId>/manifest.json`；工具在每个版本目录写 `index.json` 供人工检查，但客户端尚未消费远端索引，也不会自动发现版本更新。开发文档设计的 `/content/v1/packs/{packId}/{version}` 路径、更新检查与 ETag 需要后续统一接入。

```json
{
  "schemaVersion": 1,
  "packId": "japan",
  "contentVersion": "2026.11.6-dev",
  "files": [
    {"path": "articles.json", "bytes": 1234, "sha256": "真实文件的 64 位 SHA-256"}
  ]
}
```

以上只是字段示意，不能直接发布。安装器先下载并校验全部资源，再在数据库事务中替换内容；失败时保留已安装版本。当前取消后重新下载，未实现 HTTP Range 续传。生产发布需要 HTTPS、正确的媒体类型与 CORS、不可变的版本资源、内容审核和版本发现机制；首次全量发布前还需完成真机断网、取消、失败重试及存储容量验证。
