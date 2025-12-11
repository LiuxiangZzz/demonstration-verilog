# Verilog 代码到 FPGA 硬件的映射说明

## 整体流程

```
Verilog 代码 → 综合 (Synthesis) → 实现 (Implementation) → 比特流 (Bitstream) → FPGA 板子
```

## 1. 代码层次结构

### 顶层模块 (`top.v`)
```verilog
module top(
    input clk,        // ← 连接到板子的时钟引脚
    input rst,         // ← 连接到板子的复位按钮
    output [31:0] pc_out  // ← 连接到板子的 LED 或显示设备
);
```

**作用：** 这是 FPGA 板子"看到"的接口，所有端口都会映射到物理引脚。

### 子模块（内部逻辑）
- `if_stage.v` - 取指阶段
- `decode_stage.v` - 译码阶段
- `ex_stage.v` - 执行阶段
- `mem_stage.v` - 访存阶段
- `wb_stage.v` - 写回阶段
- `alu.v`, `control.v`, `regfile.v` 等

**作用：** 这些模块会被综合成 FPGA 内部的逻辑资源（查找表 LUT、寄存器等）。

## 2. 硬件资源映射

### 2.1 顶层端口 → 物理引脚

| Verilog 端口 | 硬件位置 | 约束文件设置 |
|-------------|---------|------------|
| `clk` | 板子时钟输入引脚 | `create_clock` + `PACKAGE_PIN` |
| `rst` | 复位按钮引脚 | `PACKAGE_PIN` |
| `pc_out[31:0]` | LED 灯或显示设备 | `PACKAGE_PIN` (32个引脚) |

**约束文件示例：**
```tcl
# 时钟引脚（Nexys A7-200T 的时钟引脚）
set_property PACKAGE_PIN E3 [get_ports clk]

# 复位按钮（Nexys A7-200T 的 CPU_RESET 按钮）
set_property PACKAGE_PIN C12 [get_ports rst]

# PC 输出到 LED（示例）
set_property PACKAGE_PIN U16 [get_ports {pc_out[0]}]
set_property PACKAGE_PIN E19 [get_ports {pc_out[1]}]
# ... 其他位
```

### 2.2 内部逻辑 → FPGA 资源

#### 组合逻辑（如 ALU、控制单元）
```verilog
// 这些代码会被综合成查找表 (LUT)
assign result = a + b;
assign control = (opcode == 7'b0110011) ? 1'b1 : 1'b0;
```
**映射到：** FPGA 的查找表 (LUT) 和可编程互连

#### 时序逻辑（如寄存器、流水线寄存器）
```verilog
// 这些代码会被综合成触发器 (Flip-Flop)
always @(posedge clk) begin
    if (rst) reg <= 32'b0;
    else reg <= next_value;
end
```
**映射到：** FPGA 的触发器 (FF) 或寄存器

#### 存储器（如 imem、dmem）
```verilog
// 64KB 存储器
reg [31:0] mem [0:16383];
```
**映射到：** 
- **Block RAM (BRAM)**：FPGA 内置的块存储器
- 或 **分布式 RAM**：使用 LUT 实现的小容量存储器
- 你的 64KB 内存会使用多个 BRAM

#### 状态机（如 dmem 的状态机）
```verilog
reg [2:0] state;
always @(posedge clk) begin
    case (state)
        IDLE: state <= READ_DELAY;
        READ_DELAY: state <= IDLE;
    endcase
end
```
**映射到：** LUT + FF 的组合

## 3. 综合和实现过程

### 步骤1：综合 (Synthesis)
```
Verilog 代码 → 门级网表
```
- 将 Verilog 代码转换为逻辑门
- 优化逻辑
- 生成网表文件

### 步骤2：实现 (Implementation)
```
网表 → 布局布线
```
- **布局 (Place)**：将逻辑单元分配到 FPGA 的具体位置
- **布线 (Route)**：连接各个逻辑单元
- 考虑时序约束

### 步骤3：生成比特流 (Bitstream)
```
布局布线结果 → .bit 文件
```
- 生成 FPGA 配置文件
- 包含所有配置信息

