module registers_tb;
    reg clk, we;
    reg [4:0] rs1, rs2, rd;
    reg [31:0] wd;
    wire [31:0] rd1, rd2;

    registers uut(.clk(clk), .rs1(rs1), .rs2(rs2),
                  .rd(rd), .wd(wd), .we(we),
                  .rd1(rd1), .rd2(rd2));

    always #5 clk = ~clk;  // clock toggles every 5 time units

    initial begin
        $dumpfile("registers.vcd");
        $dumpvars(0, registers_tb);
        clk = 0; we = 0;

        // write 42 into register 1
        rd = 5'd1; wd = 32'd42; we = 1; @(posedge clk); #1;
        $display("Wrote 42 to reg 1");

        // write 100 into register 2
        rd = 5'd2; wd = 32'd100; we = 1; @(posedge clk); #1;
        $display("Wrote 100 to reg 2");

        // read both back simultaneously
        we = 0; rs1 = 5'd1; rs2 = 5'd2; #10;
        $display("Read reg1 = %0d (expect 42)", rd1);
        $display("Read reg2 = %0d (expect 100)", rd2);

        // try writing to register 0 — should stay 0
        rd = 5'd0; wd = 32'd999; we = 1; @(posedge clk); #1;
        we = 0; rs1 = 5'd0; #10;
        $display("Read reg0 = %0d (expect 0)", rd1);

        $finish;
    end
endmodule