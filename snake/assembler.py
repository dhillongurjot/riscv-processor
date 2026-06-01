# RISC-V RV32I Assembler

# register name to number mapping
REGISTERS = {
    'x0':0,  'x1':1,  'x2':2,  'x3':3,
    'x4':4,  'x5':5,  'x6':6,  'x7':7,
    'x8':8,  'x9':9,  'x10':10,'x11':11,
    'x12':12,'x13':13,'x14':14,'x15':15,
    'x16':16,'x17':17,'x18':18,'x19':19,
    'x20':20,'x21':21,'x22':22,'x23':23,
    'x24':24,'x25':25,'x26':26,'x27':27,
    'x28':28,'x29':29,'x30':30,'x31':31,
    # ABI names
    'zero':0,'ra':1,'sp':2,'gp':3,
    'tp':4, 't0':5,'t1':6,'t2':7,
    's0':8, 's1':9,'a0':10,'a1':11,
    'a2':12,'a3':13,'a4':14,'a5':15,
    'a6':16,'a7':17,'s2':18,'s3':19,
    's4':20,'s5':21,'s6':22,'s7':23,
    's8':24,'s9':25,'s10':26,'s11':27,
    't3':28,'t4':29,'t5':30,'t6':31
}

def reg(name):
    name = name.strip().rstrip(',')
    if name not in REGISTERS:
        raise ValueError(f"Unknown register: {name}")
    return REGISTERS[name]

def to_bin(value, bits):
    if value < 0:
        value = value + (1 << bits)
    return format(value & ((1 << bits) - 1), f'0{bits}b')

def encode_r(funct7, rs2, rs1, funct3, rd, opcode):
    return to_bin(funct7,7) + to_bin(rs2,5) + to_bin(rs1,5) + \
           to_bin(funct3,3) + to_bin(rd,5) + to_bin(opcode,7)

def encode_i(imm, rs1, funct3, rd, opcode):
    return to_bin(imm,12) + to_bin(rs1,5) + \
           to_bin(funct3,3) + to_bin(rd,5) + to_bin(opcode,7)

def encode_s(imm, rs2, rs1, funct3, opcode):
    imm_b = to_bin(imm, 12)
    return imm_b[0:7] + to_bin(rs2,5) + to_bin(rs1,5) + \
           to_bin(funct3,3) + imm_b[7:12] + to_bin(opcode,7)

def encode_b(imm, rs2, rs1, funct3, opcode):
    imm_b = to_bin(imm, 13)
    return imm_b[0] + imm_b[2:8] + to_bin(rs2,5) + to_bin(rs1,5) + \
           to_bin(funct3,3) + imm_b[8:12] + imm_b[1] + to_bin(opcode,7)

def assemble_instruction(parts, labels, current_addr):
    op = parts[0].upper()

    # ── R-type ──────────────────────────────
    if op == 'ADD':
        rd, rs1, rs2 = reg(parts[1]), reg(parts[2]), reg(parts[3])
        return encode_r(0, rs2, rs1, 0, rd, 0b0110011)

    elif op == 'SUB':
        rd, rs1, rs2 = reg(parts[1]), reg(parts[2]), reg(parts[3])
        return encode_r(0b0100000, rs2, rs1, 0, rd, 0b0110011)

    elif op == 'AND':
        rd, rs1, rs2 = reg(parts[1]), reg(parts[2]), reg(parts[3])
        return encode_r(0, rs2, rs1, 0b111, rd, 0b0110011)

    elif op == 'OR':
        rd, rs1, rs2 = reg(parts[1]), reg(parts[2]), reg(parts[3])
        return encode_r(0, rs2, rs1, 0b110, rd, 0b0110011)

    elif op == 'SLT':
        rd, rs1, rs2 = reg(parts[1]), reg(parts[2]), reg(parts[3])
        return encode_r(0, rs2, rs1, 0b010, rd, 0b0110011)

    # ── I-type ──────────────────────────────
    elif op == 'ADDI':
        rd, rs1, imm = reg(parts[1]), reg(parts[2]), int(parts[3])
        return encode_i(imm, rs1, 0, rd, 0b0010011)

    elif op == 'LW':
        rd   = reg(parts[1])
        # format: LW rd, imm(rs1)
        rest = parts[2].replace(')', '').split('(')
        imm, rs1 = int(rest[0]), reg(rest[1])
        return encode_i(imm, rs1, 0b010, rd, 0b0000011)

    # ── S-type ──────────────────────────────
    elif op == 'SW':
        rs2  = reg(parts[1])
        rest = parts[2].replace(')', '').split('(')
        imm, rs1 = int(rest[0]), reg(rest[1])
        return encode_s(imm, rs2, rs1, 0b010, 0b0100011)

    # ── B-type ──────────────────────────────
    elif op == 'BEQ':
        rs1, rs2 = reg(parts[1]), reg(parts[2])
        label = parts[3].strip()
        imm = labels[label] - current_addr
        return encode_b(imm, rs2, rs1, 0b000, 0b1100011)

    elif op == 'BNE':
        rs1, rs2 = reg(parts[1]), reg(parts[2])
        label = parts[3].strip()
        imm = labels[label] - current_addr
        return encode_b(imm, rs2, rs1, 0b001, 0b1100011)

    else:
        raise ValueError(f"Unknown instruction: {op}")


def assemble(input_file, output_file):
    with open(input_file, 'r') as f:
        lines = f.readlines()

    # first pass — collect labels
    labels = {}
    addr = 0
    clean_lines = []
    for line in lines:
        line = line.split('#')[0].strip()  # remove comments
        if not line:
            continue
        if line.endswith(':'):
            labels[line[:-1]] = addr  # store label address
        else:
            clean_lines.append((addr, line))
            addr += 4

    # second pass — encode instructions
    binary_instructions = []
    for addr, line in clean_lines:
        parts = line.split()
        binary = assemble_instruction(parts, labels, addr)
        binary_instructions.append(binary)
        print(f"{addr:3}: {line:30} → {binary}")

    # write output
    with open(output_file, 'w') as f:
        for b in binary_instructions:
            f.write(b + '\n')

    print(f"\nAssembled {len(binary_instructions)} instructions → {output_file}")


if __name__ == '__main__':
    assemble('program.asm', 'program.bin')