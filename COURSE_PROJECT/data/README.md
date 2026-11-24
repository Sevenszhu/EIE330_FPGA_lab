# 验证数据目录

这里保存迷宫游戏的测试结果、过程记录、仿真波形和参考向量。整理时保留全部 20 个原有文件；数据值不变，仅更新汇总表中的证据路径。

## 从哪里开始看

先看 [verification_summary.csv](verification_summary.csv)：它汇总 T01–T13 共 13 项验证，`Evidence` 列给出相对于 `COURSE_PROJECT/` 的证据路径。需要结果表时看 `results/`，需要画图或检查事件顺序时看 `traces/`。

| 位置 | 文件数 | 用途 |
| --- | ---: | --- |
| `verification_summary.csv` | 1 | 验证总览 |
| `results/` | 8 | 可直接查看、用于报告的检查结果 |
| `traces/` | 6 | 逐步记录、时序采样和画图数据 |
| `waveforms/` | 4 | 仿真器生成的 VCD 信号波形 |
| `reference/` | 1 | 测试和路径检查使用的 HEX 参考向量 |

## 结果表

| 文件 | 内容 | 生成来源 |
| --- | --- | --- |
| [graphics_cases.csv](results/graphics_cases.csv) | 6 个 RGB565 图形用例：文字、玩家、路径、墙和区域外颜色 | `graphics_page_tb.v` |
| [integrated_game_results.csv](results/integrated_game_results.csv) | 7 项整机测试：复位、按键优先级、消抖、移动、翻页、胜利和位置复位 | `integrated_game_tb.v` |
| [maze_route_results.csv](results/maze_route_results.csv) | 路径长度、最短长度与最终位置 | `check_maze_route.py` |
| [movement_rom_sim.csv](results/movement_rom_sim.csv) | 64 个格子的 ROM 仿真输出与参考值对比 | `movement_rom_tb.v` |
| [movement_static_check.csv](results/movement_static_check.csv) | 64 个格子的 ROM 常量与地图推导值静态对比 | `check_movement_rom.py` |
| [player_movement_cases.csv](results/player_movement_cases.csv) | 6 个合法移动、撞墙和边界保护用例 | `player_movement_tb.v` |
| [vga_timing_results.csv](results/vga_timing_results.csv) | 10 项时钟、计数器、同步脉冲、行帧周期与区块尺寸检查 | `vga_timing_tb.v` |
| [victory_detection_results.csv](results/victory_detection_results.csv) | 5 项胜利置位、翻页、位置复位、保持周期和结束页保持检查 | `victory_detection_tb.v` |

`movement_static_check.csv` 与 `movement_rom_sim.csv` 内容接近，但分别检查源码常量和实际仿真输出，两份都保留。

## 过程记录和画图数据

| 文件 | 内容 | 生成来源 |
| --- | --- | --- |
| [integrated_game_trace.csv](traces/integrated_game_trace.csv) | 89 条整机事件，含时间、位置、页面、胜利、按键和冷却状态 | `integrated_game_tb.v` |
| [maze_route_trace.csv](traces/maze_route_trace.csv) | 26 步路径的方向、起止坐标与检查结果 | `check_maze_route.py` |
| [page_state_cases.csv](traces/page_state_cases.csv) | 58 条页面状态记录，含实际页面与预期页面 | `graphics_page_tb.v` |
| [vga_timing_events.csv](traces/vga_timing_events.csv) | 14 条 VGA 计数、同步和区块边界关键事件 | `vga_timing_tb.v` |
| [vga_waveform_samples.csv](traces/vga_waveform_samples.csv) | 162 条时钟与 VGA 信号采样 | `vga_waveform_tb.v` |
| [victory_detection_waveform.csv](traces/victory_detection_waveform.csv) | 116 条胜利测试采样，含位置、胜利计数、页面与颜色 | `victory_detection_tb.v` |

## 其余文件

`waveforms/` 中的 `graphics_page.vcd`、`movement_rom.vcd`、`player_movement.vcd` 和 `victory_detection.vcd` 是 Icarus Verilog 仿真产生的信号变化记录，可用 GTKWave 等波形查看器打开。它们适合调试内部信号，CSV 更适合阅读和画图。VCD 可以通过对应测试重新生成，本次未删除。

[reference/expected_movement.hex](reference/expected_movement.hex) 是 64 行十六进制移动权限向量，由 `check_movement_rom.py` 从地图生成，供 ROM 仿真和最短路径检查读取。每行对应一个格子，按 `8*y+x` 排列；四位从高到低表示上、下、左、右。它是测试输入，保留在参考数据目录。

没有发现可直接认定为无用的临时文件、日志或重复备份。

## 重新生成

在 `COURSE_PROJECT/` 下运行：

```bash
bash tests/run_verification.sh
```

需要 Python 3、Icarus Verilog 的 `iverilog` 和 `vvp`。脚本会创建分类目录并覆盖对应生成数据。直接单独运行 Verilog 测试前，也应先创建这四个子目录。

测试脚本和汇总表已使用新路径。外部画图脚本若仍按平铺目录读取文件，需要按上面的文件表改为 `results/` 或 `traces/` 下的路径。
