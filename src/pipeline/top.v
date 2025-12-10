// RISC-V 32位五级流水线CPU顶层模块
module top(
    input clk,
    input rst,
    output [31:0] pc_out
);

    // ========== 阶段间信号 ==========
    
    // IF阶段输出
    wire [31:0] pc;
    wire [31:0] pc_plus4;
    wire [31:0] instruction;
    wire [31:0] if_id_pc;
    wire [31:0] if_id_instruction;
    
    // Decode阶段输出
    wire id_ex_reg_write;
    wire id_ex_mem_read;
    wire id_ex_mem_write;
    wire [1:0] id_ex_alu_src;
    wire [1:0] id_ex_mem_to_reg;
    wire id_ex_branch;
    wire id_ex_jump;
    wire [3:0] id_ex_alu_op;
    wire [31:0] id_ex_pc;
    wire [31:0] id_ex_rdata1;
    wire [31:0] id_ex_rdata2;
    wire [31:0] id_ex_imm;
    wire [4:0] id_ex_rs1;
    wire [4:0] id_ex_rs2;
    wire [4:0] id_ex_rd;
    wire [31:0] id_ex_instruction;
    
    // Execute阶段输出
    wire ex_mem_reg_write;
    wire ex_mem_mem_read;
    wire ex_mem_mem_write;
    wire [1:0] ex_mem_mem_to_reg;
    wire ex_mem_jump;
    wire [31:0] ex_mem_alu_result;
    wire [31:0] ex_mem_rdata2;
    wire [4:0] ex_mem_rd;
    wire [31:0] ex_mem_pc_plus4;
    wire ex_mem_branch_taken;
    wire [31:0] ex_mem_branch_target;
    wire [31:0] ex_mem_jump_target;
    
    // Mem阶段输出
    wire mem_wb_reg_write;
    wire [1:0] mem_wb_mem_to_reg;
    wire [31:0] mem_wb_alu_result;
    wire [31:0] mem_wb_mem_rdata;
    wire [31:0] mem_wb_pc_plus4;
    wire [4:0] mem_wb_rd;
    wire mem_stall;
    
    // WB阶段输出
    wire [31:0] wb_data;
    wire [4:0] wb_rd;
    wire wb_reg_write;
    
    // 控制信号
    wire pc_stall;
    wire if_flush;
    wire id_stall;
    wire id_flush;
    wire [31:0] pc_next;
    
    // PC选择逻辑
    assign pc_next = (ex_mem_branch_taken) ? ex_mem_branch_target :
                     (ex_mem_jump) ? ex_mem_jump_target : pc_plus4;
    
    // 流水线控制
    assign pc_stall = mem_stall || id_stall;
    assign if_flush = ex_mem_branch_taken || ex_mem_jump;
    
    // ========== 阶段模块实例化 ==========
    
    // IF阶段
    if_stage if_stage_inst(
        .clk(clk),
        .rst(rst),
        .pc_stall(pc_stall),
        .if_flush(if_flush),
        .pc_next(pc_next),
        .pc(pc),
        .pc_plus4(pc_plus4),
        .instruction(instruction),
        .if_id_pc(if_id_pc),
        .if_id_instruction(if_id_instruction),
        .id_stall(id_stall),
        .mem_stall(mem_stall)
    );
    
    // Decode阶段
    decode_stage decode_stage_inst(
        .clk(clk),
        .rst(rst),
        .if_id_pc(if_id_pc),
        .if_id_instruction(if_id_instruction),
        .mem_wb_rd(wb_rd),
        .wb_data(wb_data),
        .mem_wb_reg_write(wb_reg_write),
        .id_ex_mem_read(id_ex_mem_read),
        .id_ex_rd(id_ex_rd),
        .mem_stall(mem_stall),
        .ex_mem_branch_taken(ex_mem_branch_taken),
        .ex_mem_jump(ex_mem_jump),
        .id_ex_reg_write(id_ex_reg_write),
        .id_ex_mem_read(id_ex_mem_read),
        .id_ex_mem_write(id_ex_mem_write),
        .id_ex_alu_src(id_ex_alu_src),
        .id_ex_mem_to_reg(id_ex_mem_to_reg),
        .id_ex_branch(id_ex_branch),
        .id_ex_jump(id_ex_jump),
        .id_ex_alu_op(id_ex_alu_op),
        .id_ex_pc(id_ex_pc),
        .id_ex_rdata1(id_ex_rdata1),
        .id_ex_rdata2(id_ex_rdata2),
        .id_ex_imm(id_ex_imm),
        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),
        .id_ex_rd(id_ex_rd),
        .id_ex_instruction(id_ex_instruction),
        .id_stall(id_stall),
        .id_flush(id_flush)
    );
    
    // Execute阶段
    ex_stage execute_stage_inst(
        .clk(clk),
        .rst(rst),
        .id_ex_reg_write(id_ex_reg_write),
        .id_ex_mem_read(id_ex_mem_read),
        .id_ex_mem_write(id_ex_mem_write),
        .id_ex_alu_src(id_ex_alu_src),
        .id_ex_mem_to_reg(id_ex_mem_to_reg),
        .id_ex_branch(id_ex_branch),
        .id_ex_jump(id_ex_jump),
        .id_ex_alu_op(id_ex_alu_op),
        .id_ex_pc(id_ex_pc),
        .id_ex_rdata1(id_ex_rdata1),
        .id_ex_rdata2(id_ex_rdata2),
        .id_ex_imm(id_ex_imm),
        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),
        .id_ex_rd(id_ex_rd),
        .id_ex_instruction(id_ex_instruction),
        .prev_ex_mem_alu_result(ex_mem_alu_result),
        .prev_ex_mem_reg_write(ex_mem_reg_write),
        .prev_ex_mem_rd(ex_mem_rd),
        .mem_wb_alu_result(mem_wb_alu_result),
        .mem_wb_mem_rdata(mem_wb_mem_rdata),
        .mem_wb_pc_plus4(mem_wb_pc_plus4),
        .mem_wb_mem_to_reg(mem_wb_mem_to_reg),
        .mem_wb_reg_write(mem_wb_reg_write),
        .mem_wb_rd(mem_wb_rd),
        .mem_stall(mem_stall),
        .ex_mem_reg_write(ex_mem_reg_write),
        .ex_mem_mem_read(ex_mem_mem_read),
        .ex_mem_mem_write(ex_mem_mem_write),
        .ex_mem_mem_to_reg(ex_mem_mem_to_reg),
        .ex_mem_jump(ex_mem_jump),
        .ex_mem_alu_result(ex_mem_alu_result),
        .ex_mem_rdata2(ex_mem_rdata2),
        .ex_mem_rd(ex_mem_rd),
        .ex_mem_pc_plus4(ex_mem_pc_plus4),
        .ex_mem_branch_taken(ex_mem_branch_taken),
        .ex_mem_branch_target(ex_mem_branch_target),
        .ex_mem_jump_target(ex_mem_jump_target)
    );
    
    // Mem阶段
    mem_stage mem_stage_inst(
        .clk(clk),
        .rst(rst),
        .ex_mem_reg_write(ex_mem_reg_write),
        .ex_mem_mem_read(ex_mem_mem_read),
        .ex_mem_mem_write(ex_mem_mem_write),
        .ex_mem_mem_to_reg(ex_mem_mem_to_reg),
        .ex_mem_jump(ex_mem_jump),
        .ex_mem_alu_result(ex_mem_alu_result),
        .ex_mem_rdata2(ex_mem_rdata2),
        .ex_mem_rd(ex_mem_rd),
        .ex_mem_pc_plus4(ex_mem_pc_plus4),
        .ex_mem_branch_taken(ex_mem_branch_taken),
        .ex_mem_branch_target(ex_mem_branch_target),
        .ex_mem_jump_target(ex_mem_jump_target),
        .mem_stall(mem_stall),
        .mem_wb_reg_write(mem_wb_reg_write),
        .mem_wb_mem_to_reg(mem_wb_mem_to_reg),
        .mem_wb_alu_result(mem_wb_alu_result),
        .mem_wb_mem_rdata(mem_wb_mem_rdata),
        .mem_wb_pc_plus4(mem_wb_pc_plus4),
        .mem_wb_rd(mem_wb_rd)
    );
    
    // WB阶段
    wb_stage wb_stage_inst(
        .mem_wb_reg_write(mem_wb_reg_write),
        .mem_wb_mem_to_reg(mem_wb_mem_to_reg),
        .mem_wb_alu_result(mem_wb_alu_result),
        .mem_wb_mem_rdata(mem_wb_mem_rdata),
        .mem_wb_pc_plus4(mem_wb_pc_plus4),
        .mem_wb_rd(mem_wb_rd),
        .wb_data(wb_data),
        .wb_rd(wb_rd),
        .wb_reg_write(wb_reg_write)
    );
    
    // PC输出
    assign pc_out = pc;

endmodule
