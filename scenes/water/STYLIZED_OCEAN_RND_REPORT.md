# STYLIZED OCEAN R&D 01

## 目的与边界

本次研究只在隔离场景 `StylizedOceanRND01.tscn` 中进行。它复用了 Robin Hood's Bay blockout 的船、岛、天空和相机尺度，但没有接入正式航行、计时器、碰撞、尾迹或状态机。

正式项目文件保持不变：

- `main.gd`
- `visual_prototype_3d.gd`
- `project.godot`
- `scenes/water/PortToPortSlice01.tscn`

本项目当前实际运行配置是 Godot 4.7.2 Compatibility renderer。因此本轮实际截图使用 Compatibility，而不是修改 `project.godot` 去切换 Forward+。这不会影响变体之间的相对比较，但不能替代 Forward+ 的性能结论。

## 基线诊断

基线来自 `RobinHoodsBayIslandBlockout01.tscn` 的原水面材质 `stylized_water_prototype_03.gdshader`：

- 水面网格约 `190 x 190`，`160 x 160` subdivisions。
- 顶点位移是 4 层长波 Gerstner 叠加，没有纹理、foam、caustics 或 refraction。
- 船的视觉 Wave Follow 使用同一组基础波参数。
- 主要问题不是“没有几何波”，而是颜色压缩较宽、波层相位关系稳定、缺少额外方向性读法，因此容易读成技术性重复波面。

完整诊断见 [WATER_BASELINE_DIAGNOSIS.md](WATER_BASELINE_DIAGNOSIS.md)。

## 共同锁定的几何参数

所有变体使用同一组基础 Gerstner 公式和参数，确保比较的是水面视觉表达，而不是换了一套运动：

- `wave_amplitude_scale = 0.70`
- `wave_length_scale = 3.8`
- `time_factor = 2.7`
- active layers: `wave_1`, `wave_5`, `wave_7`, `wave_8`
- `wave_1 = (0.34, 3.60, 0.18, 0.86)`
- `wave_5 = (1.42, 0.28, 0.12, 2.18)`
- `wave_7 = (-1.05, 2.90, 0.08, 1.30)`
- `wave_8 = (-0.58, -1.22, 0.10, 1.82)`

因此本轮没有改变船的 Wave Follow 公式或基础波形。

## Variant A — layered directional bands

实现：在相同基础几何波上叠加两组不同方向、不同尺度的方向带，并在距离增加时衰减。

主要参数：

- 第一方向带：方向 `(0.98, 0.20)`，scale `0.19`，speed `0.20`。
- 第二方向带：方向 `(0.66, -0.75)`，scale `0.095`，speed `0.12`，phase `2.3`。
- 视觉带强度：`0.28`，随远景衰减。

实际截图中，A 的方向性最明确，也最容易暴露“带状重复”。它适合验证方向流动是否可读，不适合作为最终默认方案而不再压制重复感。

截图目录：[variant_a](stylized_ocean_rnd_01_captures/variant_a/)

## Variant B — faceted geometric read

实现：使用两组低频 triangular/faceted value region，辅以非常小的宽幅几何位移；几乎不依赖条带。

主要参数：

- facet 方向：`(0.92, 0.38)` 与 `(-0.28, 0.96)`。
- facet scale：`0.105` 与 `0.072`。
- 额外几何 facet 位移强度：`0.12`。
- 颜色区域混合范围：`0.84` 到 `1.14` 的宽幅值变化。

实际截图中，B 的表面条带最少，水面最接近“由少量形状组成的图形化海面”；大尺度几何波仍然可见，且船没有被高频细节抢走。

截图目录：[variant_b](stylized_ocean_rnd_01_captures/variant_b/)

## Variant C — restrained directional ribbons

实现：两组更宽、更低对比的方向 ribbon，使用较大的相位差并强化远景衰减。

主要参数：

- broad swell：scale `0.115`，speed `0.16`，phase `1.2`。
- 第二方向带：方向 `(0.36, -0.93)`，scale `0.055`，speed `0.085`，phase `3.1`。
- 视觉带强度：`0.18`，远景衰减更快。

实际截图中，C 比 A 安静，仍保留可见方向流动；在远景中读波较弱，但更不容易形成满屏装饰性条纹。

截图目录：[variant_c](stylized_ocean_rnd_01_captures/variant_c/)

## Hybrid V1 / V2 / V3

三个 Hybrid 不是同一参数的重复截图，而是同一隔离 shader 内的三条不同结构路径：

### Hybrid V1

以 A 的可读方向带为基础，加一层受控的 B 式低频 facet。方向带强度 `0.16`，facet 几何位移 `0.065`。实际效果是方向性和图形分面之间的中间值。

截图目录：[hybrid_v1](stylized_ocean_rnd_01_captures/hybrid_v1/)

### Hybrid V2

使用分离的两个方向带，并加入低频 broad-swell envelope（强度 `0.075`）打散同步行列；方向带强度 `0.12`。实际效果比 V1 更平滑，重复条带更不集中。

截图目录：[hybrid_v2](stylized_ocean_rnd_01_captures/hybrid_v2/)

### Hybrid V3

保留最宽的方向流动，带强度 `0.095`；远景衰减最强，并加入很轻的局部接触暗化 `0.085` 和极宽的 cross-current 几何偏移 `0.035`。实际效果最安静，适合检验“远海不抢主体”，但中远景方向读法也最弱。

