// 数据存储器模块（带多周期延迟）
module dmem(
    input clk,
    input rst,
    input [31:0] addr,
    input [31:0] wdata,
    input mem_read,
    input mem_write,
    output reg [31:0] rdata,
    output reg mem_ready  // 内存访问完成信号
);

    // 数据存储器：64KB (16K words)
    reg [31:0] mem [0:16383];
    
    // 内存访问状态机
    reg [2:0] state;
    reg [2:0] delay_counter;
    
    localparam IDLE = 3'b000;
    localparam READ_DELAY = 3'b001;
    localparam WRITE_DELAY = 3'b010;
    
    // 内存延迟周期数（可配置，这里设为3个周期）
    localparam MEM_DELAY = 3;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            delay_counter <= 3'b0;
            rdata <= 32'b0;
            mem_ready <= 1'b1;
        end else begin
            case (state)
                IDLE: begin
                    if (mem_read || mem_write) begin
                        state <= mem_read ? READ_DELAY : WRITE_DELAY;
                        delay_counter <= MEM_DELAY;
                        mem_ready <= 1'b0;
                    end else begin
                        mem_ready <= 1'b1;
                    end
                end
                
                READ_DELAY: begin
                    if (delay_counter > 1) begin
                        delay_counter <= delay_counter - 1;
                    end else begin
                        // 读取完成
                        if (addr[31:2] < 16384)
                            rdata <= mem[addr[31:2]];
                        else
                            rdata <= 32'b0;
                        state <= IDLE;
                        mem_ready <= 1'b1;
                        delay_counter <= 3'b0;
                    end
                end
                
                WRITE_DELAY: begin
                    if (delay_counter > 1) begin
                        delay_counter <= delay_counter - 1;
                    end else begin
                        // 写入完成
                        if (addr[31:2] < 16384)
                            mem[addr[31:2]] <= wdata;
                        state <= IDLE;
                        mem_ready <= 1'b1;
                        delay_counter <= 3'b0;
                    end
                end
                
                default: begin
                    state <= IDLE;
                    mem_ready <= 1'b1;
                end
            endcase
        end
    end

endmodule

