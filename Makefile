# RISC-V CPU 项目 Makefile

# 工具链配置
RISCV_PREFIX ?= riscv64-unknown-elf-
CC = $(RISCV_PREFIX)gcc
OBJDUMP = $(RISCV_PREFIX)objdump
OBJCOPY = $(RISCV_PREFIX)objcopy

# 目录配置
TEST_DIR = test
BUILD_DIR = $(TEST_DIR)/build
SRC_DIR = src
WAVEFORM_DIR = /mnt/c/Users/Lenovo/Desktop/waveform_check

# 文件配置
C_SOURCE = $(TEST_DIR)/hello.c
ASM_OUTPUT = $(BUILD_DIR)/hello.s
ELF_OUTPUT = $(BUILD_DIR)/hello.elf
BIN_OUTPUT = $(BUILD_DIR)/hello.bin
HEX_OUTPUT = $(BUILD_DIR)/hello.hex
OBJDUMP_OUTPUT = $(BUILD_DIR)/hello.dump

# 仿真配置
SIMULATOR = iverilog
VVP = vvp
TB_FILE = $(TEST_DIR)/testbench.v
SRC_FILES = $(SRC_DIR)/*.v
SIM_EXEC = $(TEST_DIR)/sim
VCD_FILE = $(WAVEFORM_DIR)/demodump.vcd
VCD_FILE_LOCAL = $(TEST_DIR)/demodump.vcd

# 编译选项
CFLAGS = -march=rv32i -mabi=ilp32 -nostdlib -Ttext=0x0 -O0 -g
LDFLAGS = -nostdlib -static


# 默认目标
.DEFAULT_GOAL := help

# 创建构建目录
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

# 编译C程序为汇编文件
$(ASM_OUTPUT): $(C_SOURCE) | $(BUILD_DIR)
	@echo "=== 编译C程序为汇编文件 ==="
	$(CC) $(CFLAGS) -S -o $@ $<
	@echo "汇编文件已生成: $@"

# 编译C程序为可执行文件
$(ELF_OUTPUT): $(C_SOURCE) | $(BUILD_DIR)
	@echo "=== 编译C程序为可执行文件 ==="
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<
	@echo "可执行文件已生成: $@"

# 生成二进制文件
$(BIN_OUTPUT): $(ELF_OUTPUT)
	@echo "=== 生成二进制文件 ==="
	$(OBJCOPY) -O binary $< $@
	@echo "二进制文件已生成: $@"

# 生成十六进制文件（用于Verilog $readmemh）
$(HEX_OUTPUT): $(BIN_OUTPUT)
	@echo "=== 生成十六进制文件 ==="
	@if command -v xxd >/dev/null 2>&1; then \
		xxd -p -c 4 $< | sed 's/\(..\)\(..\)\(..\)\(..\)/\4\3\2\1/' > $@; \
	elif command -v od >/dev/null 2>&1; then \
		od -An -tx4 -w4 $< | sed 's/ //g' | sed 's/\(..\)\(..\)\(..\)\(..\)/\4\3\2\1/' > $@; \
	else \
		python3 -c "import sys; data=open('$<','rb').read(); [print(format(int.from_bytes(data[i:i+4],'little'),'08x')) for i in range(0,len(data),4)]" > $@; \
	fi
	@echo "十六进制文件已生成: $@"
	@cp $@ $(TEST_DIR)/hello.hex
	@cp $@ $(SRC_DIR)/hello.hex
	@echo "已复制到 $(TEST_DIR)/hello.hex 和 $(SRC_DIR)/hello.hex"

# 编译目标：生成汇编文件和可执行文件
compile: $(ASM_OUTPUT) $(ELF_OUTPUT) $(BIN_OUTPUT) $(HEX_OUTPUT)
	@echo ""
	@echo "=== 编译完成 ==="
	@echo "汇编文件: $(ASM_OUTPUT)"
	@echo "可执行文件: $(ELF_OUTPUT)"
	@echo "二进制文件: $(BIN_OUTPUT)"
	@echo "十六进制文件: $(HEX_OUTPUT)"

# 生成反汇编文件
objdump: $(ELF_OUTPUT)
	@echo "=== 生成反汇编文件 ==="
	$(OBJDUMP) -d -S $< > $(OBJDUMP_OUTPUT)
	@echo "反汇编文件已生成: $(OBJDUMP_OUTPUT)"
	@echo ""
	@echo "前20行反汇编内容:"
	@head -n 20 $(OBJDUMP_OUTPUT)

# 检查RISC-V工具链
check-toolchain:
	@echo "=== 检查RISC-V工具链 ==="
	@if ! command -v $(CC) >/dev/null 2>&1; then \
		echo "错误: 未找到RISC-V工具链 ($(CC))"; \
		echo "请安装: sudo apt-get install gcc-riscv64-unknown-elf"; \
		exit 1; \
	fi
	@echo "RISC-V工具链检查通过"
	@$(CC) --version | head -n 1

# 检查仿真器
check-simulator:
	@echo "=== 检查仿真器 ==="
	@if ! command -v $(SIMULATOR) >/dev/null 2>&1; then \
		echo "错误: 未找到仿真器 ($(SIMULATOR))"; \
		echo "请安装: sudo apt-get install iverilog"; \
		exit 1; \
	fi
	@echo "仿真器检查通过"
	@$(SIMULATOR) -v | head -n 1

# 准备仿真：生成测试程序
prepare-sim: $(HEX_OUTPUT)
	@echo "=== 准备仿真文件 ==="
	@if [ ! -f $(TEST_DIR)/hello.hex ]; then \
		echo "警告: hello.hex不存在，请先运行 make compile"; \
		exit 1; \
	fi

# 快速仿真（不生成波形文件）
fastsim: prepare-sim check-simulator
	@echo "=== 快速仿真（无波形文件）==="
	@cd $(TEST_DIR) && \
	$(SIMULATOR) -DNO_WAVEFORM -o sim $(TB_FILE) ../$(SRC_DIR)/*.v && \
	$(VVP) sim
	@echo "=== 仿真完成 ==="

# 完整仿真（生成波形文件）
sim: prepare-sim check-simulator
	@echo "=== 完整仿真（生成波形文件）==="
	@cd $(TEST_DIR) && \
	$(SIMULATOR) -o sim $(TB_FILE) ../$(SRC_DIR)/*.v && \
	$(VVP) sim
	@echo ""
	@if [ -f $(VCD_FILE) ]; then \
		echo "=== 波形文件已保存到Windows共享文件夹 ==="; \
		echo "路径: $(VCD_FILE)"; \
	elif [ -f $(VCD_FILE_LOCAL) ]; then \
		echo "=== 波形文件已保存到本地 ==="; \
		echo "路径: $(VCD_FILE_LOCAL)"; \
		echo "请手动复制到: $(WAVEFORM_DIR)/demodump.vcd"; \
	else \
		echo "警告: 未找到波形文件"; \
	fi

# 清理构建文件
clean:
	@echo "=== 清理构建文件 ==="
	rm -rf $(BUILD_DIR)
	rm -f $(TEST_DIR)/sim $(TEST_DIR)/*.vcd
	rm -f $(TEST_DIR)/hello.hex $(SRC_DIR)/hello.hex
	@echo "清理完成"

# 完全清理（包括波形文件）
distclean: clean
	@echo "=== 完全清理 ==="
	rm -f $(WAVEFORM_DIR)/demodump.vcd 2>/dev/null || true
	@echo "完全清理完成"

# 显示帮助信息
help:
	@echo "=========================================="
	@echo "  RISC-V 32位五级流水线CPU - Makefile"
	@echo "=========================================="
	@echo ""
	@echo "可用命令:"
	@echo ""
	@echo "  make compile          - 编译hello.c，生成汇编文件和可执行文件"
	@echo "                         输出目录: test/build/"
	@echo ""
	@echo "  make objdump          - 生成可执行文件的反汇编文件"
	@echo "                         输出文件: test/build/hello.dump"
	@echo ""
	@echo "  make sim              - 执行完整仿真并生成波形文件"
	@echo "                         波形文件保存到Windows共享文件夹"
	@echo ""
	@echo "  make fastsim          - 执行快速仿真（不生成波形文件）"
	@echo "                         用于快速测试，速度更快"
	@echo ""
	@echo "  make clean            - 清理构建文件（build目录、仿真文件等）"
	@echo ""
	@echo "  make distclean        - 完全清理（包括波形文件）"
	@echo ""
	@echo "  make help             - 显示此帮助信息"
	@echo ""
	@echo "  make check-toolchain  - 检查RISC-V工具链是否安装"
	@echo ""
	@echo "  make check-simulator  - 检查仿真器是否安装"
	@echo ""
	@echo "=========================================="
	@echo ""
	@echo "文件位置:"
	@echo "  C源文件:     $(C_SOURCE)"
	@echo "  构建目录:    $(BUILD_DIR)"
	@echo "  波形文件:    $(WAVEFORM_DIR)/demodump.vcd"
	@echo ""

.PHONY: compile objdump sim fastsim clean distclean help check-toolchain check-simulator prepare-sim

