// 寄存器文件模块
// 32个32位通用寄存器，x0始终为0
module regfile(
    input clk,
    input rst,
    input [4:0] rs1,      // 源寄存器1地址
    input [4:0] rs2,      // 源寄存器2地址
    input [4:0] rd,       // 目标寄存器地址
    input [31:0] wdata,   // 写回数据
    input we,             // 写使能
    output reg [31:0] rdata1,  // 读数据1
    output reg [31:0] rdata2   // 读数据2
);

    reg [31:0] registers [0:31];
    integer i;

    // 初始化：x0寄存器始终为0
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'b0;
            end
        end else begin
            if (we && rd != 5'b0) begin  // x0寄存器不可写
                registers[rd] <= wdata;
            end
        end
    end

    // 读端口1（组合逻辑）
    always @(*) begin
        if (rs1 == 5'b0)
            rdata1 = 32'b0;
        else
            rdata1 = registers[rs1];
    end

    // 读端口2（组合逻辑）
    always @(*) begin
        if (rs2 == 5'b0)
            rdata2 = 32'b0;
        else
            rdata2 = registers[rs2];
    end

endmodule

