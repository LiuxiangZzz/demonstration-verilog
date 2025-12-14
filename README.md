# RISC-V 32位五级流水线CPU

## 项目简介

本项目实现了一个基于RISC-V指令集架构的32位五级流水线CPU，支持RV32I基础指令集。CPU采用经典的MIPS风格五级流水线结构，包含完整的冒险检测和数据前推机制。

### 主要特性

- ✅ **五级流水线结构**：IF（取指）→ ID（译码）→ EX（执行）→ MEM（访存）→ WB（写回）
- ✅ **支持的指令**：ADDI, ADD, SUB, LW, SW, BEQ, JAL, JALR, LUI
- ✅ **冒险处理**：数据前推（Forwarding）+ Load-Use Stall
- ✅ **内存系统**：分离的指令存储器（imem）和数据存储器（dmem），各64KB
- ✅ **内存映射I/O**：通过地址0x10000000实现简单的字符输出
- ✅ **多周期访存**：支持带延迟的内存访问，使用握手协议

### 目标平台

- **FPGA器件**：Xilinx Artix-7 (xc7a200tfbg676-1)
- **适用场景**：龙芯杯团队赛、RISC-V CPU学习、流水线设计实践

---

## 文件目录结构

```
demonstration-verilog/
├── README.md                    # 项目说明文档（本文件）
├── Makefile                     # 构建和仿真脚本
├── .gitignore                  # Git忽略文件配置
│
├── create_vivado_project.tcl   # Vivado项目创建脚本
├── constraints_loongson_cup.xdc # FPGA约束文件（龙芯杯板子）
├── setup_shared_folder.sh      # VMware共享文件夹设置脚本
│
├── src/                        # 源代码目录
│   ├── pipeline/               # 流水线阶段模块
│   │   ├── top.v              # 顶层模块
│   │   ├── if_stage.v         # 取指阶段
│   │   ├── decode_stage.v     # 译码阶段
│   │   ├── ex_stage.v         # 执行阶段
│   │   ├── mem_stage.v        # 访存阶段
│   │   ├── wb_stage.v         # 写回阶段
│   │   └── hello.hex          # 程序十六进制文件
│   │
│   └── Function/              # 功能模块
│       ├── alu.v              # 算术逻辑单元
│       ├── control.v          # 控制单元
│       ├── regfile.v          # 寄存器文件
│       ├── imem.v             # 指令存储器
│       ├── dmem.v             # 数据存储器
│       └── pipeline_regs.v    # 流水线寄存器
│
└── test/                      # 测试文件目录
    ├── hello.c                # 测试程序（C源代码）
    ├── testbench.v            # iverilog测试平台
    ├── testbench_vivado.v     # Vivado测试平台
    ├── hello.hex              # 程序十六进制文件（编译生成）
    └── build/                 # 编译输出目录
        ├── hello.elf          # ELF可执行文件
        ├── hello.bin          # 二进制文件
        ├── hello.hex          # 十六进制文件
        └── hello.dump         # 反汇编文件
```

---

## 开发环境

### 必需工具

1. **RISC-V工具链**
   - GCC编译器：`riscv64-unknown-elf-gcc`
   - 用于编译C程序生成机器码

2. **仿真工具**（二选一）
   - **iverilog** + **vvp**：开源Verilog仿真器
   - **Vivado**：Xilinx官方工具（推荐用于综合和实现）

3. **综合工具**
   - **Vivado**：Xilinx FPGA开发工具
   - 版本要求：Vivado 2018.1 或更高版本

### 可选工具

- **GTKWave**：波形查看器（用于查看VCD文件）
- **Python 3**：用于脚本辅助（已包含在项目中）

---

## 快速开始

### 1. 编译测试程序

```bash
# 编译hello.c，生成hello.hex文件
make compile
```

这会生成以下文件：
- `test/build/hello.elf` - ELF可执行文件
- `test/build/hello.hex` - 十六进制文件（用于$readmemh）
- `test/build/hello.dump` - 反汇编文件

