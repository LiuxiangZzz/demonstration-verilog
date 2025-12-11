# Vivado Project Creation Script
# Usage: Run in Vivado TCL console: source create_vivado_project.tcl

# Get script directory (for finding source files)
set script_dir [file dirname [file normalize [info script]]]

# Display current working directory (for debugging)
puts "Current working directory: [pwd]"
puts "Script directory: $script_dir"

# ========== Check and close opened project ==========
# Close all projects first (most reliable way)
puts "Closing all open projects..."
set projects_closed 0
for {set i 0} {$i < 10} {incr i} {
    if {[catch {current_project} current_proj] == 0} {
        puts "  Closing project: $current_proj"
        catch {close_project}
        set projects_closed 1
        # Wait a bit between closes
        after 200
    } else {
        break
    }
}
if {$projects_closed} {
    puts "OK: All projects closed"
    # Wait for file locks to release
    puts "Waiting for file locks to release..."
    after 1000
} else {
    puts "No projects were open"
}

# Set project name and path
set project_name "riscv-pipeline-cpu"
set project_base_dir "C:/Users/Lenovo/Desktop/vivado-project"
set project_dir [file join $project_base_dir $project_name]

# Ensure project directory exists
if {![file exists $project_base_dir]} {
    file mkdir $project_base_dir
    puts "OK: Created base directory: $project_base_dir"
}
if {![file exists $project_dir]} {
    file mkdir $project_dir
    puts "OK: Created project directory: $project_dir"
}

# ========== Configuration Options ==========
# 龙芯杯团队赛指定配置：Artix-7A200T-FBG676 (xc7a200tfbg676-1)
# 注意：龙芯杯官方板子是定制板子，不是 Nexys A7-200T

# 选项1：使用器件型号（龙芯杯官方板子）
# 注意：龙芯杯官方板子没有 Vivado 板子定义文件，使用器件型号
set use_board 0
# Artix-7 200T (龙芯杯指定器件)
set part_name "xc7a200tfbg676-1"

# Option 2: If board definition file is available in the future, use this option
# set use_board 1
# set board_name "loongson-cup-board:part0:1.0"

# ========== Create Project ==========
# 龙芯杯官方板子：Artix-7A200T-FBG676 = xc7a200tfbg676-1

# Remove old project directory if it exists (most reliable way to overwrite)
if {[file exists $project_dir]} {
    puts "Old project directory exists: $project_dir"
    puts "Removing old project directory..."
    
    if {[catch {file delete -force $project_dir} del_result]} {
        puts "WARNING: Cannot remove old directory: $del_result"
        puts "This usually means files are still locked."
        puts ""
        puts "Please do the following:"
        puts "  1. Make sure ALL Vivado windows are closed"
        puts "  2. Check Task Manager - end any vivado.exe processes"
        puts "  3. Close Windows File Explorer if showing this folder"
        puts "  4. Wait 5 seconds, then run this command in TCL console:"
        puts "     file delete -force $project_dir"
        puts "  5. Then run this script again"
        puts ""
        error "Cannot remove old project directory. Please follow the steps above."
    } else {
        puts "OK: Old project directory removed"
        # Wait a moment to ensure deletion is complete
        after 500
    }
}

# Create new project
puts "Creating new project..."
if {[catch {create_project $project_name $project_dir -part $part_name -force} result]} {
    puts "ERROR: Failed to create project: $result"
    error "Failed to create project: $result"
} else {
    puts "OK: Project created successfully"
}

# Try to set board information (if available)
if {[info exists use_board] && $use_board == 1} {
    # Check if board is available
    set available_boards [get_board_parts]
    set board_found 0
    foreach board $available_boards {
        if {[string match "*nexys-a7-200t*" $board]} {
            set board_found 1
            break
        }
    }
    
    if {$board_found} {
        # Set board information
        set_property board_part $board_name [current_project]
        puts "OK: Using board to create project: $board_name"
    } else {
        puts "WARNING: Board definition '$board_name' not found"
        puts "   Project created using part: xc7a200tfbg676-1"
        puts "   To use board definition, please:"
        puts "   1. Run in Vivado: get_board_parts"
        puts "   2. Check available board list"
        puts "   3. Or install Nexys A7-200T board definition from Vivado Board Store"
    }
} else {
    puts "Creating project using part: xc7a200tfbg676-1"
}

