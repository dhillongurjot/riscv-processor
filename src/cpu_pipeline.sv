module cpu_pipeline(
    input  clk,
    input  reset,
    output        cpu_mem_we,
    output [31:0] cpu_mem_addr,
    output [31:0] cpu_mem_wdata
);

    reg [31:0] imem [0:2047];
    initial begin
        $readmemh("snake_imem.hex", imem);
    end

    reg [31:0] pc;

    // ── IF/ID ──────────────────────────────────────────────
    reg [31:0] IFID_pc;
    reg [31:0] IFID_instr;

    // ── ID/EX ──────────────────────────────────────────────
    reg [31:0] IDEX_pc;
    reg [31:0] IDEX_reg_data1, IDEX_reg_data2;
    reg [31:0] IDEX_imm;
    reg [4:0]  IDEX_rs1, IDEX_rs2, IDEX_rd;
    reg [2:0]  IDEX_funct3;
    reg        IDEX_funct7_5;
    reg        IDEX_reg_write, IDEX_alu_src;
    reg        IDEX_mem_write, IDEX_mem_read, IDEX_mem_to_reg;
    reg        IDEX_branch, IDEX_jal, IDEX_jalr, IDEX_lui, IDEX_auipc;
    reg [1:0]  IDEX_alu_op;

    // ── EX/MEM ─────────────────────────────────────────────
    reg [31:0] EXMEM_alu_result;
    reg [31:0] EXMEM_reg_data2;
    reg [4:0]  EXMEM_rd;
    reg        EXMEM_reg_write;
    reg        EXMEM_mem_write, EXMEM_mem_read, EXMEM_mem_to_reg;

    // ── MEM/WB ─────────────────────────────────────────────
    reg [31:0] MEMWB_read_data;
    reg [31:0] MEMWB_alu_result;
    reg [4:0]  MEMWB_rd;
    reg        MEMWB_reg_write;
    reg        MEMWB_mem_to_reg;

    // ── Control wires ───────────────────────────────────────
    wire reg_write, alu_src, mem_write, mem_read, mem_to_reg;
    wire branch, jal, jalr, lui, auipc;
    wire [1:0] alu_op, imm_sel;

    // ── Instruction fields ──────────────────────────────────
    wire [6:0] opcode   = IFID_instr[6:0];
    wire [4:0] rd       = IFID_instr[11:7];
    wire [4:0] rs1      = IFID_instr[19:15];
    wire [4:0] rs2      = IFID_instr[24:20];
    wire [2:0] funct3   = IFID_instr[14:12];
    wire       funct7_5 = IFID_instr[30];

    // ── All immediate types ─────────────────────────────────
    wire [31:0] imm_i = {{20{IFID_instr[31]}}, IFID_instr[31:20]};
    wire [31:0] imm_s = {{20{IFID_instr[31]}}, IFID_instr[31:25],
                          IFID_instr[11:7]};
    wire [31:0] imm_b = {{19{IFID_instr[31]}}, IFID_instr[31],
                          IFID_instr[7], IFID_instr[30:25],
                          IFID_instr[11:8], 1'b0};
    wire [31:0] imm_u = {IFID_instr[31:12], 12'b0};
    wire [31:0] imm_j = {{11{IFID_instr[31]}}, IFID_instr[31],
                          IFID_instr[19:12], IFID_instr[20],
                          IFID_instr[30:21], 1'b0};

    wire [31:0] imm_selected = (imm_sel == 2'b01) ? imm_s :
                               (imm_sel == 2'b10) ? imm_u :
                               (imm_sel == 2'b11) ? imm_b : imm_i;

    // ── Execute wires ───────────────────────────────────────
    wire [31:0] alu_result;
    wire [31:0] alu_operand_a, alu_operand_b, alu_input_b;
    wire [1:0]  forwardA, forwardB;
    wire [3:0]  alu_ctrl_signal;
    wire [31:0] write_back_data;
    wire [31:0] mem_read_data;

    wire [31:0] ex_result =
        IDEX_lui             ? IDEX_imm :
        IDEX_auipc           ? IDEX_pc + IDEX_imm :
        (IDEX_jal|IDEX_jalr) ? IDEX_pc + 32'd4 :
                               alu_result;

    // ── Jump and branch targets ─────────────────────────────
    wire [31:0] jal_target    = IFID_pc + imm_j;
    wire [31:0] jalr_target   = (alu_operand_a + IDEX_imm) & ~32'd1;
    wire [31:0] branch_target = IDEX_pc + IDEX_imm;

    wire eq          = (alu_operand_a == alu_operand_b);
    wire signed_lt   = ($signed(alu_operand_a) < $signed(alu_operand_b));
    wire unsigned_lt = (alu_operand_a < alu_operand_b);

    wire take_branch = IDEX_branch && (
        (IDEX_funct3 == 3'b000 &&  eq)          ||
        (IDEX_funct3 == 3'b001 && !eq)          ||
        (IDEX_funct3 == 3'b100 &&  signed_lt)   ||
        (IDEX_funct3 == 3'b101 && !signed_lt)   ||
        (IDEX_funct3 == 3'b110 &&  unsigned_lt) ||
        (IDEX_funct3 == 3'b111 && !unsigned_lt)
    );

    // ── Load-use hazard detection ────────────────────────────
    wire load_use_hazard = IDEX_mem_read &&
                           (IDEX_rd != 5'd0) &&
                           (IDEX_rd == rs1 || IDEX_rd == rs2);

    // ── Register file ────────────────────────────────────────
    wire [31:0] reg_data1, reg_data2;

    registers regfile(
        .clk(clk),
        .rs1(rs1), .rs2(rs2),
        .rd(MEMWB_rd), .wd(write_back_data),
        .we(MEMWB_reg_write),
        .rd1(reg_data1), .rd2(reg_data2)
    );

    // ── STAGE 1: FETCH ───────────────────────────────────────
    wire [31:0] instruction = imem[pc[12:2]];

    always @(posedge clk or posedge reset) begin
        if (reset)
            pc <= 32'd0;
        else if (IDEX_jalr)
            pc <= jalr_target;
        else if (take_branch)
            pc <= branch_target;
        else if (jal)
            pc <= jal_target;
        else if (!load_use_hazard)
            pc <= pc + 32'd4;
        // stall: PC holds when load_use_hazard=1
    end

    always @(posedge clk or posedge reset) begin
        if (reset || jal || IDEX_jalr || take_branch) begin
            IFID_pc    <= 32'd0;
            IFID_instr <= 32'd0;
        end else if (!load_use_hazard) begin
            IFID_pc    <= pc;
            IFID_instr <= instruction;
        end
        // stall: IFID holds when load_use_hazard=1
    end

    // ── STAGE 2: DECODE ──────────────────────────────────────
    control ctrl(
        .opcode(opcode),
        .reg_write(reg_write), .alu_src(alu_src),
        .mem_write(mem_write), .mem_read(mem_read),
        .mem_to_reg(mem_to_reg), .branch(branch),
        .jal(jal), .jalr(jalr), .lui(lui), .auipc(auipc),
        .alu_op(alu_op), .imm_sel(imm_sel)
    );

    always @(posedge clk or posedge reset) begin
        if (reset || IDEX_jalr || take_branch || load_use_hazard) begin
            IDEX_pc         <= 0; IDEX_reg_data1  <= 0;
            IDEX_reg_data2  <= 0; IDEX_imm        <= 0;
            IDEX_rd         <= 0; IDEX_rs1        <= 0;
            IDEX_rs2        <= 0; IDEX_funct3     <= 0;
            IDEX_funct7_5   <= 0; IDEX_reg_write  <= 0;
            IDEX_alu_src    <= 0; IDEX_mem_write  <= 0;
            IDEX_mem_read   <= 0; IDEX_mem_to_reg <= 0;
            IDEX_branch     <= 0; IDEX_jal        <= 0;
            IDEX_jalr       <= 0; IDEX_lui        <= 0;
            IDEX_auipc      <= 0; IDEX_alu_op     <= 0;
        end else begin
            IDEX_pc         <= IFID_pc;
            IDEX_reg_data1  <= reg_data1;
            IDEX_reg_data2  <= reg_data2;
            IDEX_imm        <= imm_selected;
            IDEX_rd         <= rd;
            IDEX_rs1        <= rs1;
            IDEX_rs2        <= rs2;
            IDEX_funct3     <= funct3;
            IDEX_funct7_5   <= funct7_5;
            IDEX_reg_write  <= reg_write;
            IDEX_alu_src    <= alu_src;
            IDEX_mem_write  <= mem_write;
            IDEX_mem_read   <= mem_read;
            IDEX_mem_to_reg <= mem_to_reg;
            IDEX_branch     <= branch;
            IDEX_jal        <= jal;
            IDEX_jalr       <= jalr;
            IDEX_lui        <= lui;
            IDEX_auipc      <= auipc;
            IDEX_alu_op     <= alu_op;
        end
    end

    // ── STAGE 3: EXECUTE ─────────────────────────────────────
    forwarding_unit fwd(
        .IDEX_rs1(IDEX_rs1), .IDEX_rs2(IDEX_rs2),
        .EXMEM_rd(EXMEM_rd), .EXMEM_reg_write(EXMEM_reg_write),
        .MEMWB_rd(MEMWB_rd), .MEMWB_reg_write(MEMWB_reg_write),
        .forwardA(forwardA), .forwardB(forwardB)
    );

    assign alu_operand_a = (forwardA == 2'b10) ? EXMEM_alu_result :
                           (forwardA == 2'b01) ? write_back_data  :
                                                 IDEX_reg_data1;

    assign alu_operand_b = (forwardB == 2'b10) ? EXMEM_alu_result :
                           (forwardB == 2'b01) ? write_back_data  :
                                                 IDEX_reg_data2;

    assign alu_input_b = IDEX_alu_src ? IDEX_imm : alu_operand_b;

    assign alu_ctrl_signal =
        (IDEX_alu_op == 2'b00) ? 4'b0000 :
        (IDEX_alu_op == 2'b01) ? 4'b0001 :
        (IDEX_funct3 == 3'b000) ? (IDEX_funct7_5 ? 4'b0001 : 4'b0000) :
        (IDEX_funct3 == 3'b001) ? 4'b0010 :
        (IDEX_funct3 == 3'b010) ? 4'b0011 :
        (IDEX_funct3 == 3'b011) ? 4'b0100 :
        (IDEX_funct3 == 3'b100) ? 4'b0101 :
        (IDEX_funct3 == 3'b101) ? (IDEX_funct7_5 ? 4'b0111 : 4'b0110) :
        (IDEX_funct3 == 3'b110) ? 4'b1000 :
        (IDEX_funct3 == 3'b111) ? 4'b1001 :
                                   4'b0000;

    alu alu_unit(
        .a(alu_operand_a),
        .b(alu_input_b),
        .alu_ctrl(alu_ctrl_signal),
        .result(alu_result)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            EXMEM_alu_result <= 0; EXMEM_reg_data2  <= 0;
            EXMEM_rd         <= 0; EXMEM_reg_write  <= 0;
            EXMEM_mem_write  <= 0; EXMEM_mem_read   <= 0;
            EXMEM_mem_to_reg <= 0;
        end else begin
            EXMEM_alu_result <= ex_result;
            EXMEM_reg_data2  <= IDEX_reg_data2;
            EXMEM_rd         <= IDEX_rd;
            EXMEM_reg_write  <= IDEX_reg_write;
            EXMEM_mem_write  <= IDEX_mem_write;
            EXMEM_mem_read   <= IDEX_mem_read;
            EXMEM_mem_to_reg <= IDEX_mem_to_reg;
        end
    end

    // ── STAGE 4: MEMORY ──────────────────────────────────────
    memory dmem(
        .clk(clk),
        .mem_read(EXMEM_mem_read),
        .mem_write(EXMEM_mem_write),
        .address(EXMEM_alu_result),
        .write_data(EXMEM_reg_data2),
        .read_data(mem_read_data)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            MEMWB_read_data  <= 0; MEMWB_alu_result <= 0;
            MEMWB_rd         <= 0; MEMWB_reg_write  <= 0;
            MEMWB_mem_to_reg <= 0;
        end else begin
            MEMWB_read_data  <= mem_read_data;
            MEMWB_alu_result <= EXMEM_alu_result;
            MEMWB_rd         <= EXMEM_rd;
            MEMWB_reg_write  <= EXMEM_reg_write;
            MEMWB_mem_to_reg <= EXMEM_mem_to_reg;
        end
    end

    // ── STAGE 5: WRITEBACK ───────────────────────────────────
    assign write_back_data = MEMWB_mem_to_reg ?
                             MEMWB_read_data : MEMWB_alu_result;

    // ── MEMORY MAPPED OUTPUT ─────────────────────────────────
    assign cpu_mem_we    = EXMEM_mem_write;
    assign cpu_mem_addr  = EXMEM_alu_result;
    assign cpu_mem_wdata = EXMEM_reg_data2;

endmodule