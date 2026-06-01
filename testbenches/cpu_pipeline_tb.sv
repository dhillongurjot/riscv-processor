module cpu_pipeline_tb;
    reg clk, reset;

    cpu_pipeline uut(.clk(clk), .reset(reset));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("cpu_pipeline.vcd");
        $dumpvars(0, cpu_pipeline_tb);

        // same program as before
        uut.imem[0] = 32'h00A00093; // ADDI x1, x0, 10
        uut.imem[1] = 32'h01400113; // ADDI x2, x0, 20
        uut.imem[2] = 32'h002081B3; // ADD  x3, x1, x2

        clk = 0; reset = 1; #10;
        reset = 0;

        // pipeline needs more cycles than single-cycle
        // instructions take 5 cycles to complete
        repeat(20) @(posedge clk);

        $display("reg1 = %0d (expect 10)",  uut.regfile.regs[1]);
        $display("reg2 = %0d (expect 20)",  uut.regfile.regs[2]);
        $display("reg3 = %0d (expect 30)",  uut.regfile.regs[3]);

        $finish;
    end
endmodule