# Add design source files
# Check if files exist first, then add them (using script directory as base)
set source_files {
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

set missing_files {}
set found_files {}

foreach file $source_files {
    # Use script directory as base path
    set full_path [file join $script_dir $file]
    if {[file exists $full_path]} {
        lappend found_files $full_path
    } else {
        lappend missing_files $file
        puts "WARNING: File does not exist: $full_path"
    }
}

if {[llength $missing_files] > 0} {
    puts "ERROR: The following files were not found:"
    foreach file $missing_files {
        puts "  - $file"
    }
    puts ""
    puts "Please ensure:"
    puts "1. Run this script from the project root directory"
    puts "2. Or modify paths in the script to use absolute paths"
    puts "3. Current working directory: [pwd]"
    error "Files missing, cannot continue creating project"
}

# Add found files
if {[llength $found_files] > 0} {
    if {[catch {add_files $found_files} result]} {
        puts "WARNING: Some files may already exist in project: $result"
        # Try to add files individually to see which ones fail
        foreach file $found_files {
            if {[catch {add_files $file} err]} {
                puts "  Skipping (may already exist): $file"
            }
        }
    } else {
        puts "OK: Added [llength $found_files] source files"
    }
}

# Add simulation files (using script directory as base path)
set testbench_file [file join $script_dir "test/testbench_vivado.v"]
if {[file exists $testbench_file]} {
    add_files -fileset sim_1 $testbench_file
    puts "OK: Added testbench file: $testbench_file"
} else {
    puts "WARNING: Testbench file does not exist: $testbench_file"
}

# 添加约束文件（龙芯杯官方板子，使用脚本目录作为基准路径）
set constraint_file [file join $script_dir "constraints_loongson_cup.xdc"]
if {[file exists $constraint_file]} {
    add_files -fileset constrs_1 $constraint_file
    puts "OK: Added constraint file: $constraint_file"
    puts "NOTE: Please ensure pin assignments in constraints_loongson_cup.xdc are correctly configured"
} else {
    puts "WARNING: Constraint file not found: $constraint_file, please add manually"
}

# Set top-level module
if {[catch {set_property top testbench [get_filesets sim_1]} result]} {
    puts "WARNING: Failed to set simulation top: $result"
}
if {[catch {set_property top top [get_filesets sources_1]} result]} {
    puts "WARNING: Failed to set synthesis top: $result"
}

# Update compile order
if {[catch {update_compile_order -fileset sources_1} result]} {
    puts "WARNING: Failed to update compile order for sources_1: $result"
}
if {[catch {update_compile_order -fileset sim_1} result]} {
    puts "WARNING: Failed to update compile order for sim_1: $result"
}

# Set simulation parameters
# 仿真时间：设置为 -all 让testbench中的$finish控制停止时间
# testbench中设置了#5000，所以仿真会在约5100ns停止
set_property -name {xsim.simulate.runtime} -value {-all} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]

# Set working directory (for $readmemh file lookup, pointing to pipeline directory where hello.hex is located)
# 使用绝对路径确保在不同操作系统上都能找到文件
set pipeline_dir [file join $script_dir "src/pipeline"]
# 转换为Vivado可用的路径格式（如果是Windows路径需要转换）
if {[string match "*:*" $pipeline_dir]} {
    # Windows路径，直接使用
    set_property -name {xsim.simulate.custom_wd} -value $pipeline_dir -objects [get_filesets sim_1]
} else {
    # Linux路径，转换为Windows格式（如果在Windows上运行Vivado）
    set_property -name {xsim.simulate.custom_wd} -value $pipeline_dir -objects [get_filesets sim_1]
}
puts "OK: Simulation working directory set to: $pipeline_dir"
puts "NOTE: Ensure hello.hex exists at: [file join $pipeline_dir hello.hex]"

puts "Project creation completed!"
puts "Next steps:"
puts "1. Ensure hello.hex file is in the correct location"
puts "2. Run simulation: launch_simulation"

