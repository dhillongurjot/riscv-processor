module alu_tb;
    reg [31:0] a, b;
    reg [2:0] alu_ctrl;
    wire [31:0] result;

    alu uut (.a(a), .b(b), .alu_ctrl(alu_ctrl), .result(result));

    initial begin
        $dumpfile("alu.vcd");
        $dumpvars(0, alu_tb);

        // ADD
        a = 32'd15; b = 32'd10; alu_ctrl = 3'b000; #10;
        $display("ADD: %0d + %0d = %0d", a, b, result);

        // SUB
        a = 32'd15; b = 32'd10; alu_ctrl = 3'b001; #10;
        $display("SUB: %0d - %0d = %0d", a, b, result);

        // AND
        a = 32'hFF00; b = 32'hF0F0; alu_ctrl = 3'b010; #10;
        $display("AND: %h & %h = %h", a, b, result);

        // OR
        a = 32'hFF00; b = 32'hF0F0; alu_ctrl = 3'b011; #10;
        $display("OR: %h | %h = %h", a, b, result);

        // SLT (true case)
        a = 32'd5; b = 32'd10; alu_ctrl = 3'b100; #10;
        $display("SLT: %0d < %0d = %0d (expect 1)", a, b, result);

        // SLT (false case)
        a = 32'd10; b = 32'd5; alu_ctrl = 3'b100; #10;
        $display("SLT: %0d < %0d = %0d (expect 0)", a, b, result);

        // SLT (negative number test - this is why $signed matters)
        a = -32'd1; b = 32'd1; alu_ctrl = 3'b100; #10;
        $display("SLT: -1 < 1 = %0d (expect 1)", result);

        $finish;
    end
endmodule