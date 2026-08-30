# 当前 PLACEHOLDER 清单

以下内容明确属于临时原型，不是最终美术：

- `SimpleDistantLandSilhouette`：`visual_prototype_3d.gd::_build_far_silhouette()` 创建的远景容器。
- `FarBlueGrayMountainSilhouette`：程序生成的远景山体剪影。
- `TinyDestinationSilhouette`：程序生成的测试岛屿剪影。
- `JourneyTestSimpleHighPoint`：Journey Test 使用的简单高点几何体。
- `IslandPrototype.tscn` 与 `HarborPrototype.tscn`：当前是可替换结构容器，不代表已经有正式岛屿或港口资产。

这些 placeholder 只负责验证空间关系、碰撞边界和航行情绪。未来导入正式岛屿、港口、灯塔、建筑、植被、岩石或道具时，优先替换 VisualRoot 内容，不继续精修这些程序几何。