### 2. 运行仿真（iverilog）

```bash
# 快速仿真（不生成波形文件）
make fastsim

# 完整仿真（生成波形文件，当前已注释）
# make sim
```

### 3. 查看反汇编

```bash
# 生成并查看反汇编文件
make objdump
```

---

## 使用Vivado打开项目

### 方法一：使用TCL脚本（推荐）

1. **启动Vivado**
   - 打开Vivado IDE

2. **打开TCL Console**
   - 在Vivado底部找到 "Tcl Console" 标签页

3. **切换到项目目录**
   ```tcl
   cd C:/Users/Lenovo/Desktop/store-project/demonstration-verilog-main/demonstration-verilog-main
   ```
   （根据你的实际路径修改）

4. **运行项目创建脚本**
   ```tcl
   source create_vivado_project.tcl
   ```

5. **等待项目创建完成**
   - 脚本会自动：
     - 创建项目目录
     - 添加所有源文件
     - 添加约束文件
     - 设置顶层模块
     - 配置综合参数

### 方法二：手动创建项目

1. **创建新项目**
   - File → Project → New
   - 项目名称：`riscv-pipeline-cpu`
   - 项目类型：RTL Project

2. **选择器件**
   - 搜索：`xc7a200tfbg676-1`
   - 选择：Artix-7

3. **添加源文件**
   - 添加 `src/pipeline/*.v`
   - 添加 `src/Function/*.v`
   - 添加 `src/pipeline/hello.hex`

4. **添加约束文件**
   - 添加 `constraints_loongson_cup.xdc`

5. **设置顶层模块**
   - 右键 `top.v` → Set as Top

6. **设置综合参数**（重要！）
   ```tcl
   set_param synth.elaboration.rodinMoreOptions {rt::set_parameter dissolveMemorySizeLimit 524288}
   ```

### 验证项目创建

在TCL Console中运行：

```tcl
# 检查源文件
get_files -of_objects [get_filesets sources_1]

# 检查顶层模块
get_property top [get_filesets sources_1]

# 检查hello.hex文件
get_files -filter {FILE_TYPE == "Memory Initialization Files"}
```

---

## 运行命令

### Makefile命令

| 命令 | 功能 | 说明 |
|------|------|------|
| `make compile` | 编译C程序 | 生成hello.hex等文件 |
| `make objdump` | 生成反汇编 | 查看程序汇编代码 |
| `make fastsim` | 快速仿真 | 运行仿真，不生成波形 |
| `make sim` | 完整仿真 | 运行仿真并生成波形（当前已注释） |
| `make clean` | 清理构建文件 | 删除build目录和临时文件 |
| `make deepclean` | 完全清理 | 包括波形文件 |
| `make help` | 显示帮助 | 查看所有可用命令 |

### Vivado操作

#### 运行综合

1. 在 **Design Runs** 标签页
2. 右键 `synth_1` → **Run Synthesis**
3. 等待综合完成

#### 验证综合结果

```tcl
# 检查所有阶段
get_cells -hierarchical -filter {NAME =~ "*stage*"}

# 检查BRAM
get_cells -hierarchical -filter {PRIMITIVE_TYPE =~ "*RAM*"}

# 查看资源使用
report_utilization

# 查看时序
report_timing_summary
```

#### 运行仿真

1. 在 **Sources** 中确认 `testbench_vivado.v` 在 `sim_1` 文件集中
2. 设置仿真顶层：右键 `testbench_vivado.v` → Set as Top
3. 运行仿真：**Run Simulation → Behavioral Simulation**
4. 应该看到 "Hello World" 输出

#### 运行实现

1. 综合完成后，在 **Design Runs** 中
2. 右键 `impl_1` → **Run Implementation**
3. 等待实现完成

#### 生成比特流

1. 实现完成后
2. 右键 `impl_1` → **Generate Bitstream**
3. 等待生成完成

---

## 项目配置说明

### 时钟配置

