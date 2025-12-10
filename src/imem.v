// 指令存储器模块（只读）
module imem(
    input [31:0] addr,
    output reg [31:0] instruction
);

    // 指令存储器：64KB (16K words)
    reg [31:0] mem [0:16383];
    
    // 从文件加载指令
    initial begin
        // 尝试从多个路径加载
        if (!$readmemh("hello.hex", mem)) begin
            if (!$readmemh("../test/hello.hex", mem)) begin
                if (!$readmemh("test/hello.hex", mem)) begin
                    // 如果都失败，初始化为NOP
                    integer i;
                    for (i = 0; i < 16384; i = i + 1) begin
                        mem[i] = 32'h00000013;  // NOP
                    end
                    $display("Warning: Could not load hello.hex, initializing with NOPs");
                end
            end
        end else begin
            $display("Successfully loaded instructions from hello.hex");
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

