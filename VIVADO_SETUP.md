# Vivado 项目设置指南

## 概述
这个 RISC-V 五级流水线 CPU 项目可以在 Xilinx Vivado 中运行，但需要做一些调整。

## 兼容性说明

### ✅ 支持的 Verilog 特性
- 标准 Verilog-2001 语法
- `$readmemh` / `$readmemb` 文件读取
- `$display` / `$write` 系统任务
- 所有模块和端口定义

### ⚠️ 需要调整的部分
- **波形文件生成**：Vivado 使用自己的波形格式，不支持 `$dumpfile`/`$dumpvars`
- **文件路径**：`$readmemh` 的路径需要相对于 Vivado 项目目录
- **仿真器**：使用 Vivado 的 xsim 而不是 iverilog

## 在 Vivado 中创建项目

### 方法1：使用 GUI 创建项目

1. **打开 Vivado**
   ```
   启动 Vivado -> Create Project
   ```

2. **项目设置**
   - Project Name: `riscv-pipeline-cpu`
   - Project Location: 选择项目目录
   - Project Type: RTL Project
   - 不添加源文件（稍后添加）

3. **添加源文件**
   ```
   Add Sources -> Add or create design sources
   添加以下文件：
   
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
   ```

4. **添加仿真文件**
   ```
   Add Sources -> Add or create simulation sources
   添加：test/testbench_vivado.v
   ```

5. **设置顶层模块**
   ```
   Simulation Sources -> testbench_vivado -> Set as Top
   ```

6. **设置仿真文件路径**
   - 确保 `hello.hex` 文件在正确的位置
   - 可能需要调整 `imem.v` 和 `dmem.v` 中的文件路径

### 方法2：使用 TCL 脚本（推荐）

创建 `create_vivado_project.tcl`：

```tcl
# 创建 Vivado 项目
create_project riscv-pipeline-cpu . -part xc7a100tcsg324-1

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

# 更新编译顺序
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# 设置仿真时间
set_property -name {xsim.simulate.runtime} -value {5000ns} -objects [get_filesets sim_1]
```

在 Vivado TCL 控制台运行：
```tcl
source create_vivado_project.tcl
```

## 文件路径调整

由于 Vivado 的工作目录可能与 iverilog 不同，可能需要调整 `imem.v` 和 `dmem.v` 中的文件路径：

### 选项1：使用绝对路径
```verilog
$readmemh("/完整路径/demonstration-verilog/src/pipeline/hello.hex", mem);
```

### 选项2：复制文件到项目目录
将 `hello.hex` 复制到 Vivado 项目根目录，然后使用相对路径。

### 选项3：在 Vivado 中设置工作目录
在仿真设置中指定工作目录。

## 运行仿真

1. **启动仿真**
   ```
   Flow Navigator -> Simulation -> Run Simulation -> Run Behavioral Simulation
   ```

2. **查看波形**
   - Vivado 会自动打开波形窗口
   - 添加需要观察的信号到波形窗口
   - 运行仿真

3. **查看输出**
   - 在 TCL 控制台查看 `$display` 输出
   - 应该能看到 "Hello World" 输出

## 常见问题

### Q: 找不到 hello.hex 文件
**A:** 检查文件路径，确保 `$readmemh` 的路径正确。可以在 Vivado 中设置工作目录。

### Q: 波形文件在哪里？
**A:** Vivado 的波形文件默认保存在：
```
项目目录/riscv-pipeline-cpu.sim/sim_1/behav/xsim/
```

### Q: 如何保存波形？
**A:** 在波形窗口中：
- File -> Save Waveform Configuration
- 或者使用 TCL 命令保存波形

### Q: 仿真很慢怎么办？
**A:** 
- 减少仿真时间
- 只添加必要的信号到波形窗口
- 使用更快的仿真模式

## 与 iverilog 的主要区别

| 特性 | iverilog/vvp | Vivado xsim |
|------|-------------|-------------|
| 波形文件 | `$dumpfile`/`$dumpvars` | 自动生成，使用 `.wdb` 格式 |
| 文件路径 | 相对于运行目录 | 相对于项目目录或工作目录 |
| 仿真速度 | 较快 | 较慢（但功能更全） |
| 调试功能 | 基础 | 更强大的调试工具 |

## 推荐工作流程

1. **开发阶段**：使用 `make fastsim`（iverilog）快速迭代
2. **验证阶段**：使用 Vivado 进行更详细的波形分析和调试
3. **综合阶段**：在 Vivado 中进行综合和实现（如果需要上板）

## 注意事项

- 这个项目主要是用于仿真的 CPU，不是为 FPGA 综合设计的
- 如果要在 FPGA 上运行，需要：
  - 添加时钟约束
  - 添加复位约束
  - 可能需要修改内存实现（使用 BRAM）
  - 添加 I/O 接口
