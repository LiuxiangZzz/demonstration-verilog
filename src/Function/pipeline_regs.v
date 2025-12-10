// 流水线寄存器模块
// 包含IF/ID, ID/EX, EX/MEM, MEM/WB四个流水线寄存器

// IF/ID流水线寄存器
module if_id_reg(
    input clk,
    input rst,
    input stall,
    input flush,
    input [31:0] pc_in,
    input [31:0] instruction_in,
    output reg [31:0] pc_out,
    output reg [31:0] instruction_out
);

    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            pc_out <= 32'b0;
            instruction_out <= 32'h00000013;  // NOP
        end else if (!stall) begin
            pc_out <= pc_in;
            instruction_out <= instruction_in;
        end
    end

endmodule

// ID/EX流水线寄存器
module id_ex_reg(
    input clk,
    input rst,
    input stall,
    input flush,
    // 控制信号
    input reg_write_in,
    input mem_read_in,
    input mem_write_in,
    input [1:0] alu_src_in,
    input [1:0] mem_to_reg_in,
    input branch_in,
    input jump_in,
    input [3:0] alu_op_in,
    // 数据信号
    input [31:0] pc_in,
    input [31:0] rdata1_in,
    input [31:0] rdata2_in,
    input [31:0] imm_in,
    input [4:0] rs1_in,
    input [4:0] rs2_in,
    input [4:0] rd_in,
    input [31:0] instruction_in,
    // 输出
    output reg reg_write_out,
    output reg mem_read_out,
    output reg mem_write_out,
    output reg [1:0] alu_src_out,
    output reg [1:0] mem_to_reg_out,
    output reg branch_out,
    output reg jump_out,
    output reg [3:0] alu_op_out,
    output reg [31:0] pc_out,
    output reg [31:0] rdata1_out,
    output reg [31:0] rdata2_out,
    output reg [31:0] imm_out,
    output reg [4:0] rs1_out,
    output reg [4:0] rs2_out,
    output reg [4:0] rd_out,
    output reg [31:0] instruction_out
);

    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            reg_write_out <= 1'b0;
            mem_read_out <= 1'b0;
            mem_write_out <= 1'b0;
            alu_src_out <= 2'b00;
            mem_to_reg_out <= 2'b00;
            branch_out <= 1'b0;
            jump_out <= 1'b0;
            alu_op_out <= 4'b0000;
            pc_out <= 32'b0;
            rdata1_out <= 32'b0;
            rdata2_out <= 32'b0;
            imm_out <= 32'b0;
            rs1_out <= 5'b0;
            rs2_out <= 5'b0;
            rd_out <= 5'b0;
            instruction_out <= 32'h00000013;  // NOP
        end else if (!stall) begin
            reg_write_out <= reg_write_in;
            mem_read_out <= mem_read_in;
            mem_write_out <= mem_write_in;
            alu_src_out <= alu_src_in;
            mem_to_reg_out <= mem_to_reg_in;
            branch_out <= branch_in;
            jump_out <= jump_in;
            alu_op_out <= alu_op_in;
            pc_out <= pc_in;
            rdata1_out <= rdata1_in;
            rdata2_out <= rdata2_in;
            imm_out <= imm_in;
            rs1_out <= rs1_in;
            rs2_out <= rs2_in;
            rd_out <= rd_in;
            instruction_out <= instruction_in;
        end
    end

endmodule

// EX/MEM流水线寄存器
module ex_mem_reg(
    input clk,
    input rst,
    input stall,
    // 控制信号
    input reg_write_in,
    input mem_read_in,
    input mem_write_in,
    input [1:0] mem_to_reg_in,
    input jump_in,
    // 数据信号
    input [31:0] alu_result_in,
    input [31:0] rdata2_in,
    input [4:0] rd_in,
    input [31:0] pc_plus4_in,
    input branch_taken_in,
    input [31:0] branch_target_in,
    input [31:0] jump_target_in,
    // 输出
    output reg reg_write_out,
    output reg mem_read_out,
    output reg mem_write_out,
    output reg [1:0] mem_to_reg_out,
    output reg jump_out,
    output reg [31:0] alu_result_out,
    output reg [31:0] rdata2_out,
    output reg [4:0] rd_out,
    output reg [31:0] pc_plus4_out,
    output reg branch_taken_out,
    output reg [31:0] branch_target_out,
    output reg [31:0] jump_target_out
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_write_out <= 1'b0;
            mem_read_out <= 1'b0;
            mem_write_out <= 1'b0;
            mem_to_reg_out <= 2'b00;
            jump_out <= 1'b0;
            alu_result_out <= 32'b0;
            rdata2_out <= 32'b0;
            rd_out <= 5'b0;
            pc_plus4_out <= 32'b0;
            branch_taken_out <= 1'b0;
            branch_target_out <= 32'b0;
            jump_target_out <= 32'b0;
        end else if (!stall) begin
            reg_write_out <= reg_write_in;
            mem_read_out <= mem_read_in;
            mem_write_out <= mem_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            jump_out <= jump_in;
            alu_result_out <= alu_result_in;
            rdata2_out <= rdata2_in;
            rd_out <= rd_in;
            pc_plus4_out <= pc_plus4_in;
            branch_taken_out <= branch_taken_in;
            branch_target_out <= branch_target_in;
            jump_target_out <= jump_target_in;
        end
    end

endmodule

// MEM/WB流水线寄存器
module mem_wb_reg(
    input clk,
    input rst,
    input stall,
    // 控制信号
    input reg_write_in,
    input [1:0] mem_to_reg_in,
    // 数据信号
    input [31:0] alu_result_in,
    input [31:0] mem_rdata_in,
    input [31:0] pc_plus4_in,
    input [4:0] rd_in,
    // 输出
    output reg reg_write_out,
    output reg [1:0] mem_to_reg_out,
    output reg [31:0] alu_result_out,
    output reg [31:0] mem_rdata_out,
    output reg [31:0] pc_plus4_out,
    output reg [4:0] rd_out
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_write_out <= 1'b0;
            mem_to_reg_out <= 2'b00;
            alu_result_out <= 32'b0;
            mem_rdata_out <= 32'b0;
            pc_plus4_out <= 32'b0;
            rd_out <= 5'b0;
        end else if (!stall) begin
            reg_write_out <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            alu_result_out <= alu_result_in;
            mem_rdata_out <= mem_rdata_in;
            pc_plus4_out <= pc_plus4_in;
            rd_out <= rd_in;
        end
    end

endmodule

