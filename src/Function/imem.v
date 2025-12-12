// 指令存储器模块（只读）
module imem(
    input [31:0] addr,
    output reg [31:0] instruction
);

    // 指令存储器：64KB (16K words)
    // 使用 Block RAM 综合属性，避免内存推断错误
    (* ram_style = "block" *) reg [31:0] mem [0:16383];
    
    // 从文件加载指令
    integer i;
    reg file_loaded;
    initial begin
        // 先初始化为NOP
        for (i = 0; i < 16384; i = i + 1) begin
            mem[i] = 32'h00000013;  // NOP
        end
        
        // Try to load from multiple paths (Vivado synthesis uses project directory as working directory)
        file_loaded = 0;
        // Try absolute path first (most reliable, but requires file to be in project)
        // Then try paths relative to project root
        $readmemh("src/pipeline/hello.hex", mem);
        if (mem[0] != 32'h00000013) begin
            file_loaded = 1;
            $display("Successfully loaded instructions from src/pipeline/hello.hex");
        end else begin
            // Try current working directory (for simulation)
            $readmemh("hello.hex", mem);
            if (mem[0] != 32'h00000013) begin
                file_loaded = 1;
                $display("Successfully loaded instructions from hello.hex");
            end else begin
                // Try other relative paths
                $readmemh("../pipeline/hello.hex", mem);
                if (mem[0] != 32'h00000013) begin
                    file_loaded = 1;
                    $display("Successfully loaded instructions from ../pipeline/hello.hex");
                end else begin
                    $readmemh("test/hello.hex", mem);
                    if (mem[0] != 32'h00000013) begin
                        file_loaded = 1;
                        $display("Successfully loaded instructions from test/hello.hex");
                    end else begin
                        $readmemh("../test/hello.hex", mem);
                        if (mem[0] != 32'h00000013) begin
                            file_loaded = 1;
                            $display("Successfully loaded instructions from ../test/hello.hex");
                        end else begin
                            $display("Warning: Could not load hello.hex, using NOPs");
                        end
                    end
                end
            end
        end
    end
    
    // 读取接口
    always @(*) begin
        if (addr[31:2] < 16384)  // 地址对齐到4字节
            instruction = mem[addr[31:2]];
        else
            instruction = 32'h00000013;  // NOP (ADDI x0, x0, 0)
    end

endmodule

