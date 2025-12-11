# 龙芯杯团队赛官方板子约束文件
# FPGA: Artix-7A200T-FBG676 (xc7a200tfbg676-1)
# 
# 板子外设：
# - DDR3: 1GB (K4B1G1646G-BCK0)
# - SRAM: IDT71V124SATY
# - NAND: K9F1G08U0C-PCB0
# - SPI Flash: 2个
# - VGA, LCD, USB, LAN, PS2, UART
# - GPIO: 16个LED单色灯、2个LED双色灯、8×8 LED点阵、8个共阴级八段数码管

# ========== 时钟约束 ==========
# 注意：需要根据龙芯杯官方板子的实际时钟配置修改
# 假设使用 100MHz 时钟（需要确认实际频率）
# set_property PACKAGE_PIN XXX [get_ports clk]
# create_clock -period 10.000 -name clk [get_ports clk]
# set_property IOSTANDARD LVCMOS33 [get_ports clk]

# ========== 复位约束 ==========
# 注意：需要根据龙芯杯官方板子的实际复位引脚修改
# set_property PACKAGE_PIN XXX [get_ports rst]
# set_property IOSTANDARD LVCMOS33 [get_ports rst]
# set_property ASYNC_REG TRUE [get_ports rst]

# ========== PC 输出到 LED ==========
# 16个LED单色灯（需要根据实际引脚分配修改）
# set_property PACKAGE_PIN XXX [get_ports {pc_out[0]}]   # LED0
# set_property PACKAGE_PIN XXX [get_ports {pc_out[1]}]   # LED1
# ... 其他 LED 引脚
# set_property IOSTANDARD LVCMOS33 [get_ports {pc_out[*]}]

# ========== 7段数码管 ==========
# 8个共阴级八段数码管（需要根据实际引脚分配修改）
# 段选信号（7段 + 小数点 = 8位）
# set_property PACKAGE_PIN XXX [get_ports {seg[0]}]
# ... 其他段选引脚
# 位选信号（8个）
# set_property PACKAGE_PIN XXX [get_ports {an[0]}]
# ... 其他位选引脚

# ========== UART 接口 ==========
# RS-232 UART（需要根据实际引脚分配修改）
# set_property PACKAGE_PIN XXX [get_ports uart_tx]
# set_property PACKAGE_PIN XXX [get_ports uart_rx]
# set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]
# set_property IOSTANDARD LVCMOS33 [get_ports uart_rx]

# ========== DDR3 接口 ==========
# DDR3 SDRAM 1GB (K4B1G1646G-BCK0)
# 注意：DDR3 需要复杂的时序约束，通常使用 IP 核
# 这里只列出基本引脚（需要根据实际连接修改）
# set_property PACKAGE_PIN XXX [get_ports {ddr3_addr[*]}]
# set_property PACKAGE_PIN XXX [get_ports {ddr3_dq[*]}]
# ... 其他 DDR3 信号

# ========== 时序约束 ==========
# set_input_delay -clock clk 2.0 [get_ports rst]
# set_output_delay -clock clk 2.0 [get_ports {pc_out[*]}]

# ========== 时钟域 ==========
# set_clock_groups -asynchronous -group [get_clocks clk]

# ========== 重要提示 ==========
# 本文件是模板，需要根据龙芯杯官方板子的实际引脚分配进行修改
# 请参考：
# 1. 龙芯杯官方提供的板子原理图
# 2. 龙芯杯官方提供的引脚分配文档
# 3. 龙芯杯官方提供的约束文件示例

