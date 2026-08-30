# Port-to-Port Slice 03

隔离的双向微型航海世界。V02 位于 `../overnight_v02/`，作为回退副本保留。

## 手动测试

启动 `启动PortToPort_V03.bat`。船初始停在 Port A，按 `Space` 出发；抵达任一港口后再次按 `Space` 才会出发。A/D 或方向键转向，W/S 调整速度，鼠标拖动观察，R 重置镜头，Backspace 回到 Port A。

## 开发测试

```text
--capture-port-to-port-v03
--port-to-port-v03-autoplay --port-to-port-v03-roundtrip --quit-after-roundtrip
--port-to-port-v03-collision-check
```

截图与运行证据保存在本目录的 `port_to_port_slice_03_captures/` 和 `QA_PASSES.md`。
