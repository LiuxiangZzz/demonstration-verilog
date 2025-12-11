# Verilog 代码到 FPGA 硬件的映射关系

## 简单理解

### 1. 顶层模块 = FPGA 的"接口"

```verilog
module top(
    input clk,           // ← 这个会连接到板子的时钟引脚
    input rst,            // ← 这个会连接到板子的按钮
    output [31:0] pc_out  // ← 这个会连接到板子的 LED 或显示器
);
```

**类比：** 就像电脑的 USB 接口，顶层模块是 FPGA 的"接口"。

### 2. 内部模块 = FPGA 的"大脑"

```verilog
// 这些模块在 FPGA 内部，不会直接连接到外部
if_stage if_stage_inst(...);
decode_stage decode_stage_inst(...);
ex_stage ex_stage_inst(...);
```

**类比：** 就像电脑的 CPU、内存，在 FPGA 内部工作。

## 详细映射流程

### 步骤1：代码 → 逻辑单元

```
Verilog 代码
    ↓
综合工具 (Vivado Synthesis)
    ↓
逻辑门网表（LUT、FF、BRAM）
```

**例子：**
```verilog
// 你的代码
assign result = a + b;

// 综合后变成
LUT1 + LUT2 + ... (多个查找表实现加法)
```

### 步骤2：逻辑单元 → FPGA 位置

```
逻辑门网表
    ↓
布局工具 (Place)
    ↓
分配到 FPGA 的具体位置
```

**例子：**
- ALU 的逻辑 → FPGA 的某个区域的 LUT
- 寄存器 → FPGA 的某个区域的 FF
- 内存 → FPGA 的 BRAM 块

### 步骤3：端口 → 物理引脚

```
顶层模块端口
    ↓
约束文件 (constraints.xdc)
    ↓
FPGA 物理引脚
    ↓
板子接口
```

**例子：**
```verilog
// 代码中
output [15:0] pc_out;

// 约束文件中
set_property PACKAGE_PIN U16 [get_ports {pc_out[0]}]

// 实际连接
pc_out[0] → FPGA 引脚 U16 → 板子 LED0
```

## 你的项目中的具体映射

### 顶层模块 (`top.v`)

```verilog
module top(
    input clk,        // → 板子时钟（引脚 E3）
    input rst,         // → 复位按钮（引脚 C12）
    output [31:0] pc_out  // → LED 灯（引脚 U16, E19, ...）
);
```

**映射关系：**
- `clk` → FPGA 引脚 E3 → Nexys A7-200T 时钟输入
- `rst` → FPGA 引脚 C12 → CPU_RESET 按钮
- `pc_out[0]` → FPGA 引脚 U16 → LED0
- `pc_out[1]` → FPGA 引脚 E19 → LED1
- ... 以此类推

### 内部模块（不直接连接外部）

#### 指令存储器 (`imem.v`)
```verilog
reg [31:0] mem [0:16383];  // 64KB 内存
```
**映射到：** FPGA 的 Block RAM (BRAM)
- 你的 64KB → 使用约 8-16 个 BRAM 块
- 在 FPGA 内部，不连接到外部引脚

#### 数据存储器 (`dmem.v`)
```verilog
reg [31:0] mem [0:16383];  // 64KB 内存
```
**映射到：** FPGA 的 Block RAM (BRAM)
- 同样在 FPGA 内部

#### ALU (`alu.v`)
```verilog
assign result = a + b;
```
**映射到：** FPGA 的查找表 (LUT)
- 加法运算 → 多个 LUT 组合实现
- 在 FPGA 内部

#### 寄存器文件 (`regfile.v`)
```verilog
reg [31:0] registers [0:31];  // 32个寄存器
```
**映射到：** FPGA 的分布式 RAM 或 BRAM
- 在 FPGA 内部

## 约束文件的作用

约束文件 (`constraints.xdc`) 是"翻译器"，告诉工具：

1. **哪个端口连接到哪个引脚**
   ```tcl
   set_property PACKAGE_PIN E3 [get_ports clk]
   ```
   "clk 端口连接到 FPGA 的 E3 引脚"

2. **时钟频率是多少**
   ```tcl
   create_clock -period 10.000 -name clk
   ```
   "时钟周期是 10ns（100MHz）"

3. **电压标准是什么**
   ```tcl
   set_property IOSTANDARD LVCMOS33 [get_ports clk]
   ```
   "使用 3.3V 标准"

## 完整流程示例

### 例子：PC 值显示在 LED 上

**1. 代码中：**
```verilog
module top(
    input clk,
    input rst,
    output [15:0] pc_out  // PC 的低 16 位
);
    // CPU 运行，PC 值不断变化
    // pc_out 连接到内部 PC 寄存器
endmodule
```

**2. 约束文件中：**
```tcl
# PC 的第 0 位连接到 LED0
set_property PACKAGE_PIN U16 [get_ports {pc_out[0]}]
# PC 的第 1 位连接到 LED1
set_property PACKAGE_PIN E19 [get_ports {pc_out[1]}]
# ... 其他位
```

**3. 综合实现后：**
- CPU 内部 PC 寄存器 → 通过内部连线 → `pc_out` 端口
- `pc_out[0]` → FPGA 引脚 U16 → 板子 LED0
- `pc_out[1]` → FPGA 引脚 E19 → 板子 LED1
- ...

**4. 实际效果：**
- LED0-LED15 显示 PC 的二进制值
- PC 变化时，LED 也会变化

## 资源使用

### XC7A200T 的资源
- **LUT**: 126,800 个
- **FF**: 253,600 个
- **BRAM**: 365 个（每个 36Kb）

### 你的项目使用
- **LUT**: ~5,000-10,000（ALU、控制逻辑）
- **FF**: ~2,000-5,000（流水线寄存器）
- **BRAM**: ~8-16 个（64KB × 2 = 128KB 内存）

**结论：** 资源充足！

## 总结

1. **顶层模块端口** → **约束文件** → **FPGA 引脚** → **板子接口**
2. **内部模块** → **综合工具** → **LUT/FF/BRAM** → **FPGA 内部资源**
3. **只有顶层端口**会连接到板子外部
4. **约束文件**是连接代码和硬件的桥梁

**关键点：**
- 代码的顶层端口 = FPGA 的接口
- 代码的内部逻辑 = FPGA 的内部资源
- 约束文件 = 告诉工具如何连接

