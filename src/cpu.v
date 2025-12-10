// RISC-V 32位五级流水线CPU顶层模块
module cpu(
    input clk,
    input rst,
    output [31:0] pc_out
);

    // ========== IF阶段信号 ==========
    wire [31:0] pc;
    wire [31:0] pc_next;
    wire [31:0] pc_plus4;
    wire [31:0] instruction;
    wire pc_stall;
    wire if_flush;
    
    // ========== IF/ID流水线寄存器 ==========
    wire [31:0] if_id_pc;
    wire [31:0] if_id_instruction;
    
    // ========== ID阶段信号 ==========
    wire [6:0] opcode;
    wire [4:0] rs1, rs2, rd;
    wire [2:0] funct3;
    wire [6:0] funct7;
    wire [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;
    wire [31:0] rdata1, rdata2;
    wire [31:0] imm_selected;
    
    // 控制信号
    wire reg_write;
    wire mem_read;
    wire mem_write;
    wire [1:0] alu_src;
    wire [1:0] mem_to_reg;
    wire branch;
    wire jump;
    wire [3:0] alu_op;
    
    // 冒险检测
    wire id_stall;
    wire id_flush;
    
    // ========== ID/EX流水线寄存器 ==========
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
    
    // ========== EX阶段信号 ==========
    wire [31:0] alu_a, alu_b;
    wire [31:0] alu_result;
    wire alu_zero;
    wire [3:0] alu_control;
    wire branch_taken;
    wire [31:0] ex_branch_target;
    wire [31:0] ex_jump_target;
    wire [31:0] ex_pc_plus4;
    
    // 数据前推
    wire [1:0] forward_a, forward_b;
    wire [31:0] forward_mem_wb_data;
    wire [31:0] forward_ex_mem_data;
    
    // ========== EX/MEM流水线寄存器 ==========
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
    
    // ========== MEM阶段信号 ==========
    wire [31:0] mem_rdata;
    wire mem_ready;
    wire mem_stall;
    wire [31:0] mem_pc_plus4;
    
    // ========== MEM/WB流水线寄存器 ==========
    wire mem_wb_reg_write;
    wire [1:0] mem_wb_mem_to_reg;
    wire [31:0] mem_wb_alu_result;
    wire [31:0] mem_wb_mem_rdata;
    wire [31:0] mem_wb_pc_plus4;
    wire [4:0] mem_wb_rd;
    
    // ========== WB阶段信号 ==========
    wire [31:0] wb_data;
    
    // ========== 模块实例化 ==========
    
    // PC寄存器
    reg [31:0] pc_reg;
    always @(posedge clk or posedge rst) begin
        if (rst)
            pc_reg <= 32'h00000000;
        else if (!pc_stall)
            pc_reg <= pc_next;
    end
    assign pc = pc_reg;
    assign pc_out = pc;
    assign pc_plus4 = pc + 4;
    
    // PC选择逻辑
    // 分支和跳转在EX阶段判断，但需要传递目标地址
    wire [31:0] ex_branch_target;
    wire [31:0] ex_jump_target;
    
    // PC选择：优先分支，然后跳转，最后顺序执行
    // 注意：这里使用EX/MEM阶段的信号，因为分支判断在EX阶段完成
    assign pc_next = (ex_mem_branch_taken) ? ex_mem_branch_target :
                     (ex_mem_jump) ? ex_mem_jump_target : pc_plus4;
    
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
    
    // 指令译码
    assign opcode = if_id_instruction[6:0];
    assign rs1 = if_id_instruction[19:15];
    assign rs2 = if_id_instruction[24:20];
    assign rd = if_id_instruction[11:7];
    assign funct3 = if_id_instruction[14:12];
    assign funct7 = if_id_instruction[31:25];
    
    // 立即数生成
    assign imm_i = {{20{if_id_instruction[31]}}, if_id_instruction[31:20]};
    assign imm_s = {{20{if_id_instruction[31]}}, if_id_instruction[31:25], if_id_instruction[11:7]};
    assign imm_b = {{20{if_id_instruction[31]}}, if_id_instruction[7], if_id_instruction[30:25], 
                     if_id_instruction[11:8], 1'b0};
    assign imm_u = {if_id_instruction[31:12], 12'b0};
    assign imm_j = {{12{if_id_instruction[31]}}, if_id_instruction[19:12], 
                     if_id_instruction[20], if_id_instruction[30:21], 1'b0};
    
    // 立即数选择
    assign imm_selected = (opcode == 7'b1100011) ? imm_b :  // BRANCH
                          (opcode == 7'b1101111) ? imm_j :  // JAL
                          (opcode == 7'b1100111) ? imm_i :  // JALR
                          (opcode == 7'b0100011) ? imm_s :  // STORE
                          imm_i;  // 默认I型立即数
    
    // 寄存器文件
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
    
    // ALU控制信号生成（根据funct3和funct7）
    // 对于R型指令，需要检查funct3和funct7
    wire [2:0] funct3_ex = id_ex_instruction[14:12];
    wire [6:0] funct7_ex = id_ex_instruction[31:25];
    
    assign alu_control = (id_ex_alu_op == 4'b0000) ? 4'b0000 :  // ADD (I型或默认)
                         (id_ex_alu_op == 4'b0001) ? 
                             ((funct7_ex == 7'b0100000 && funct3_ex == 3'b000) ? 4'b0001 : 4'b0000) :  // SUB or ADD
                         4'b0000;
    
    // 冒险检测单元（简化版）
    // 检测Load-Use数据冒险（需要检查EX/MEM阶段的load指令）
    assign id_stall = (id_ex_mem_read && 
                       ((rs1 == id_ex_rd) || (rs2 == id_ex_rd)) &&
                       (id_ex_rd != 5'b0));
    
    assign if_flush = ex_mem_branch_taken || ex_mem_jump;
    
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
        .imm_in(imm_selected),
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
    
    // 数据前推单元（简化版）
    assign forward_a = ((id_ex_rs1 != 5'b0) && (id_ex_rs1 == mem_wb_rd) && mem_wb_reg_write) ? 2'b01 :
                       ((id_ex_rs1 != 5'b0) && (id_ex_rs1 == ex_mem_rd) && ex_mem_reg_write) ? 2'b10 : 2'b00;
    
    assign forward_b = ((id_ex_rs2 != 5'b0) && (id_ex_rs2 == mem_wb_rd) && mem_wb_reg_write) ? 2'b01 :
                       ((id_ex_rs2 != 5'b0) && (id_ex_rs2 == ex_mem_rd) && ex_mem_reg_write) ? 2'b10 : 2'b00;
    
    assign forward_mem_wb_data = (mem_wb_mem_to_reg == 2'b00) ? mem_wb_alu_result :
                                  (mem_wb_mem_to_reg == 2'b01) ? mem_wb_mem_rdata :
                                  mem_wb_pc_plus4;
    
    assign forward_ex_mem_data = ex_mem_alu_result;
    
    // ALU输入选择
    assign alu_a = (forward_a == 2'b01) ? forward_mem_wb_data :
                   (forward_a == 2'b10) ? forward_ex_mem_data :
                   id_ex_rdata1;
    
    assign alu_b = (id_ex_alu_src == 2'b01) ? id_ex_imm :
                   (forward_b == 2'b01) ? forward_mem_wb_data :
                   (forward_b == 2'b10) ? forward_ex_mem_data :
                   id_ex_rdata2;
    
    // ALU
    alu alu_inst(
        .a(alu_a),
        .b(alu_b),
        .alu_control(alu_control),
        .result(alu_result),
        .zero(alu_zero)
    );
    
    // 分支判断（在EX阶段）
    // 对于BEQ，需要比较两个寄存器值
    wire [31:0] branch_rs1, branch_rs2;
    assign branch_rs1 = (forward_a == 2'b01) ? forward_mem_wb_data :
                        (forward_a == 2'b10) ? forward_ex_mem_data :
                        id_ex_rdata1;
    assign branch_rs2 = (forward_b == 2'b01) ? forward_mem_wb_data :
                        (forward_b == 2'b10) ? forward_ex_mem_data :
                        id_ex_rdata2;
    
    assign branch_taken = id_ex_branch && (branch_rs1 == branch_rs2);
    assign ex_branch_target = id_ex_pc + id_ex_imm;
    
    // 跳转目标（在EX阶段计算）
    assign ex_jump_target = (id_ex_jump && (id_ex_instruction[6:0] == 7'b1100111)) ? 
                            (branch_rs1 + id_ex_imm) :  // JALR
                            (id_ex_pc + id_ex_imm);  // JAL
    
    assign ex_pc_plus4 = id_ex_pc;
    
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
        .alu_result_in(alu_result),
        .rdata2_in((forward_b == 2'b01) ? forward_mem_wb_data :
                   (forward_b == 2'b10) ? forward_ex_mem_data :
                   id_ex_rdata2),
        .rd_in(id_ex_rd),
        .pc_plus4_in(ex_pc_plus4),
        .branch_taken_in(branch_taken),
        .branch_target_in(ex_branch_target),
        .jump_target_in(ex_jump_target),
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
    
    // 数据存储器
    dmem dmem_inst(
        .clk(clk),
        .rst(rst),
        .addr(ex_mem_alu_result),
        .wdata(ex_mem_rdata2),
        .mem_read(ex_mem_mem_read),
        .mem_write(ex_mem_mem_write),
        .rdata(mem_rdata),
        .mem_ready(mem_ready)
    );
    
    // 内存stall控制
    assign mem_stall = (ex_mem_mem_read || ex_mem_mem_write) && !mem_ready;
    assign pc_stall = mem_stall || id_stall;
    assign id_flush = if_flush;
    
    assign mem_pc_plus4 = ex_mem_pc_plus4;
    
    // MEM/WB流水线寄存器
    mem_wb_reg mem_wb_reg_inst(
        .clk(clk),
        .rst(rst),
        .stall(1'b0),
        .reg_write_in(ex_mem_reg_write),
        .mem_to_reg_in(ex_mem_mem_to_reg),
        .alu_result_in(ex_mem_alu_result),
        .mem_rdata_in(mem_rdata),
        .pc_plus4_in(mem_pc_plus4),
        .rd_in(ex_mem_rd),
        .reg_write_out(mem_wb_reg_write),
        .mem_to_reg_out(mem_wb_mem_to_reg),
        .alu_result_out(mem_wb_alu_result),
        .mem_rdata_out(mem_wb_mem_rdata),
        .pc_plus4_out(mem_wb_pc_plus4),
        .rd_out(mem_wb_rd)
    );
    
    // 写回数据选择
    assign wb_data = (mem_wb_mem_to_reg == 2'b00) ? mem_wb_alu_result :
                     (mem_wb_mem_to_reg == 2'b01) ? mem_wb_mem_rdata :
                     mem_wb_pc_plus4;

endmodule

