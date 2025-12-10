// 执行阶段 (Execute Stage)
module ex_stage(
    input clk,
    input rst,
    // ID/EX流水线寄存器输入
    input id_ex_reg_write,
    input id_ex_mem_read,
    input id_ex_mem_write,
    input [1:0] id_ex_alu_src,
    input [1:0] id_ex_mem_to_reg,
    input id_ex_branch,
    input id_ex_jump,
    input [3:0] id_ex_alu_op,
    input [31:0] id_ex_pc,
    input [31:0] id_ex_rdata1,
    input [31:0] id_ex_rdata2,
    input [31:0] id_ex_imm,
    input [4:0] id_ex_rs1,
    input [4:0] id_ex_rs2,
    input [4:0] id_ex_rd,
    input [31:0] id_ex_instruction,
    // 数据前推输入（来自上一周期的EX/MEM和MEM/WB阶段）
    input [31:0] prev_ex_mem_alu_result,
    input prev_ex_mem_reg_write,
    input [4:0] prev_ex_mem_rd,
    input [31:0] mem_wb_alu_result,
    input [31:0] mem_wb_mem_rdata,
    input [31:0] mem_wb_pc_plus4,
    input [1:0] mem_wb_mem_to_reg,
    input mem_wb_reg_write,
    input [4:0] mem_wb_rd,
    // 流水线控制
    input mem_stall,
    // EX/MEM流水线寄存器输出
    output ex_mem_reg_write,
    output ex_mem_mem_read,
    output ex_mem_mem_write,
    output [1:0] ex_mem_mem_to_reg,
    output ex_mem_jump,
    output [31:0] ex_mem_alu_result,
    output [31:0] ex_mem_rdata2,
    output [4:0] ex_mem_rd,
    output [31:0] ex_mem_pc_plus4,
    output ex_mem_branch_taken,
    output [31:0] ex_mem_branch_target,
    output [31:0] ex_mem_jump_target
);

    // ALU控制信号生成
    wire [2:0] funct3 = id_ex_instruction[14:12];
    wire [6:0] funct7 = id_ex_instruction[31:25];
    wire [3:0] alu_control;
    
    assign alu_control = (id_ex_alu_op == 4'b0000) ? 4'b0000 :  // ADD (I型或默认)
                         (id_ex_alu_op == 4'b0001) ? 
                             ((funct7 == 7'b0100000 && funct3 == 3'b000) ? 4'b0001 : 4'b0000) :  // SUB or ADD
                         4'b0000;
    
    // 数据前推单元
    wire [1:0] forward_a, forward_b;
    wire [31:0] forward_mem_wb_data;
    wire [31:0] forward_ex_mem_data;
    
    // 前推优先使用上一周期 EX/MEM，其次才是 MEM/WB，避免刚加载的基址被更旧的值覆盖
    assign forward_a = ((id_ex_rs1 != 5'b0) && (id_ex_rs1 == prev_ex_mem_rd) && prev_ex_mem_reg_write) ? 2'b10 :
                       ((id_ex_rs1 != 5'b0) && (id_ex_rs1 == mem_wb_rd) && mem_wb_reg_write) ? 2'b01 : 2'b00;
    
    assign forward_b = ((id_ex_rs2 != 5'b0) && (id_ex_rs2 == prev_ex_mem_rd) && prev_ex_mem_reg_write) ? 2'b10 :
                       ((id_ex_rs2 != 5'b0) && (id_ex_rs2 == mem_wb_rd) && mem_wb_reg_write) ? 2'b01 : 2'b00;
    
    assign forward_mem_wb_data = (mem_wb_mem_to_reg == 2'b00) ? mem_wb_alu_result :
                                  (mem_wb_mem_to_reg == 2'b01) ? mem_wb_mem_rdata :
                                  mem_wb_pc_plus4;
    
    assign forward_ex_mem_data = prev_ex_mem_alu_result;
    
    // ALU输入选择
    wire [31:0] alu_a, alu_b;
    assign alu_a = (forward_a == 2'b01) ? forward_mem_wb_data :
                   (forward_a == 2'b10) ? forward_ex_mem_data :
                   id_ex_rdata1;
    
    assign alu_b = (id_ex_alu_src == 2'b01) ? id_ex_imm :
                   (forward_b == 2'b01) ? forward_mem_wb_data :
                   (forward_b == 2'b10) ? forward_ex_mem_data :
                   id_ex_rdata2;
    
    // ALU
    wire [31:0] alu_result;
    wire alu_zero;
    alu alu_inst(
        .a(alu_a),
        .b(alu_b),
        .alu_control(alu_control),
        .result(alu_result),
        .zero(alu_zero)
    );
    
    // LUI指令特殊处理：直接使用立即数作为结果
    wire [31:0] final_alu_result;
    assign final_alu_result = (id_ex_alu_op == 4'b0010) ? id_ex_imm : alu_result;
    
    // 调试：显示sw指令的ALU计算和信号传递（已禁用，让输出更清晰）
    // always @(posedge clk) begin
    //     if (id_ex_mem_write && id_ex_instruction[6:0] == 7'b0100011) begin
    //         $display("ex_stage: SW rs1=%0d rs2=%0d fwdA=%b fwdB=%b alu_a=%h alu_b=%h alu_res=%h final=%h mem_write=%b", 
    //                  id_ex_rs1, id_ex_rs2, forward_a, forward_b, alu_a, alu_b, alu_result, final_alu_result, id_ex_mem_write);
    //         $display("ex_stage:   id_ex_mem_read=%b mem_wb_rd=%0d prev_ex_mem_rd=%0d fwd_mem_wb=%h fwd_ex_mem=%h",
    //                  id_ex_mem_read, mem_wb_rd, prev_ex_mem_rd, forward_mem_wb_data, forward_ex_mem_data);
    //     end
    // end
    
    // 分支判断
    wire [31:0] branch_rs1, branch_rs2;
    assign branch_rs1 = (forward_a == 2'b01) ? forward_mem_wb_data :
                        (forward_a == 2'b10) ? forward_ex_mem_data :
                        id_ex_rdata1;
    assign branch_rs2 = (forward_b == 2'b01) ? forward_mem_wb_data :
                        (forward_b == 2'b10) ? forward_ex_mem_data :
                        id_ex_rdata2;
    
    wire branch_taken;
    wire [31:0] branch_target;
    assign branch_taken = id_ex_branch && (branch_rs1 == branch_rs2);
    assign branch_target = id_ex_pc + id_ex_imm;
    
    // 跳转目标
    wire [31:0] jump_target;
    assign jump_target = (id_ex_jump && (id_ex_instruction[6:0] == 7'b1100111)) ? 
                         (branch_rs1 + id_ex_imm) :  // JALR
                         (id_ex_pc + id_ex_imm);  // JAL
    
    // PC+4 用于JAL/JALR写回
    wire [31:0] ex_pc_plus4 = id_ex_pc + 4;
    
    // 写回数据选择（用于SW指令）
    wire [31:0] ex_rdata2;
    assign ex_rdata2 = (forward_b == 2'b01) ? forward_mem_wb_data :
                       (forward_b == 2'b10) ? forward_ex_mem_data :
                       id_ex_rdata2;
    
    // EX/MEM流水线寄存器
    ex_mem_reg ex_mem_reg_inst(
        .clk(clk),
        .rst(rst),
        .stall(mem_stall),
        .reg_write_in(id_ex_reg_write),
        .mem_read_in(id_ex_mem_read),
        .mem_write_in(id_ex_mem_write),
        .mem_to_reg_in(id_ex_mem_to_reg),
        .jump_in(id_ex_jump),
        .alu_result_in(final_alu_result),
        .rdata2_in(ex_rdata2),
        .rd_in(id_ex_rd),
        .pc_plus4_in(ex_pc_plus4),
        .branch_taken_in(branch_taken),
        .branch_target_in(branch_target),
        .jump_target_in(jump_target),
        .reg_write_out(ex_mem_reg_write),
        .mem_read_out(ex_mem_mem_read),
        .mem_write_out(ex_mem_mem_write),
        .mem_to_reg_out(ex_mem_mem_to_reg),
        .jump_out(ex_mem_jump),
        .alu_result_out(ex_mem_alu_result),
        .rdata2_out(ex_mem_rdata2),
        .rd_out(ex_mem_rd),
        .pc_plus4_out(ex_mem_pc_plus4),
        .branch_taken_out(ex_mem_branch_taken),
        .branch_target_out(ex_mem_branch_target),
        .jump_target_out(ex_mem_jump_target)
    );

endmodule

