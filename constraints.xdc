# Vivado 约束文件
# 龙芯杯团队赛指定配置：Nexys A7-200T (XC7A200T)
# 用于 FPGA 综合和实现

# ========== 时钟约束 ==========
# Nexys A7-200T 板载时钟：100MHz（周期 10ns）
# 如果使用其他时钟源，请相应修改
create_clock -period 10.000 -name clk [get_ports clk]

# ========== 输入/输出标准 ==========
# 假设使用 3.3V LVCMOS 标准
# 根据实际 FPGA 开发板修改
set_property IOSTANDARD LVCMOS33 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports {pc_out[*]}]

# ========== 引脚分配 ==========
# 根据实际 FPGA 开发板修改引脚号
# 示例（需要根据实际硬件修改）：
# set_property PACKAGE_PIN Y18 [get_ports clk]
# set_property PACKAGE_PIN AB22 [get_ports rst]
# set_property PACKAGE_PIN AA22 [get_ports {pc_out[0]}]
# ... 其他引脚

# ========== 时序约束 ==========
# 设置输入延迟
set_input_delay -clock clk 2.0 [get_ports rst]

# 设置输出延迟
set_output_delay -clock clk 2.0 [get_ports {pc_out[*]}]

# ========== 复位约束 ==========
# 复位信号异步复位，高电平有效
set_property ASYNC_REG TRUE [get_ports rst]

# ========== 时钟域 ==========
# 所有信号都在同一个时钟域
set_clock_groups -asynchronous -group [get_clocks clk]

# ========== 资源约束 ==========
# 如果需要限制资源使用，可以添加：
# set_property MAX_FANOUT 100 [get_nets clk]

