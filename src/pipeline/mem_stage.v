// 访存阶段 (Memory Stage)
module mem_stage(
    input clk,
    input rst,
    // EX/MEM流水线寄存器输入
    input ex_mem_reg_write,
    input ex_mem_mem_read,
    input ex_mem_mem_write,
    input [1:0] ex_mem_mem_to_reg,
    input ex_mem_jump,
    input [31:0] ex_mem_alu_result,
    input [31:0] ex_mem_rdata2,
    input [4:0] ex_mem_rd,
    input [31:0] ex_mem_pc_plus4,
    input ex_mem_branch_taken,
    input [31:0] ex_mem_branch_target,
    input [31:0] ex_mem_jump_target,
    // 流水线控制
    output mem_stall,
    // MEM/WB流水线寄存器输出
    output mem_wb_reg_write,
    output [1:0] mem_wb_mem_to_reg,
    output [31:0] mem_wb_alu_result,
    output [31:0] mem_wb_mem_rdata,
    output [31:0] mem_wb_pc_plus4,
    output [4:0] mem_wb_rd
);

    // 数据存储器
    wire [31:0] mem_rdata;
    wire mem_ready;
    
    // 调试：显示mem_write信号（已禁用，让输出更清晰）
    // always @(posedge clk) begin
    //     if (ex_mem_mem_write) begin
    //         $display("mem_stage: mem_write addr=%h wdata=%h mem_write=%b", ex_mem_alu_result, ex_mem_rdata2, ex_mem_mem_write);
    //     end
    // end
    
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
    
    // MEM/WB流水线寄存器
    mem_wb_reg mem_wb_reg_inst(
        .clk(clk),
        .rst(rst),
        .stall(1'b0),
        .reg_write_in(ex_mem_reg_write),
        .mem_to_reg_in(ex_mem_mem_to_reg),
        .alu_result_in(ex_mem_alu_result),
        .mem_rdata_in(mem_rdata),
        .pc_plus4_in(ex_mem_pc_plus4),
        .rd_in(ex_mem_rd),
        .reg_write_out(mem_wb_reg_write),
        .mem_to_reg_out(mem_wb_mem_to_reg),
        .alu_result_out(mem_wb_alu_result),
        .mem_rdata_out(mem_wb_mem_rdata),
        .pc_plus4_out(mem_wb_pc_plus4),
        .rd_out(mem_wb_rd)
    );

endmodule

