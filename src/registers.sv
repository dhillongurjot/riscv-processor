module registers(
    input         clk,
    input  [4:0]  rs1,      // first register to read
    input  [4:0]  rs2,      // second register to read
    input  [4:0]  rd,       // register to write to
    input  [31:0] wd,       // data to write
    input         we,       // write enable
    output [31:0] rd1,      // first read result
    output [31:0] rd2       // second read result
);
    reg [31:0] regs [31:0];  // 32 registers, each 32 bits

    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1)
            regs[i] = 32'd0;
    end

    // synchronous write
    always @(posedge clk) begin
        if (we && rd != 5'd0)
            regs[rd] <= wd;
    end

    // combinational read
    assign rd1 = (rs1 == 5'd0) ? 32'd0 : regs[rs1];
    assign rd2 = (rs2 == 5'd0) ? 32'd0 : regs[rs2];

endmodule