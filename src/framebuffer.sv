module framebuffer(
    input        clk,
    input        we,
    input  [9:0] waddr,
    input  [1:0] wdata,
    input  [9:0] raddr,
    output [1:0] rdata
);
    reg [1:0] tiles [0:767];  // 32 x 24 = 768 tiles

    integer i;
    initial begin
        for (i = 0; i < 768; i = i + 1)
            tiles[i] = 2'b00;
    end

    always @(posedge clk)
        if (we) tiles[waddr] <= wdata;

    assign rdata = tiles[raddr];

endmodule