### 步骤4：下载到板子
```
.bit 文件 → FPGA 板子
```
- 通过 JTAG/USB 下载
- FPGA 根据比特流配置内部资源

## 4. 你的项目中的具体映射

### 4.1 顶层模块端口

**`top.v` 的端口：**
```verilog
input clk;           // → 板子时钟引脚（如 Nexys A7-200T 的 E3）
input rst;           // → 板子复位按钮（如 CPU_RESET）
output [31:0] pc_out; // → 32个 LED 或显示设备引脚
```

### 4.2 内存映射

**指令存储器 (`imem.v`)：**
- 64KB = 16K × 32位
- 映射到：**Block RAM (BRAM)**
- XC7A200T 有足够的 BRAM（约 365 个 36Kb BRAM）

**数据存储器 (`dmem.v`)：**
- 64KB = 16K × 32位
- 映射到：**Block RAM (BRAM)**
- 与指令存储器共享或分开使用 BRAM

### 4.3 寄存器文件 (`regfile.v`)
```verilog
reg [31:0] registers [0:31];  // 32个32位寄存器
```
- 映射到：**分布式 RAM** 或 **BRAM**
- 32个寄存器 × 32位 = 1024位，通常用分布式 RAM

### 4.4 流水线寄存器 (`pipeline_regs.v`)
- IF/ID、ID/EX、EX/MEM、MEM/WB 寄存器
- 映射到：**触发器 (FF)**
- 每个寄存器位需要一个 FF

### 4.5 ALU 和控制单元
- 组合逻辑
- 映射到：**查找表 (LUT)**
- 复杂的运算可能需要多个 LUT

## 5. 约束文件的作用

### 5.1 时钟约束
```tcl
create_clock -period 10.000 -name clk [get_ports clk]
```
**作用：** 告诉工具时钟频率，用于时序分析

### 5.2 引脚约束
```tcl
set_property PACKAGE_PIN E3 [get_ports clk]
```
**作用：** 将 Verilog 端口映射到 FPGA 的物理引脚

### 5.3 I/O 标准
```tcl
set_property IOSTANDARD LVCMOS33 [get_ports clk]
```
**作用：** 指定引脚的电压标准（3.3V）

## 6. 实际映射示例

### 示例：将 PC 输出到 LED

**1. 修改顶层模块（如果需要）：**
```verilog
module top(
    input clk,
    input rst,
    output [15:0] pc_out_led  // 只使用低16位显示在LED上
);
    // ... 内部逻辑
    assign pc_out_led = pc[15:0];
endmodule
```

**2. 在约束文件中指定引脚：**
```tcl
# Nexys A7-200T 的 LED 引脚（示例）
set_property PACKAGE_PIN U16 [get_ports {pc_out_led[0]}]
set_property PACKAGE_PIN E19 [get_ports {pc_out_led[1]}]
# ... 其他 LED 引脚
set_property IOSTANDARD LVCMOS33 [get_ports {pc_out_led[*]}]
```

**3. 综合和实现后：**
- `pc_out_led[0]` → FPGA 引脚 U16 → 板子 LED0
- `pc_out_led[1]` → FPGA 引脚 E19 → 板子 LED1
- ...

## 7. 资源使用估算

### XC7A200T 资源
- **LUT**: 126,800
- **FF**: 253,600
- **BRAM**: 365 × 36Kb

### 你的项目估算
- **LUT**: ~5,000-10,000（ALU、控制逻辑等）
- **FF**: ~2,000-5,000（流水线寄存器、状态机等）
- **BRAM**: ~8-16 个（64KB 指令内存 + 64KB 数据内存）

**结论：** 资源充足，完全可以在 XC7A200T 上实现

## 8. 总结

1. **顶层模块端口** → **物理引脚**（通过约束文件）
2. **内部逻辑** → **LUT + FF + BRAM**
3. **约束文件** → **告诉工具如何映射**
4. **综合实现** → **生成比特流**
5. **下载到板子** → **FPGA 按配置工作**

**关键点：**
- 只有顶层模块的端口会连接到板子外部
- 内部模块会被综合成 FPGA 内部资源
- 约束文件是连接代码和硬件的桥梁