- **时钟频率**：100MHz（10ns周期）
- **约束文件**：`constraints_loongson_cup.xdc`
- **时钟定义**：`create_clock -period 10.000 -name clk [get_ports clk]`

### 内存配置

- **指令存储器（imem）**：64KB (16K words × 32 bits)
- **数据存储器（dmem）**：64KB (16K words × 32 bits)
- **内存类型**：Block RAM（通过综合属性指定）

### 调试输出

顶层模块包含以下调试输出端口：
- `debug_instruction`：ID阶段的指令
- `debug_alu_result`：EX阶段的ALU结果
- `debug_mem_rdata`：MEM阶段的内存读数据
- `debug_wb_data`：WB阶段的写回数据

这些端口用于防止综合优化，也可用于调试。

---

## 测试程序

### hello.c

测试程序输出 "Hello World\n" 到内存映射I/O地址 `0x10000000`。

**程序流程**：
1. 使用 `LUI` 设置I/O基地址（0x10000000）
2. 使用 `ADDI` 加载ASCII字符
3. 使用 `SW` 输出字符
4. 最后进入死循环

**编译**：
```bash
make compile
```

**查看反汇编**：
```bash
make objdump
```

---

## 常见问题

### 1. 综合时只有if_stage被综合

**原因**：其他阶段的输出未被使用，被优化掉了

**解决**：已通过添加调试输出端口解决，确保所有阶段都被使用

### 2. hello.hex文件未加载

**原因**：文件路径不正确

**解决**：
- 确认 `hello.hex` 在 `src/pipeline/` 目录下
- 确认文件已添加到Vivado项目中
- 检查综合日志中的路径信息

### 3. 内存推断错误

**原因**：内存太大，无法自动推断

**解决**：已通过以下方式解决：
- 添加 `(* ram_style = "block" *)` 综合属性
- 设置综合参数：`set_param synth.elaboration.rodinMoreOptions {rt::set_parameter dissolveMemorySizeLimit 524288}`

### 4. 波形文件不显示数值

**原因**：波形显示格式设置问题

**解决**：
- 在波形查看器中，选中信号 → 右键 → **Radix** → **Hexadecimal**
- **View** → **Time Axis**（勾选）

### 5. 波形文件无法同步到Windows

**原因**：共享文件夹不存在或权限不足

**解决**：
```bash
# 运行设置脚本
./setup_shared_folder.sh

# 或在Windows中手动创建文件夹
# C:\Users\Lenovo\Desktop\waveform_check
```

---

## 项目特点

### 设计亮点

1. **清晰的模块划分**：每个流水线阶段独立模块，易于理解和维护
2. **完善的冒险处理**：数据前推 + Load-Use Stall的组合策略
3. **灵活的内存系统**：支持多周期访存，使用握手协议
4. **实用的调试支持**：调试输出端口 + 内存映射I/O

### 性能指标

- **流水线深度**：5级
- **支持指令数**：9种基础指令（可扩展）
- **内存容量**：128KB（64KB指令 + 64KB数据）
- **目标频率**：100MHz（可调整）

---

## 开发建议

### 扩展指令支持

要添加新指令，需要修改：
1. `src/Function/control.v`：添加指令识别和控制信号
2. `src/Function/alu.v`：添加ALU操作（如需要）
3. `src/pipeline/decode_stage.v`：添加立即数生成（如需要）

### 优化建议

1. **性能优化**：
   - 添加分支预测
   - 优化关键路径
   - 增加指令缓存

2. **功能扩展**：
   - 支持更多RISC-V指令
   - 添加异常处理
   - 支持中断

3. **调试增强**：
   - 添加性能计数器
   - 添加调试接口
   - 增强日志输出

---

## 更新日志

### 最新版本

- ✅ 修复综合优化问题（添加调试输出端口）
- ✅ 修复内存推断错误（添加Block RAM属性）
- ✅ 修复时钟约束问题（启用create_clock）
- ✅ 优化波形文件同步功能
- ✅ 完善项目文档
