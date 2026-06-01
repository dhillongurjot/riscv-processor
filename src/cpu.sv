module cpu(
    input clk,
    input reset
);
    // program counter
    reg [31:0] pc;

    // instruction memory (separate from data memory)
    reg [31:0] imem [0:255];

    // wires connecting everything together
    wire [31:0] instruction;
    wire [6:0]  opcode;
    wire [4:0]  rs1, rs2, rd;
    wire [31:0] imm;
    wire [31:0] reg_data1, reg_data2;
    wire [31:0] alu_input_b;
    wire [31:0] alu_result;
    wire [31:0] mem_read_data;
    wire [31:0] write_back_data;
    wire [2:0]  alu_ctrl_signal;

    // control signals
    wire reg_write, alu_src, mem_write, mem_read, mem_to_reg, branch;
    wire [1:0] alu_op;

    // fetch instruction from instruction memory
    assign instruction = imem[pc[9:2]];

    // decode instruction fields
    assign opcode = instruction[6:0];
    assign rd     = instruction[11:7];
    assign rs1    = instruction[19:15];
    assign rs2    = instruction[24:20];
    assign imm    = {{20{instruction[31]}}, instruction[31:20]};

    // control unit
    control ctrl(
        .opcode(opcode),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .mem_to_reg(mem_to_reg),
        .branch(branch),
        .alu_op(alu_op)
    );

    // register file
    registers regfile(
        .clk(clk),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .wd(write_back_data),
        .we(reg_write),
        .rd1(reg_data1),
        .rd2(reg_data2)
    );

    // ALU input mux — register or immediate
    assign alu_input_b = alu_src ? imm : reg_data2;

    // ALU operation decoder
    assign alu_ctrl_signal = (alu_op == 2'b10) ? {1'b0, instruction[14:12]} :
                             (alu_op == 2'b01) ? 3'b001 :
                                                 3'b000;

    // ALU
    alu alu_unit(
        .a(reg_data1),
        .b(alu_input_b),
        .alu_ctrl(alu_ctrl_signal),
        .result(alu_result)
    );

    // data memory
    memory dmem(
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .address(alu_result),
        .write_data(reg_data2),
        .read_data(mem_read_data)
    );

    // writeback mux — ALU result or memory data
    assign write_back_data = mem_to_reg ? mem_read_data : alu_result;

    // program counter update
    always @(posedge clk or posedge reset) begin
        if (reset)
            pc <= 32'd0;
        else
            pc <= pc + 32'd4;
    end

endmodule