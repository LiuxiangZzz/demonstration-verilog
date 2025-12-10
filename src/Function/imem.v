// 指令存储器模块（只读）
module imem(
    input [31:0] addr,
    output reg [31:0] instruction
);

    // 指令存储器：64KB (16K words)
    reg [31:0] mem [0:16383];
    
    // 从文件加载指令
    integer i;
    reg file_loaded;
    initial begin
        // 先初始化为NOP
        for (i = 0; i < 16384; i = i + 1) begin
            mem[i] = 32'h00000013;  // NOP
        end
        
        // 尝试从多个路径加载
        file_loaded = 0;
        $readmemh("../pipeline/hello.hex", mem);
        if (mem[0] != 32'h00000013) begin
            file_loaded = 1;
            $display("Successfully loaded instructions from ../pipeline/hello.hex");
        end else begin
            $readmemh("hello.hex", mem);
            if (mem[0] != 32'h00000013) begin
                file_loaded = 1;
                $display("Successfully loaded instructions from hello.hex");
            end else begin
                $readmemh("../test/hello.hex", mem);
                if (mem[0] != 32'h00000013) begin
                    file_loaded = 1;
                    $display("Successfully loaded instructions from ../test/hello.hex");
                end else begin
                    $readmemh("test/hello.hex", mem);
                    if (mem[0] != 32'h00000013) begin
                        file_loaded = 1;
                        $display("Successfully loaded instructions from test/hello.hex");
                    end else begin
                        $display("Warning: Could not load hello.hex, using NOPs");
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

