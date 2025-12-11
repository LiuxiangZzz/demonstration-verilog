# Vivado 使用指南

## 兼容性分析

### ✅ 完全兼容的特性
- 标准 Verilog 语法（always、initial、wire、reg 等）
- `$readmemh` - Vivado 完全支持
- `$display` - Vivado 完全支持
- `$dumpfile` / `$dumpvars` - Vivado 支持（但建议使用 Vivado 的波形查看器）
- 条件编译 `ifdef/ifndef` - Vivado 支持
- 所有模块结构和端口定义

### ⚠️ 需要注意的问题

1. **文件路径问题**
   - 当前代码使用相对路径（如 `../pipeline/hello.hex`）
   - Vivado 中工作目录可能不同，需要调整路径或使用绝对路径

2. **波形文件格式**
   - 当前使用 VCD 格式（`$dumpfile`）
   - Vivado 原生支持 WDB 格式，但 VCD 也可以使用

3. **测试平台**
   - 当前 testbench 是为 iverilog 设计的
   - 在 Vivado 中需要创建新的测试平台或修改现有 testbench

## 在 Vivado 中运行步骤

### 方法1：创建 Vivado 项目（推荐）

1. **创建新项目**
   ```
   File → New Project
   ```

2. **添加源文件**
   - 添加所有 `src/pipeline/*.v` 文件
   - 添加所有 `src/Function/*.v` 文件
   - 添加 `test/testbench.v` 文件

3. **设置顶层模块**
   - 仿真时：`testbench`
   - 综合时：`top`

4. **添加约束文件（如果需要综合）**
   - 创建时钟约束
   - 创建复位约束

5. **运行仿真**
   ```
   Flow → Run Simulation → Run Behavioral Simulation
   ```

### 方法2：修改文件路径

如果要在 Vivado 中使用现有 testbench，需要修改文件路径：

1. **修改 imem.v 中的路径**
   ```verilog
   // 将相对路径改为绝对路径或 Vivado 项目路径
   $readmemh("hello.hex", mem);
   ```

2. **修改 dmem.v 中的路径**
   ```verilog
   $readmemh("hello.hex", temp_mem);
   ```

3. **修改 testbench.v 中的波形文件路径**
   ```verilog
   $dumpfile("demodump.vcd");
   ```

### 方法3：使用 TCL 脚本（自动化）

创建 `run_vivado.tcl` 脚本来自动化项目创建和仿真。

## 综合到 FPGA

如果要综合到 FPGA：

1. **添加约束文件**
   - 时钟频率约束
   - I/O 引脚约束（如果有外部接口）

2. **设置综合选项**
   - 选择目标 FPGA 器件
   - 设置优化策略

3. **运行综合**
   ```
   Flow → Run Synthesis
   ```

4. **实现和生成比特流**
   ```
   Flow → Run Implementation
   Flow → Generate Bitstream
   ```

## 注意事项

1. **内存初始化**
   - Vivado 对 `$readmemh` 的路径解析可能与 iverilog 不同
   - 建议将 `hello.hex` 放在项目根目录或使用绝对路径

2. **仿真时间**
   - 当前 testbench 运行 5000ns
   - 可以在 Vivado 中调整仿真时间

3. **波形查看**
   - Vivado 使用 WDB 格式更高效
   - 但 VCD 格式也可以正常使用

4. **调试**
   - Vivado 的调试工具更强大
   - 可以使用 ILA (Integrated Logic Analyzer) 进行硬件调试

## 快速测试脚本

可以创建一个简单的 TCL 脚本来快速测试：

```tcl
# create_project.tcl
create_project riscv_cpu ./vivado_project -part xc7a35tcpg236-1
add_files {src/pipeline/*.v src/Function/*.v}
add_files -fileset sim_1 test/testbench.v
set_property top testbench [get_filesets sim_1]
launch_simulation
```

