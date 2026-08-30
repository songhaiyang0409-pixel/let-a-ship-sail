# 3D 素材导入检查

正式导入 GLB、GLTF 或 FBX 时，逐项检查：

1. **Scale**：是否按 `1 Godot unit = 1 meter` 导入，根节点是否有异常缩放。
2. **Pivot**：底部接触面、船体中心或建筑基准点是否合理。
3. **Material**：是否符合 Graphic Stylized 3D 的大色面、剪影和有限色彩原则。
4. **Texture**：纹理是否必要，是否存在丢失路径、过大尺寸或不必要的高频细节。
5. **Collision**：是否使用低成本简化碰撞代理，而不是默认复杂 Mesh Collider。
6. **Shadow**：阴影是否稳定，是否出现明显漏光、反面或透明排序问题。
7. **Animation**：是否包含不必要的动画、骨骼或循环；没有需求时应保持为空或禁用。
8. **面数**：是否存在明显异常面数，是否能在目标移动端尺寸和帧率下运行。

## 替换边界

岛屿视觉放在 `IslandPrototype.tscn/VisualRoot`；`CollisionRoot` 保持独立。港口内容放在 `HarborPrototype.tscn` 的 `DockRoot`、`BuildingRoot`、`LandmarkRoot` 或 `PropRoot` 中。

替换模型不应要求修改 Sea Trial 的核心航行、边界或抵达代码。
