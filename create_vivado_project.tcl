# Vivado 项目创建脚本
# 使用方法：在 Vivado TCL 控制台运行：source create_vivado_project.tcl

# 设置项目名称和路径
set project_name "riscv-pipeline-cpu"
set project_dir "."

# ========== 配置选项 ==========
# 龙芯杯团队赛指定配置：Artix-7A200T-FBG676 (xc7a200tfbg676-1)
# 注意：龙芯杯官方板子是定制板子，不是 Nexys A7-200T

# 选项1：使用器件型号（龙芯杯官方板子）
# 注意：龙芯杯官方板子没有 Vivado 板子定义文件，使用器件型号
set use_board 0
# Artix-7 200T (龙芯杯指定器件)
set part_name "xc7a200tfbg676-1"

# 选项2：如果将来有板子定义文件，可以使用此选项
# set use_board 1
# set board_name "loongson-cup-board:part0:1.0"

# ========== 创建项目 ==========
# 先创建项目（使用器件型号）
# 龙芯杯官方板子：Artix-7A200T-FBG676 = xc7a200tfbg676-1
create_project $project_name $project_dir -part $part_name -force

# 尝试设置开发板信息（如果可用）
if {[info exists use_board] && $use_board == 1} {
    # 检查板子是否可用
    set available_boards [get_board_parts]
    set board_found 0
    foreach board $available_boards {
        if {[string match "*nexys-a7-200t*" $board]} {
            set board_found 1
            break
        }
    }
    
    if {$board_found} {
        # 设置开发板信息
        set_property board_part $board_name [current_project]
        puts "✓ 使用开发板创建项目: $board_name"
    } else {
        puts "⚠ 警告: 板子定义 '$board_name' 未找到"
        puts "   项目已使用器件型号创建: xc7a200tfbg676-1"
        puts "   如果需要使用板子定义，请："
        puts "   1. 在Vivado中运行: get_board_parts"
        puts "   2. 查看可用的板子列表"
        puts "   3. 或者从 Vivado Board Store 安装 Nexys A7-200T 板子定义"
    }
} else {
    puts "使用器件型号创建项目: xc7a200tfbg676-1"
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

# 添加约束文件（龙芯杯官方板子）
if {[file exists "constraints_loongson_cup.xdc"]} {
    add_files -fileset constrs_1 constraints_loongson_cup.xdc
    puts "✓ 已添加约束文件: constraints_loongson_cup.xdc"
    puts "⚠ 注意: 请确保 constraints_loongson_cup.xdc 中的引脚分配已正确配置"
} else {
    puts "⚠ 警告: 未找到约束文件 constraints_loongson_cup.xdc，请手动添加"
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
