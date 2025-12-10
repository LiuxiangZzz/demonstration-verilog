// RISC-V CPU测试平台
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
        $display("=== CPU仿真开始 ===");
        $display("程序输出:");
        $display("----------------------------------------");
        #5000;  // 运行5000ns
        $display("----------------------------------------");
        $display("Simulation finished at time %0t", $time);
        $finish;
    end
    
    // 波形文件输出到src目录
    // 可以通过定义NO_WAVEFORM宏来禁用波形文件生成（用于fastsim）
    `ifndef NO_WAVEFORM
    initial begin
        // 输出到src目录
        $dumpfile("../src/demodump.vcd");
        $display("Waveform file: ../src/demodump.vcd");
        $dumpvars(0, testbench);
    end
    `else
    initial begin
        $display("Waveform generation disabled (NO_WAVEFORM defined)");
    end
    `endif
    
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

