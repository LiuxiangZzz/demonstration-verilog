// RISC-V CPU测试平台 - Vivado 兼容版本
`timescale 1ns/1ps

module testbench;

    reg clk;
    reg rst;
    wire [31:0] pc;
    
    // CPU实例
    top cpu_inst(
        .clk(clk),
        .rst(rst),
        .pc_out(pc)
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
        $display("=== CPU Simulation Started ===");
        $display("Program Output:");
        $display("----------------------------------------");
        #5000;  // 运行5000ns（足够运行hello.c程序）
        $display("----------------------------------------");
        $display("Simulation finished at time %0t", $time);
        $finish;
    end
    
    // Vivado 波形文件输出（使用 Vivado 的波形格式）
    // 注意：Vivado 会自动生成波形文件，不需要手动 $dumpfile
    // 如果需要保存波形，可以在 Vivado 中设置：
    // Simulation Settings -> Simulation -> xsim.simulate.log_all_signals = true
    
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

