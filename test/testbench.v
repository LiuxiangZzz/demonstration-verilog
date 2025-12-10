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
    
    // 波形文件输出到Windows共享文件夹
    // 可以通过定义NO_WAVEFORM宏来禁用波形文件生成（用于fastsim）
    `ifndef NO_WAVEFORM
    initial begin
        // 尝试多个可能的路径
        // 优先尝试Windows共享文件夹路径（WSL）
        if ($system("test -d /mnt/c/Users/Lenovo/Desktop/waveform_check") == 0) begin
            $dumpfile("/mnt/c/Users/Lenovo/Desktop/waveform_check/demodump.vcd");
            $display("Waveform file: /mnt/c/Users/Lenovo/Desktop/waveform_check/demodump.vcd");
        end else if ($system("test -d /media/sf_waveform_check") == 0) begin
            $dumpfile("/media/sf_waveform_check/demodump.vcd");
            $display("Waveform file: /media/sf_waveform_check/demodump.vcd");
        end else begin
            // 如果共享文件夹不存在，输出到当前目录
            $dumpfile("demodump.vcd");
            $display("Warning: Windows shared folder not found, saving to: demodump.vcd");
            $display("Please manually copy demodump.vcd to C:\\Users\\Lenovo\\Desktop\\waveform_check\\");
        end
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
            if (cycle_count % 10 == 0) begin
                $display("Time: %0t ns, Cycle: %0d, PC: %h", $time, cycle_count, pc);
            end
        end
    end

endmodule

