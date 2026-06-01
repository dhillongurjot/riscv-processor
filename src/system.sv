module system(
    input        clk,
    input        reset,
    output       hsync,
    output       vsync,
    output [2:0] rgb
);
    // VGA signals
    wire        visible;
    wire [9:0]  pixel_x, pixel_y;

    // CPU memory interface
    wire        cpu_mem_we;
    wire [31:0] cpu_mem_addr;
    wire [31:0] cpu_mem_wdata;

    // framebuffer write — CPU writes to addresses 0-3071 (768 tiles × 4 bytes)
    wire        fb_we    = cpu_mem_we && (cpu_mem_addr < 32'd3072);
    wire [9:0]  fb_waddr = cpu_mem_addr[11:2];    // byte addr → tile index
    wire [1:0]  fb_wdata = cpu_mem_wdata[1:0];    // lower 2 bits = color

    // framebuffer read — VGA computes which tile current pixel belongs to
    wire [4:0]  tile_x   = pixel_x / 20;
    wire [4:0]  tile_y   = pixel_y / 20;
    wire [9:0]  fb_raddr = {tile_y[4:0], tile_x[4:0]}; // tile_y*32 + tile_x
    wire [1:0]  fb_rdata;

    // CPU
    cpu_pipeline cpu(
        .clk(clk),
        .reset(reset),
        .cpu_mem_we(cpu_mem_we),
        .cpu_mem_addr(cpu_mem_addr),
        .cpu_mem_wdata(cpu_mem_wdata)
    );

    // VGA controller
    vga_controller vga(
        .clk_25mhz(clk),
        .reset(reset),
        .hsync(hsync),
        .vsync(vsync),
        .visible(visible),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y)
    );

    // framebuffer
    framebuffer fb(
        .clk(clk),
        .we(fb_we),
        .waddr(fb_waddr),
        .wdata(fb_wdata),
        .raddr(fb_raddr),
        .rdata(fb_rdata)
    );

    // color output
    reg [2:0] rgb_reg;
    always @(*) begin
        if (!visible)
            rgb_reg = 3'b000;
        else case(fb_rdata)
            2'b00: rgb_reg = 3'b000;  // black
            2'b01: rgb_reg = 3'b010;  // green — snake body
            2'b10: rgb_reg = 3'b100;  // red   — food
            2'b11: rgb_reg = 3'b110;  // yellow — snake head
            default: rgb_reg = 3'b000;
        endcase
    end
    assign rgb = rgb_reg;

endmodule