module snake_tb;
    reg clk, reset;
    wire hsync, vsync;
    wire [2:0] rgb;

    system uut(
        .clk(clk), .reset(reset),
        .hsync(hsync), .vsync(vsync), .rgb(rgb)
    );

    always #20 clk = ~clk;

    integer i, frame;

    initial begin
        clk = 0; reset = 1; #40;
        reset = 0;

        // wait for init() to finish
        repeat(500000) @(posedge clk);

        // capture 80 game frames
        for (frame = 0; frame < 80; frame = frame + 1) begin
            // one game tick — short delay loop = ~50k cycles
            repeat(50000) @(posedge clk);

            $display("FRAME %0d", frame);
            for (i = 0; i < 512; i = i + 1)
                $display("%0d", uut.fb.tiles[i]);
        end

        $display("DONE");
        $finish;
    end
endmodule