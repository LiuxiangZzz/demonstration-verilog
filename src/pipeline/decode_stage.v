// 译码阶段 (Instruction Decode Stage)
module decode_stage(
    input clk,
    input rst,
    // IF/ID流水线寄存器输入
    input [31:0] if_id_pc,
    input [31:0] if_id_instruction,
    // 写回数据
    input [4:0] mem_wb_rd,
    input [31:0] wb_data,
    input mem_wb_reg_write,
    // 冒险检测输入
    input id_ex_mem_read,
    input [4:0] id_ex_rd,
    input mem_stall,
    input ex_mem_branch_taken,
    input ex_mem_jump,
    // ID/EX流水线寄存器输出
    output id_ex_reg_write,
    output id_ex_mem_read,
    output id_ex_mem_write,
    output [1:0] id_ex_alu_src,
    output [1:0] id_ex_mem_to_reg,
    output id_ex_branch,
    output id_ex_jump,
    output [3:0] id_ex_alu_op,
    output [31:0] id_ex_pc,
    output [31:0] id_ex_rdata1,
    output [31:0] id_ex_rdata2,
    output [31:0] id_ex_imm,
    output [4:0] id_ex_rs1,
    output [4:0] id_ex_rs2,
    output [4:0] id_ex_rd,
    output [31:0] id_ex_instruction,
    // 冒险检测输出
    output id_stall,
    output id_flush
);

    // 指令译码
    wire [6:0] opcode;
    wire [4:0] rs1, rs2, rd;
    wire [2:0] funct3;
    wire [6:0] funct7;
    
    assign opcode = if_id_instruction[6:0];
    assign rs1 = if_id_instruction[19:15];
    assign rs2 = if_id_instruction[24:20];
    assign rd = if_id_instruction[11:7];
    assign funct3 = if_id_instruction[14:12];
    assign funct7 = if_id_instruction[31:25];
    
    // 立即数生成
    wire [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;
    assign imm_i = {{20{if_id_instruction[31]}}, if_id_instruction[31:20]};
    assign imm_s = {{20{if_id_instruction[31]}}, if_id_instruction[31:25], if_id_instruction[11:7]};
    assign imm_b = {{20{if_id_instruction[31]}}, if_id_instruction[7], if_id_instruction[30:25], 
                     if_id_instruction[11:8], 1'b0};
    assign imm_u = {if_id_instruction[31:12], 12'b0};
    assign imm_j = {{12{if_id_instruction[31]}}, if_id_instruction[19:12], 
                     if_id_instruction[20], if_id_instruction[30:21], 1'b0};
    
    // 立即数选择
    wire [31:0] imm;
    assign imm = (opcode == 7'b1100011) ? imm_b :  // BRANCH
                 (opcode == 7'b1101111) ? imm_j :  // JAL
                 (opcode == 7'b1100111) ? imm_i :  // JALR
                 (opcode == 7'b0100011) ? imm_s :  // STORE
                 imm_i;  // 默认I型立即数
    
    // 寄存器文件
    wire [31:0] rdata1, rdata2;
    regfile regfile_inst(
        .clk(clk),
        .rst(rst),
        .rs1(rs1),
        .rs2(rs2),
        .rd(mem_wb_rd),
        .wdata(wb_data),
        .we(mem_wb_reg_write),
        .rdata1(rdata1),
        .rdata2(rdata2)
    );
    
    // 控制单元
    wire reg_write;
    wire mem_read;
    wire mem_write;
    wire [1:0] alu_src;
    wire [1:0] mem_to_reg;
    wire branch;
    wire jump;
    wire [3:0] alu_op;
    
    control control_inst(
        .opcode(opcode),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .alu_src(alu_src),
        .mem_to_reg(mem_to_reg),
        .branch(branch),
        .jump(jump),
        .alu_op(alu_op)
    );
    
    // 冒险检测单元
    // 检测Load-Use数据冒险
    assign id_stall = (id_ex_mem_read && 
                       ((rs1 == id_ex_rd) || (rs2 == id_ex_rd)) &&
                       (id_ex_rd != 5'b0));
    
    assign id_flush = ex_mem_branch_taken || ex_mem_jump;
    
    // ID/EX流水线寄存器
    id_ex_reg id_ex_reg_inst(
        .clk(clk),
        .rst(rst),
        .stall(mem_stall),
        .flush(id_flush),
        .reg_write_in(reg_write),
        .mem_read_in(mem_read),
        .mem_write_in(mem_write),
        .alu_src_in(alu_src),
        .mem_to_reg_in(mem_to_reg),
        .branch_in(branch),
        .jump_in(jump),
        .alu_op_in(alu_op),
        .pc_in(if_id_pc),
        .rdata1_in(rdata1),
        .rdata2_in(rdata2),
        .imm_in(imm),
        .rs1_in(rs1),
        .rs2_in(rs2),
        .rd_in(rd),
        .instruction_in(if_id_instruction),
        .reg_write_out(id_ex_reg_write),
        .mem_read_out(id_ex_mem_read),
        .mem_write_out(id_ex_mem_write),
        .alu_src_out(id_ex_alu_src),
        .mem_to_reg_out(id_ex_mem_to_reg),
        .branch_out(id_ex_branch),
        .jump_out(id_ex_jump),
        .alu_op_out(id_ex_alu_op),
        .pc_out(id_ex_pc),
        .rdata1_out(id_ex_rdata1),
        .rdata2_out(id_ex_rdata2),
        .imm_out(id_ex_imm),
        .rs1_out(id_ex_rs1),
        .rs2_out(id_ex_rs2),
        .rd_out(id_ex_rd),
        .instruction_out(id_ex_instruction)
    );

endmodule
