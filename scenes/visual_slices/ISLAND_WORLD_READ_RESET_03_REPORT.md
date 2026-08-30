# ISLAND WORLD READ RESET 03

## Scope

隔离视觉/世界读取迭代。Pass 02 保持不变；不接入 Sea Trial、Journey Test、
Port-to-Port V03 或 project.godot。

## Steering regression

Pass 02 复用的 RegionalOceanSystem 默认把键盘输入直接累加到 boat_yaw。
在默认后侧跟随构图下，这个 yaw 符号与此前批准的 A/D 视觉读法相反。
Reset 03 通过 --island-world-read-reset-03 只在本切片启用反向输入符号：
A=left，D=right；默认 Canonical Reference 行为不变。船的实际位移仍由同一
_boat_forward() 从 boat_yaw 计算，因此没有另造一套航向或速度系统。

## Scale relationships

约定为 1 Godot unit approximately 1 m。Reset 03 使用约 6 m 船体、1.8 m 人体参照、
2 m 码头宽度、3 m 船只净宽参照、约 1.2 m 一般岸线高度；外露侧使用最高
约 6 m 的岩岸段，后方高脊约 10–11 m。标尺仅在 --show-scale-references
时显示，不改变正式船资产。

## Terrain / coastline / harbor

- 以西侧高、迎风、暴露的非对称头地为主要远景轮廓；
- 以东侧较低、向内包裹的受庇护肩部形成受庇护一侧；
- 后方用偏置高脊收住空间，不使用单一锥体；
- 海岸由断开的岩棚、半浸岩石和不同高度的岸段组成，没有连续统一灰边；
- 港湾由两侧陆块之间的开口和后方低内岸先形成，码头只是后置落脚标记；
- 不使用显眼的圆顶 KayKit 树，植被只保留少量低矮色块。

## Assets

本迭代不强行使用下载包。明亮圆形 KayKit 树在正常游戏镜头中会破坏北方
海岸的尺度和视觉统一，因此拒绝为主植被；所有新增地形仍标为 placeholder。

## Remaining weaknesses

当前仍是低成本 blockout：岩棚与低植被还不是正式自然资产，港湾没有真实码头、
房屋或灯塔，近岸碰撞也没有在本视觉切片中实现。最终是否有我要靠岸的
感受仍需实机判断。实际截图中仍能看到明显的 blockout 多面体语言，部分近岸
三角面较硬；这不是正式美术完成结论。

## Runtime QA

- gda script validate：Reset 03 脚本与 RegionalOceanSystem 均为 valid=true。
- gda scene preflight：Reset 03 与 Pass 02 均为 status=ready，无诊断。
- 实际 Godot 窗口渲染：五张游戏摄像机截图已生成，均为 1152×648。
- 真实窗口输入探针：A/D 的 Input.is_key_pressed 路径捕获到了
  steer_input=-1 与 steer_input=+1；Reset 03 的 yaw_sign=-1 配置为
  A=left、D=right。
- gda live daemon 在当前 Windows 环境返回 live_unsupported_platform，因此
  鼠标/键盘后的主观左右观感仍保留给人工实机验收。

## Screenshot QA

已通过的可观察项：远景有非对称目标轮廓；中景能读出左右头地与中央开口；
港湾入口保留连续开水域；近岸有不同高度的岩棚和半浸石；自然-only 截图不依赖
圆顶 KayKit 树、房屋或灯塔。

仍然偏弱的可观察项：所有地形仍是 placeholder；近岸多面体转折偏硬；
尚无正式资产材质、港口建筑或碰撞验证。Reset 03 不宣称这些项目已完成。

## Files

Created:
- scenes/visual_slices/IslandWorldReadReset03.tscn
- scenes/visual_slices/island_world_read_reset_03.gd
- scenes/visual_slices/ISLAND_WORLD_READ_RESET_03_REPORT.md
- 启动IslandWorldReadReset03.bat
- scenes/visual_slices/island_world_read_reset_03_captures/ (runtime output)

Modified:
- scenes/water/regional_ocean/regional_ocean_system.gd — only adds a
  Reset-03 command-line steering correction; default behavior remains unchanged.

Formal files intentionally not modified:
- Sea Trial
- Journey Test
- Port-to-Port V03
- project.godot
