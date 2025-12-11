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
    
    // 初始化：从hello.hex加载整块镜像（代码+常量）
    integer j;
    reg [31:0] temp_mem [0:16383];
    initial begin
        // 先初始化为0
        for (j = 0; j < 16384; j = j + 1) begin
            mem[j] = 32'b0;
            temp_mem[j] = 32'b0;
        end
        
        // 尝试从hex文件加载整块数据（地址从0开始）
        // 注意：从test目录运行，所以路径是相对于test目录的
        $readmemh("hello.hex", temp_mem);
        if (temp_mem[0] == 32'h00000013 || temp_mem[0] == 32'h00000000) begin
            $readmemh("../test/hello.hex", temp_mem);
            if (temp_mem[0] == 32'h00000013 || temp_mem[0] == 32'h00000000) begin
                $readmemh("../test/build/hello.hex", temp_mem);
                if (temp_mem[0] == 32'h00000013 || temp_mem[0] == 32'h00000000) begin
                    $readmemh("test/hello.hex", temp_mem);
                end
            end
        end
        
        // 将加载的数据整体拷贝到数据存储器，确保.rodata等常量可访问
        for (j = 0; j < 16384; j = j + 1) begin
            mem[j] = temp_mem[j];
        end
        $display("dmem: init mem[0x1D..0x1F] = %h %h %h", mem[29], mem[30], mem[31]);
    end
    
    // 内存访问状态机
    reg [2:0] state;
    reg [2:0] delay_counter;
    reg [31:0] addr_reg;
    reg [31:0] wdata_reg;
    
    localparam IDLE = 3'b000;
    localparam READ_DELAY = 3'b001;
    localparam WRITE_DELAY = 3'b010;
    
    // 内存延迟周期数（可配置，这里设为1个周期，减少stall）
    localparam MEM_DELAY = 1;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            delay_counter <= 3'b0;
            rdata <= 32'b0;
            mem_ready <= 1'b1;
            addr_reg <= 32'b0;
            wdata_reg <= 32'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (mem_read || mem_write) begin
                        // 锁存当前的地址和写数据，避免下一拍被覆盖
                        addr_reg <= addr;
                        wdata_reg <= wdata;
                        // （可选）调试：显示内存写请求
                        // if (mem_write) begin
                        //     $display("dmem IDLE: Write request addr=%h, wdata=%h", addr, wdata);
                        // end
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
                        if (addr_reg[31:2] < 16384)
                            rdata <= mem[addr_reg[31:2]];
                        else
                            rdata <= 32'b0;
                        // 调试：显示关键地址的读取
                        if (addr_reg == 32'h7FE8 || addr_reg == 32'h7FE4 || addr_reg == 32'h7FEC) begin
                            $display("dmem: Read addr=%h, rdata=%h", addr_reg, (addr_reg[31:2] < 16384) ? mem[addr_reg[31:2]] : 32'b0);
                        end
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
                        if (addr_reg[31:2] < 16384)
                            mem[addr_reg[31:2]] <= wdata_reg;
                        
                        // 内存映射I/O：检测对输出地址的写入（0x10000000）
                        if (addr_reg == 32'h10000000) begin
                            // 将写入的数据作为字符打印到终端
                            if (wdata_reg[7:0] == 8'h0A || wdata_reg[7:0] == 8'h0D) begin
                                // 换行符
                                $display("");
                            end else if (wdata_reg[7:0] >= 8'h20 && wdata_reg[7:0] <= 8'h7E) begin
                                // 可打印ASCII字符（0x20-0x7E）
                                $write("%c", wdata_reg[7:0]);
                            end else if (wdata_reg[7:0] == 8'h00) begin
                                // 空字符，不打印
                            end else begin
                                // 其他控制字符（显示为十六进制）
                                $write("[%02h]", wdata_reg[7:0]);
                            end
                        end else if (addr_reg == 32'h7FE8 || addr_reg == 32'h7FE4 || addr_reg == 32'h7FEC) begin
                            // 调试：显示栈操作（可选）
                            // $display("dmem: Write to stack addr=%h, wdata=%h", addr_reg, wdata_reg);
                        end
                        
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

