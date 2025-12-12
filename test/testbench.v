// RISC-V CPU测试平台
`timescale 1ns/1ps

module testbench;

    reg clk;
    reg rst;
    wire [31:0] pc;
    // 调试输出端口（防止综合优化，仿真中可以不使用）
    wire [31:0] debug_instruction;
    wire [31:0] debug_alu_result;
    wire [31:0] debug_mem_rdata;
    wire [31:0] debug_wb_data;
    
    // CPU实例
    top cpu_inst(
        .clk(clk),
        .rst(rst),
        .pc_out(pc),
        .debug_instruction(debug_instruction),
        .debug_alu_result(debug_alu_result),
        .debug_mem_rdata(debug_mem_rdata),
        .debug_wb_data(debug_wb_data)
    );
    
    // 时钟生成
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns周期，50MHz
    end
    
    // 复位序列
    initial begin
        rst = 1;
        #100;
        rst = 0;
        $display("=== CPU仿真开始 ===");
        $display("程序输出:");
        $display("----------------------------------------");
        #5000;  // 运行5000ns
        $display("----------------------------------------");
        $display("Simulation finished at time %0t", $time);
        $finish;
    end
    
    // 波形文件输出
    // 在 Vivado 中：使用 Vivado 自带的 .wdb 波形格式（自动生成，无需 $dumpfile）
    // 在 iverilog 中：使用 VCD 格式（通过定义 USE_VCD 宏启用）
    `ifdef USE_VCD
    initial begin
        // 仅在使用 iverilog 时生成 VCD 文件
        $dumpfile("../src/demodump.vcd");
        $display("Waveform file: ../src/demodump.vcd");
        $dumpvars(0, testbench);
    end
    `endif
    // 注意：Vivado 会自动生成 .wdb 波形文件，无需手动配置
    
    // 监控信号
    integer cycle_count;
    initial cycle_count = 0;
    
    always @(posedge clk) begin
        if (!rst) begin
            cycle_count = cycle_count + 1;
            // 减少时间戳输出频率，让Hello World输出更清晰
            if (cycle_count % 100 == 0) begin
                $display("Time: %0t ns, Cycle: %0d, PC: %h", $time, cycle_count, pc);
            end
        end
    end

endmodule