截图目录：[hybrid_v3](stylized_ocean_rnd_01_captures/hybrid_v3/)

## 截图与时间序列

每个版本都实际生成了相同的 5 个机位和 3 张固定相机时间序列，共 7 个版本、56 张 PNG。全部主截图尺寸为 `1152 x 648`：

- `01_idle.png`
- `02_open_water_cruising.png`
- `03_turning.png`
- `04_near_water.png`
- `05_horizon.png`
- `temporal/00.png`
- `temporal/01.png`
- `temporal/02.png`

代表性截图：

- [Baseline idle](stylized_ocean_rnd_01_captures/baseline/01_idle.png)
- [Variant A idle](stylized_ocean_rnd_01_captures/variant_a/01_idle.png)
- [Variant B idle](stylized_ocean_rnd_01_captures/variant_b/01_idle.png)
- [Variant C idle](stylized_ocean_rnd_01_captures/variant_c/01_idle.png)
- [Hybrid V1 idle](stylized_ocean_rnd_01_captures/hybrid_v1/01_idle.png)
- [Hybrid V2 idle](stylized_ocean_rnd_01_captures/hybrid_v2/01_idle.png)
- [Hybrid V3 idle](stylized_ocean_rnd_01_captures/hybrid_v3/01_idle.png)
- [Variant A temporal 00](stylized_ocean_rnd_01_captures/variant_a/temporal/00.png)
- [Variant A temporal 02](stylized_ocean_rnd_01_captures/variant_a/temporal/02.png)
- [Hybrid V3 horizon](stylized_ocean_rnd_01_captures/hybrid_v3/05_horizon.png)

固定相机时间序列中，A 的方向带移动最容易观察；B 和 Hybrid V3 的变化更偏宽幅、低频，需要前后帧对照才能看出持续运动。这符合“远景安静、近景保留变化”的目标，但也意味着 B/V3 需要在实际游戏中继续确认是否足够有生命感。

## 对比结论（只陈述本轮观察）

| 维度 | 本轮观察 |
|---|---|
| 噪声最低 | B 与 Hybrid V3；两者都没有高频纹理噪点 |
| 大尺度波浪最清楚 | 基线与 B；基线更硬，B 更图形化 |
| 方向流动最清楚 | A；同时也最容易暴露重复带 |
| 船与水的关系 | B / Hybrid V2 较干净；船和岛仍然是可读主体 |
| 远景安静程度 | Hybrid V3 最明显，其次 C / V2 |
| 重复感风险 | A 最高；V1 中等；B、V2、V3 较低但并非消失 |
| 地平线 | 所有实际截图均保持干净，没有连续爆白地平线 |
| 视觉问题 | 岛和船仍是 blockout 资产；这不是本轮水面变体要解决的问题 |

## 技术排序与建议

按本轮截图和结构目标给出的技术候选排序：

1. **Hybrid V2**：方向性、低频变化和重复抑制之间最均衡，适合作为下一轮隔离水面迭代的起点。
2. **Variant B**：最接近大色块/图形化方向，水面干净；需要实际确认运动是否足够明显。
3. **Hybrid V3**：最不抢主体、远景最安静；需要确认不会安静到像静态材质。
4. **Variant C**：方向性克制，结构简单；远景可读性偏弱。
5. **Hybrid V1**：较容易看见波，但仍有一定带状重复风险。
6. **Variant A**：方向性最强，作为研究对照价值高；重复感风险也最高。

这个排序是本轮截图与代码结构的研发建议，不是正式项目替换决定。是否真的“有水感而不抢主体”，仍需用户在实际场景中观察确认。

## 性能与运行检查

实际运行命令：

```powershell
& "E:\让一艘船航行\tools\Godot\Godot_v4.7.2-stable_win64_console.exe" --path "E:\让一艘船航行" --resolution 1152x648 "res://scenes/water/StylizedOceanRND01.tscn" -- --capture-stylized-ocean-rnd-01
```

实际图形运行结果：

- Godot 4.7.2 成功加载并运行隔离场景。
- 实际 renderer 为 Compatibility / OpenGL 3.3（由当前正式 `project.godot` 配置决定）。
- 7 个版本均生成 5 个主截图和 3 个时间序列截图。
- 最后一次运行读数：`draw_calls=109`，`primitives=261624`。
- 当前运行路径无法可靠取得 GPU ms/frame，因此没有虚构 GPU 时间；`gpu_ms_unavailable_in_runtime=true`。
- 未观察到水面 shader 编译错误。
- headless 模式下的截图失败是无 viewport 的 Dummy renderer 限制，不作为 shader 失败；实际图形运行已成功保存截图。

## 修改文件

本轮新增/修改仅限隔离 R&D：

- `materials/water_test/stylized_ocean_rnd_01.gdshader`
- `scenes/water/stylized_ocean_rnd_01.gd`
- `scenes/water/StylizedOceanRND01.tscn`
- `scenes/water/WATER_BASELINE_DIAGNOSIS.md`
- `scenes/water/STYLIZED_OCEAN_RND_REPORT.md`
- `scenes/water/stylized_ocean_rnd_01_captures/` 下的截图输出

正式文件修改数：**0**。

## 下一步边界

本报告完成后停止。没有把任何变体接入 Sea Trial、Journey Test、Port-to-Port 或正式水面，也没有修改 `project.godot`。下一步应先由人工选择是否继续以 Hybrid V2、B 或 V3 做新的隔离视觉实验。
