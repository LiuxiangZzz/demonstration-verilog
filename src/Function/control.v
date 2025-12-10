// 控制单元模块
module control(
    input [6:0] opcode,
    output reg reg_write,
    output reg mem_read,
    output reg mem_write,
    output reg [1:0] alu_src,
    output reg [1:0] mem_to_reg,
    output reg branch,
    output reg jump,
    output reg [3:0] alu_op
);

    // RISC-V操作码定义
    localparam OP_LUI   = 7'b0110111;  // LUI
    localparam OP_AUIPC = 7'b0010111;  // AUIPC
    localparam OP_JAL   = 7'b1101111;  // JAL
    localparam OP_JALR  = 7'b1100111;  // JALR
    localparam OP_BRANCH = 7'b1100011; // BEQ, BNE, etc.
    localparam OP_LOAD  = 7'b0000011;  // LW, LH, LB
    localparam OP_STORE = 7'b0100011;  // SW, SH, SB
    localparam OP_OP_IMM = 7'b0010011; // ADDI, SLTI, etc.
    localparam OP_OP    = 7'b0110011;  // ADD, SUB, etc.

    always @(*) begin
        // 默认值
        reg_write = 1'b0;
        mem_read = 1'b0;
        mem_write = 1'b0;
        alu_src = 2'b00;
        mem_to_reg = 2'b00;
        branch = 1'b0;
        jump = 1'b0;
        alu_op = 4'b0000;

        case (opcode)
            OP_OP_IMM: begin  // ADDI等立即数指令
                reg_write = 1'b1;
                alu_src = 2'b01;  // 使用立即数
                mem_to_reg = 2'b00; // ALU结果写回
                alu_op = 4'b0000;  // ADD操作
            end

            OP_OP: begin  // ADD, SUB等R型指令
                reg_write = 1'b1;
                alu_src = 2'b00;  // 使用寄存器
                mem_to_reg = 2'b00; // ALU结果写回
                alu_op = 4'b0001;  // 根据funct3进一步判断
            end

            OP_LOAD: begin  // LW
                reg_write = 1'b1;
                mem_read = 1'b1;
                alu_src = 2'b01;  // 使用立即数（地址偏移）
                mem_to_reg = 2'b01; // 内存数据写回
                alu_op = 4'b0000;  // ADD操作（计算地址）
            end

            OP_STORE: begin  // SW
                mem_write = 1'b1;
                alu_src = 2'b01;  // 使用立即数（地址偏移）
                alu_op = 4'b0000;  // ADD操作（计算地址）
            end

            OP_BRANCH: begin  // BEQ
                branch = 1'b1;
                alu_src = 2'b00;  // 使用寄存器
                alu_op = 4'b0001;  // SUB操作（比较）
            end

            OP_JAL: begin  // JAL
                reg_write = 1'b1;
                jump = 1'b1;
                mem_to_reg = 2'b10; // PC+4写回
            end

            OP_JALR: begin  // JALR
                reg_write = 1'b1;
                jump = 1'b1;
                alu_src = 2'b01;  // 使用立即数
                mem_to_reg = 2'b10; // PC+4写回
                alu_op = 4'b0000;  // ADD操作
            end

            OP_LUI: begin  // LUI
                reg_write = 1'b1;
                alu_src = 2'b01;  // 使用立即数
                mem_to_reg = 2'b00; // ALU结果写回（立即数左移12位）
                alu_op = 4'b0010;  // LUI操作（立即数直接作为结果，在立即数生成中处理）
            end

            default: begin
                // 保持默认值
            end
        endcase
    end

endmodule

