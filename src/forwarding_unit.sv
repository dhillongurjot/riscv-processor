module forwarding_unit(
    input [4:0]  IDEX_rs1,
    input [4:0]  IDEX_rs2,
    input [4:0]  EXMEM_rd,
    input        EXMEM_reg_write,
    input [4:0]  MEMWB_rd,
    input        MEMWB_reg_write,
    output reg [1:0] forwardA,
    output reg [1:0] forwardB
);
    always @(*) begin
        // default — use register file value
        forwardA = 2'b00;
        forwardB = 2'b00;

        // EX hazard — forward from EX/MEM stage
        if (EXMEM_reg_write && EXMEM_rd != 5'd0) begin
            if (EXMEM_rd == IDEX_rs1) forwardA = 2'b10;
            if (EXMEM_rd == IDEX_rs2) forwardB = 2'b10;
        end

        // MEM hazard — forward from MEM/WB stage
        // only if EX hazard didn't already handle it
        if (MEMWB_reg_write && MEMWB_rd != 5'd0) begin
            if (MEMWB_rd == IDEX_rs1 && forwardA == 2'b00)
                forwardA = 2'b01;
            if (MEMWB_rd == IDEX_rs2 && forwardB == 2'b00)
                forwardB = 2'b01;
        end
    end
endmodule