# Nexys A7-200T 约束文件示例
# 龙芯杯指定板子：Nexys A7-200T (XC7A200T)

# ========== 时钟约束 ==========
# Nexys A7-200T 板载时钟：100MHz (引脚 E3)
set_property PACKAGE_PIN E3 [get_ports clk]
create_clock -period 10.000 -name clk [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

# ========== 复位约束 ==========
# CPU_RESET 按钮（引脚 C12）
set_property PACKAGE_PIN C12 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]
set_property ASYNC_REG TRUE [get_ports rst]

# ========== PC 输出到 LED ==========
# Nexys A7-200T 有 16 个 LED，可以显示 PC 的低 16 位
# LED[15:0] 对应 pc_out[15:0]

# LED0-LED15 引脚（根据 Nexys A7-200T 原理图）
set_property PACKAGE_PIN U16 [get_ports {pc_out[0]}]   # LED0
set_property PACKAGE_PIN E19 [get_ports {pc_out[1]}]   # LED1
set_property PACKAGE_PIN U19 [get_ports {pc_out[2]}]   # LED2
set_property PACKAGE_PIN V19 [get_ports {pc_out[3]}]   # LED3
set_property PACKAGE_PIN W18 [get_ports {pc_out[4]}]   # LED4
set_property PACKAGE_PIN U18 [get_ports {pc_out[5]}]   # LED5
set_property PACKAGE_PIN U17 [get_ports {pc_out[6]}]   # LED6
set_property PACKAGE_PIN V16 [get_ports {pc_out[7]}]   # LED7
set_property PACKAGE_PIN W17 [get_ports {pc_out[8]}]   # LED8
set_property PACKAGE_PIN W16 [get_ports {pc_out[9]}]   # LED9
set_property PACKAGE_PIN V15 [get_ports {pc_out[10]}]  # LED10
set_property PACKAGE_PIN V14 [get_ports {pc_out[11]}]  # LED11
set_property PACKAGE_PIN V13 [get_ports {pc_out[12]}]  # LED12
set_property PACKAGE_PIN V3  [get_ports {pc_out[13]}]  # LED13
set_property PACKAGE_PIN W3  [get_ports {pc_out[14]}]  # LED14
set_property PACKAGE_PIN U3  [get_ports {pc_out[15]}]  # LED15

# PC 的高 16 位可以连接到其他设备（如 7 段数码管）
# 或者只使用低 16 位

set_property IOSTANDARD LVCMOS33 [get_ports {pc_out[*]}]

# ========== 时序约束 ==========
set_input_delay -clock clk 2.0 [get_ports rst]
set_output_delay -clock clk 2.0 [get_ports {pc_out[*]}]

# ========== 时钟域 ==========
set_clock_groups -asynchronous -group [get_clocks clk]

# ========== 说明 ==========
# 1. clk 端口 → FPGA 引脚 E3 → 板子时钟输入
# 2. rst 端口 → FPGA 引脚 C12 → CPU_RESET 按钮
# 3. pc_out[15:0] → FPGA 引脚 U16, E19, ... → LED[15:0]
#
# 映射关系：
#   Verilog 端口 → FPGA 引脚 → 板子物理接口
#   top.clk     → E3        → 时钟输入
#   top.rst     → C12       → 复位按钮
#   top.pc_out  → U16等     → LED 灯

