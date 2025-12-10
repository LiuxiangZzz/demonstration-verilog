// 写回阶段 (Write Back Stage)
module wb_stage(
    // MEM/WB流水线寄存器输入
    input mem_wb_reg_write,
    input [1:0] mem_wb_mem_to_reg,
    input [31:0] mem_wb_alu_result,
    input [31:0] mem_wb_mem_rdata,
    input [31:0] mem_wb_pc_plus4,
    input [4:0] mem_wb_rd,
    // 写回输出
    output [31:0] wb_data,
    output [4:0] wb_rd,
    output wb_reg_write
);

    // 写回数据选择
    assign wb_data = (mem_wb_mem_to_reg == 2'b00) ? mem_wb_alu_result :
                     (mem_wb_mem_to_reg == 2'b01) ? mem_wb_mem_rdata :
                     mem_wb_pc_plus4;
    
    // 传递写回控制信号
    assign wb_rd = mem_wb_rd;
    assign wb_reg_write = mem_wb_reg_write;

endmodule

