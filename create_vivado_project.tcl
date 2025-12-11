# Vivado 项目创建脚本
# 使用方法：在 Vivado TCL 控制台运行：source create_vivado_project.tcl

# 设置项目名称和路径
set project_name "riscv-pipeline-cpu"
set project_dir "."

# ========== 配置选项 ==========
# 龙芯杯团队赛指定配置：XC7A200T 器件（Nexys A7-200T 开发板）

# 选项1：使用开发板（推荐，龙芯杯指定板子）
set use_board 1
set board_name "digilentinc.com:nexys-a7-200t:part0:1.0"  # Nexys A7-200T (龙芯杯指定)

# 选项2：仅使用器件型号（如果板子名称不可用，使用此选项）
# set use_board 0
# set part_name "xc7a200tfbg676-1"  # Artix-7 200T (龙芯杯指定器件)

# ========== 创建项目 ==========
if {[info exists use_board] && $use_board == 1} {
    # 使用开发板创建项目
    create_project $project_name $project_dir -board $board_name -force
    puts "使用开发板创建项目: $board_name"
} else {
    # 使用器件型号创建项目（仅仿真）
    create_project $project_name $project_dir -part $part_name -force
    puts "使用器件型号创建项目: $part_name (仅仿真)"
}

# 添加设计源文件
add_files {
    src/pipeline/top.v
    src/pipeline/if_stage.v
    src/pipeline/decode_stage.v
    src/pipeline/ex_stage.v
    src/pipeline/mem_stage.v
    src/pipeline/wb_stage.v
    src/Function/alu.v
    src/Function/control.v
    src/Function/dmem.v
    src/Function/imem.v
    src/Function/pipeline_regs.v
    src/Function/regfile.v
}

# 添加仿真文件
add_files -fileset sim_1 {
    test/testbench_vivado.v
}

# 设置顶层模块
set_property top testbench [get_filesets sim_1]
set_property top top [get_filesets sources_1]

# 更新编译顺序
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# 设置仿真参数
set_property -name {xsim.simulate.runtime} -value {5000ns} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]

# 设置工作目录（用于 $readmemh 文件查找）
set_property -name {xsim.simulate.custom_wd} -value {./} -objects [get_filesets sim_1]

puts "项目创建完成！"
puts "下一步："
puts "1. 确保 hello.hex 文件在正确的位置"
puts "2. 运行仿真：launch_simulation"
