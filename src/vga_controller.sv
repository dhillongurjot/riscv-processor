module vga_controller(
    input        clk_25mhz,
    input        reset,
    output reg   hsync,
    output reg   vsync,
    output       visible,
    output [9:0] pixel_x,
    output [9:0] pixel_y
);
    // horizontal timing
    localparam H_VISIBLE    = 640;
    localparam H_FRONT      = 16;
    localparam H_SYNC       = 96;
    localparam H_BACK       = 48;
    localparam H_TOTAL      = 800;

    // vertical timing
    localparam V_VISIBLE    = 480;
    localparam V_FRONT      = 10;
    localparam V_SYNC       = 2;
    localparam V_BACK       = 33;
    localparam V_TOTAL      = 525;

    // counters
    reg [9:0] h_count;
    reg [9:0] v_count;

    // horizontal counter
    always @(posedge clk_25mhz or posedge reset) begin
        if (reset)
            h_count <= 0;
        else if (h_count == H_TOTAL - 1)
            h_count <= 0;
        else
            h_count <= h_count + 1;
    end

    // vertical counter
    always @(posedge clk_25mhz or posedge reset) begin
        if (reset)
            v_count <= 0;
        else if (h_count == H_TOTAL - 1) begin
            if (v_count == V_TOTAL - 1)
                v_count <= 0;
            else
                v_count <= v_count + 1;
        end
    end

    // sync pulses — active low
    always @(posedge clk_25mhz) begin
        hsync <= ~(h_count >= H_VISIBLE + H_FRONT &&
                   h_count <  H_VISIBLE + H_FRONT + H_SYNC);
        vsync <= ~(v_count >= V_VISIBLE + V_FRONT &&
                   v_count <  V_VISIBLE + V_FRONT + V_SYNC);
    end

    // visible area and pixel coordinates
    assign visible = (h_count < H_VISIBLE) && (v_count < V_VISIBLE);
    assign pixel_x = h_count;
    assign pixel_y = v_count;

endmodule