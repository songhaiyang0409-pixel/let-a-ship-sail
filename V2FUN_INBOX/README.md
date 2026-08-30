# V2FUN Asset Inbox

将 V2FUN 手动下载的原始 3D 文件放入 incoming/，然后双击项目根目录的
处理V2FUN资产.bat。

支持：GLB、glTF、FBX、OBJ。

流水线会：

1. 保留原始文件到 originals/；
2. 创建独立的工作副本到 working/；
3. 写入技术检查报告到 reports/；
4. 更新 ledger.json；
5. 不覆盖已经处理过的相同 SHA-256 文件。

working/ 中的文件只代表安全的 pass-through derivative。当前版本不会自动
减面、重拓扑、改材质或破坏性缩放。

处理后可双击项目根目录的启动V2FUN资产预览.bat 查看隔离的中性 Asset Inbox
Gallery。新资产进入正式岛屿或 Sea Trial 前，仍需人工美术批准。
