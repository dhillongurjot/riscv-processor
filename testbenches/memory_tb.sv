module memory_tb;
    reg clk, mem_read, mem_write;
    reg [31:0] address, write_data;
    wire [31:0] read_data;

    memory uut(
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .address(address),
        .write_data(write_data),
        .read_data(read_data)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("memory.vcd");
        $dumpvars(0, memory_tb);
        clk = 0; mem_read = 0; mem_write = 0;

        // write 42 to address 0
        address = 32'd0; write_data = 32'd42;
        mem_write = 1; mem_read = 0;
        @(posedge clk); #1;
        $display("Wrote 42 to address 0");

        // write 100 to address 4
        address = 32'd4; write_data = 32'd100;
        mem_write = 1; mem_read = 0;
        @(posedge clk); #1;
        $display("Wrote 100 to address 4");

        // read back address 0
        address = 32'd0;
        mem_write = 0; mem_read = 1; #10;
        $display("Read address 0 = %0d (expect 42)", read_data);

        // read back address 4
        address = 32'd4;
        mem_write = 0; mem_read = 1; #10;
        $display("Read address 4 = %0d (expect 100)", read_data);

        // make sure read is off when mem_read=0
        mem_read = 0; #10;
        $display("Read with mem_read=0: %0d (expect 0)", read_data);

        $finish;
    end
endmodule