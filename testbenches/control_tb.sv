module control_tb;
    reg [6:0] opcode;
    wire reg_write, alu_src, mem_write, mem_read, mem_to_reg, branch;
    wire [1:0] alu_op;

    control uut(
        .opcode(opcode),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .mem_to_reg(mem_to_reg),
        .branch(branch),
        .alu_op(alu_op)
    );

    initial begin
        $dumpfile("control.vcd");
        $dumpvars(0, control_tb);

        // R-type
        opcode = 7'b0110011; #10;
        $display("R-type:  reg_write=%b alu_src=%b mem_write=%b mem_read=%b branch=%b alu_op=%b",
                  reg_write, alu_src, mem_write, mem_read, branch, alu_op);

        // I-type
        opcode = 7'b0010011; #10;
        $display("I-type:  reg_write=%b alu_src=%b mem_write=%b mem_read=%b branch=%b alu_op=%b",
                  reg_write, alu_src, mem_write, mem_read, branch, alu_op);

        // LOAD
        opcode = 7'b0000011; #10;
        $display("LOAD:    reg_write=%b alu_src=%b mem_write=%b mem_read=%b branch=%b alu_op=%b",
                  reg_write, alu_src, mem_write, mem_read, branch, alu_op);

        // STORE
        opcode = 7'b0100011; #10;
        $display("STORE:   reg_write=%b alu_src=%b mem_write=%b mem_read=%b branch=%b alu_op=%b",
                  reg_write, alu_src, mem_write, mem_read, branch, alu_op);

        // BRANCH
        opcode = 7'b1100011; #10;
        $display("BRANCH:  reg_write=%b alu_src=%b mem_write=%b mem_read=%b branch=%b alu_op=%b",
                  reg_write, alu_src, mem_write, mem_read, branch, alu_op);

        $finish;
    end
endmodule