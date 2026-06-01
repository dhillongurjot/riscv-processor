module control(
    input  [6:0] opcode,
    output reg        reg_write,
    output reg        alu_src,
    output reg        mem_write,
    output reg        mem_read,
    output reg        mem_to_reg,
    output reg        branch,
    output reg        jal,
    output reg        jalr,
    output reg        lui,
    output reg        auipc,
    output reg [1:0]  alu_op,
    output reg [1:0]  imm_sel
);
    always @(*) begin
        // default everything to 0 first
        reg_write = 0; alu_src = 0; mem_write = 0;
        mem_read  = 0; mem_to_reg = 0; branch = 0;
        jal = 0; jalr = 0; lui = 0; auipc = 0;
        alu_op = 2'b00; imm_sel = 2'b00;

        case(opcode)
            7'b0110011: begin // R-type
                reg_write = 1;
                alu_op    = 2'b10;
            end
            7'b0010011: begin // I-type ALU
                reg_write = 1;
                alu_src   = 1;
                alu_op    = 2'b10;
            end
            7'b0000011: begin // LOAD
                reg_write  = 1;
                alu_src    = 1;
                mem_read   = 1;
                mem_to_reg = 1;
            end
            7'b0100011: begin // STORE
                alu_src   = 1;
                mem_write = 1;
                imm_sel   = 2'b01;
            end
            7'b1100011: begin // BRANCH
                branch  = 1;
                alu_op  = 2'b01;
                imm_sel = 2'b11;
            end
            7'b0110111: begin // LUI
                reg_write = 1;
                lui       = 1;
                imm_sel   = 2'b10;
            end
            7'b0010111: begin // AUIPC
                reg_write = 1;
                auipc     = 1;
                imm_sel   = 2'b10;
            end
            7'b1101111: begin // JAL
                reg_write = 1;
                jal       = 1;
            end
            7'b1100111: begin // JALR
                reg_write = 1;
                jalr      = 1;
                alu_src   = 1;
            end
            default: begin end
        endcase
    end
endmodule