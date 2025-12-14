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
# Windows波形文件目录（尝试多个可能的路径）
# WSL路径
WAVEFORM_DIR_WSL = /mnt/c/Users/Lenovo/Desktop/waveform_check
# VMware共享文件夹路径（如果Desktop已挂载）
# 注意：共享文件夹直接映射到 /mnt/hgfs/Desktop，所以 waveform_check 在 /mnt/hgfs/Desktop/waveform_check
WAVEFORM_DIR_VMWARE = /mnt/hgfs/Desktop/waveform_check
# 检测可用的路径
WAVEFORM_DIR = $(shell if [ -d $(WAVEFORM_DIR_WSL) ]; then echo $(WAVEFORM_DIR_WSL); elif [ -d $(WAVEFORM_DIR_VMWARE) ]; then echo $(WAVEFORM_DIR_VMWARE); else echo ""; fi)

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
SRC_FILES = $(SRC_DIR)/pipeline/*.v $(SRC_DIR)/Function/*.v
SIM_EXEC = $(TEST_DIR)/sim
VCD_FILE_SRC = $(SRC_DIR)/demodump.vcd
VCD_FILE_WIN = $(WAVEFORM_DIR)/demodump.vcd

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
	@cp $@ $(SRC_DIR)/pipeline/hello.hex
	@echo "已复制到 $(TEST_DIR)/hello.hex 和 $(SRC_DIR)/pipeline/hello.hex"

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

# 准备仿真：生成测试程序
prepare-sim: $(HEX_OUTPUT)
	@echo "=== 准备仿真文件 ==="
	@if [ ! -f $(TEST_DIR)/hello.hex ]; then \
		echo "警告: hello.hex不存在，请先运行 make compile"; \
		exit 1; \
	fi

# 快速仿真（不生成波形文件）
fastsim: prepare-sim
	@echo "=== 快速仿真（无波形文件）==="
	@cd $(TEST_DIR) && \
	$(SIMULATOR) -DNO_WAVEFORM -o sim testbench.v ../$(SRC_DIR)/pipeline/*.v ../$(SRC_DIR)/Function/*.v && \
	$(VVP) sim
	@echo "=== 仿真完成 ==="

# 完整仿真（生成波形文件）
#sim: prepare-sim
    @echo "=== 完整仿真（生成波形文件）==="
    @cd $(TEST_DIR) && \
    $(SIMULATOR) -DUSE_VCD -o sim testbench.v ../$(SRC_DIR)/pipeline/*.v ../$(SRC_DIR)/Function/*.v && \
    $(VVP) sim
    @echo ""
    @if [ -f $(VCD_FILE_SRC) ]; then \
        echo "=== 波形文件已生成到: $(VCD_FILE_SRC) ==="; \
        WAVEFORM_TARGET=""; \
        SYNC_SUCCESS=0; \
        if [ -d /mnt/c/Users/Lenovo/Desktop ]; then \
            if [ -d /mnt/c/Users/Lenovo/Desktop/waveform_check ] || mkdir -p /mnt/c/Users/Lenovo/Desktop/waveform_check 2>/dev/null; then \
                WAVEFORM_TARGET="/mnt/c/Users/Lenovo/Desktop/waveform_check/demodump.vcd"; \
            fi; \
        elif [ -d /mnt/hgfs/Desktop ]; then \
            if [ -d /mnt/hgfs/Desktop/waveform_check ]; then \
                WAVEFORM_TARGET="/mnt/hgfs/Desktop/waveform_check/demodump.vcd"; \
            fi; \
        fi; \
        if [ -n "$$WAVEFORM_TARGET" ] && [ -d "$$(dirname $$WAVEFORM_TARGET)" ]; then \
            if cp $(VCD_FILE_SRC) $$WAVEFORM_TARGET 2>/dev/null; then \
                echo "=== 已自动同步到Windows文件夹 ==="; \
                echo "路径: $$WAVEFORM_TARGET"; \
                echo "Windows路径: C:\\Users\\Lenovo\\Desktop\\waveform_check\\demodump.vcd"; \
                SYNC_SUCCESS=1; \
            fi; \
        fi; \
        if [ $$SYNC_SUCCESS -eq 0 ]; then \
            echo "警告: 无法自动同步到Windows文件夹"; \
            echo ""; \
            echo "波形文件位置: $(VCD_FILE_SRC)"; \
            echo "目标Windows路径: C:\\Users\\Lenovo\\Desktop\\waveform_check\\demodump.vcd"; \
            echo ""; \
            echo "解决方法:"; \
            echo "  1. 在Windows中手动创建文件夹: C:\\Users\\Lenovo\\Desktop\\waveform_check"; \
            echo "  2. 或运行: ./setup_shared_folder.sh (会自动创建文件夹)"; \
            echo ""; \
            echo "文件大小: $$(du -h $(VCD_FILE_SRC) | cut -f1)"; \
        fi \
    else \
        echo "警告: 未找到波形文件 $(VCD_FILE_SRC)"; \
    fi
	
# 清理构建文件
clean:
	@echo "=== 清理构建文件 ==="
	rm -rf $(BUILD_DIR)
	rm -f $(TEST_DIR)/sim $(TEST_DIR)/*.vcd
	rm -f $(TEST_DIR)/hello.hex $(SRC_DIR)/hello.hex
	rm -f $(VCD_FILE_SRC)
	@echo "清理完成"

# 完全清理（包括波形文件）
deepclean: clean
	@echo "=== 完全清理 ==="
	rm -f $(VCD_FILE_WIN) 2>/dev/null || true
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
	@echo "  make sim               - 执行完整仿真并生成波形文件"
	@echo "                         使用流水线CPU运行程序，波形文件保存到src目录并自动同步到Windows文件夹"
	@echo ""
	@echo "  make fastsim           - 执行快速仿真（不生成波形文件）"
	@echo "                         使用流水线CPU运行程序，用于快速测试，速度更快"
	@echo ""
	@echo "  make clean            - 清理构建文件（build目录、仿真文件等）"
	@echo ""
	@echo "  make deepclean        - 完全清理（包括波形文件）"
	@echo ""
	@echo "  make help             - 显示此帮助信息"
	@echo ""
	@echo "=========================================="
	@echo ""

.PHONY: compile objdump sim fastsim clean deepclean help prepare-sim

