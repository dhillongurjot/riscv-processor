module memory(
    input         clk,
    input         mem_read,
    input         mem_write,
    input  [31:0] address,
    input  [31:0] write_data,
    output reg [31:0] read_data
);
    reg [31:0] mem [0:2047];  // 2048 words of memory

    integer i;
    initial begin
        for (i = 0; i < 2048; i = i + 1)
            mem[i] = 32'd0;
    end

    // synchronous write
    always @(posedge clk) begin
        if (mem_write)
            mem[address[12:2]] <= write_data;
    end

    // combinational read
    always @(*) begin
        if (mem_read)
            read_data = mem[address[12:2]];
        else
            read_data = 32'd0;
    end

endmodule