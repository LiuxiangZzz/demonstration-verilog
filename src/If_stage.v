// IF阶段：取指阶段
module If_stage(
    input clk,
    input rst,
    input stall,              // 流水线暂停信号
    input flush,              // 流水线刷新信号
    input [31:0] pc_next,     // 下一个PC值（来自EX/MEM阶段的分支/跳转）
    output [31:0] pc,         // 当前PC值
    output [31:0] pc_plus4,   // PC+4
    output [31:0] instruction, // 取出的指令
    output [31:0] if_id_pc,   // 传递给ID阶段的PC+4
    output [31:0] if_id_instruction // 传递给ID阶段的指令
);

    // PC寄存器
    reg [31:0] pc_reg;
    always @(posedge clk or posedge rst) begin
        if (rst)
            pc_reg <= 32'h00000000;
        else if (!stall)
            pc_reg <= pc_next;
    end
    
    assign pc = pc_reg;
    assign pc_plus4 = pc + 4;
    
    // 指令存储器
    imem imem_inst(
        .addr(pc),
        .instruction(instruction)
    );
    
    // IF/ID流水线寄存器
    if_id_reg if_id_reg_inst(
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .flush(flush),
        .pc_in(pc_plus4),
        .instruction_in(instruction),
        .pc_out(if_id_pc),
        .instruction_out(if_id_instruction)
    );

endmodule

