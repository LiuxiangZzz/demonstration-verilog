// 取指阶段 (Instruction Fetch Stage)
module if_stage(
    input clk,
    input rst,
    input pc_stall,
    input if_flush,
    input [31:0] pc_next,
    output [31:0] pc,
    output [31:0] pc_plus4,
    output [31:0] instruction,
    // IF/ID流水线寄存器输出
    output [31:0] if_id_pc,
    output [31:0] if_id_instruction,
    // 流水线控制
    input id_stall,
    input mem_stall
);

    // PC寄存器
    reg [31:0] pc_reg;
    always @(posedge clk or posedge rst) begin
        if (rst)
            pc_reg <= 32'h00000000;
        else if (!pc_stall)
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
        .stall(id_stall || mem_stall),
        .flush(if_flush),
        .pc_in(pc_plus4),
        .instruction_in(instruction),
        .pc_out(if_id_pc),
        .instruction_out(if_id_instruction)
    );

endmodule

