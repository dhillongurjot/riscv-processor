# RISC-V Processor with Snake Game

A complete RV32I processor designed from scratch in SystemVerilog, featuring a 5-stage pipeline with full hazard handling, a VGA display system, and a Snake game compiled from C running on the custom CPU. Built over the summer as a hardware engineering portfolio project targeting roles at semiconductor companies.

---

## Demo

> **Simulation demo video** — *coming soon*

**Interactive demo** — run locally with `python3 demo/play_snake.py`

The Snake game logic is compiled from C to RISC-V binary using a custom Python assembler and GCC cross-compiler toolchain. The binary executes on the custom CPU, writes game state to a hardware framebuffer, and the VGA controller renders each frame — verified end-to-end in simulation.

---

## What This Project Is

Most computer architecture courses teach you how a CPU works on paper. This project builds one from the ground up — every logic block designed, connected, and verified individually before being wired into a complete working system.

The final result is a pipelined RISC-V processor that:
- Executes the full RV32I base integer instruction set
- Resolves data hazards via forwarding and load-use stall detection
- Drives a VGA display through a hardware framebuffer
- Runs a Snake game compiled from C — verified in simulation

**Targeting synthesis on a Lattice ECP5 FPGA** using the open-source Yosys/nextpnr toolchain (Mac/Linux native, no proprietary tools required).

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                    system.sv                         │
│                                                      │
│  ┌──────────────────────────────┐                   │
│  │       cpu_pipeline.sv        │                   │
│  │                              │                   │
│  │  IF → ID → EX → MEM → WB    │ ──SW writes──►   │
│  │         ↑                    │                   │
│  │  forwarding_unit.sv          │    ┌────────────┐ │
│  │  (RAW hazard resolution)     │    │framebuffer │ │
│  │                              │    │   .sv      │ │
│  │  Modules:                    │    │ 32×16 tiles│ │
│  │  · alu.sv                    │    └─────┬──────┘ │
│  │  · registers.sv              │          │        │
│  │  · control.sv                │    ┌─────▼──────┐ │
│  │  · memory.sv                 │    │vga_ctrl.sv │ │
│  └──────────────────────────────┘    │640×480 60Hz│ │
│                                      └─────┬──────┘ │
└────────────────────────────────────────────┼────────┘
                                             │
                                        VGA output
                                        to monitor
```

---

## Pipeline Design

The CPU implements the classic 5-stage RISC-V pipeline:

| Stage | Module | What it does |
|-------|--------|--------------|
| IF | cpu_pipeline.sv | Fetches instruction from memory using PC |
| ID | control.sv, registers.sv | Decodes opcode, reads register file |
| EX | alu.sv, forwarding_unit.sv | Executes operation, resolves hazards |
| MEM | memory.sv | Reads or writes data memory |
| WB | registers.sv | Writes result back to register file |

### Hazard Handling

**Data hazards (RAW)** — resolved by the forwarding unit. When an instruction in EX needs a value being computed by the instruction ahead of it in MEM or WB, the forwarding unit routes the value directly without waiting for writeback.

**Load-use hazards** — when a LW instruction is immediately followed by an instruction that needs the loaded value, the pipeline stalls for one cycle. The PC and IF/ID register freeze, and a NOP bubble is inserted into EX. This was discovered and debugged by reading disassembled machine code from the compiled Snake binary.

**Control hazards (branches and jumps)** — JAL is resolved in the decode stage with a 1-cycle penalty. JALR and taken branches are resolved in the execute stage with a 2-cycle penalty. Incorrect instructions are flushed from the pipeline.

---

## Supported Instructions

All RV32I base integer instructions:

| Type | Instructions |
|------|-------------|
| R-type | ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU |
| I-type | ADDI, ANDI, ORI, XORI, SLLI, SRLI, SRAI, SLTI, SLTIU |
| Load | LW |
| Store | SW |
| Branch | BEQ, BNE, BLT, BGE, BLTU, BGEU |
| Jump | JAL, JALR |
| Upper imm | LUI, AUIPC |

---

## VGA Display System

The VGA controller generates a 640×480 60Hz signal using a 25MHz pixel clock. Timing parameters:

```
Horizontal: 640 visible + 16 front porch + 96 sync + 48 back porch = 800 total
Vertical:   480 visible + 10 front porch + 2  sync + 33 back porch = 525 total
```

The framebuffer is a 32×16 tile grid (512 tiles total). Each tile stores a 2-bit color code:

| Value | Color | Meaning |
|-------|-------|---------|
| 00 | Black | Empty |
| 01 | Green | Snake body |
| 10 | Red | Food |
| 11 | Yellow | Snake head |

The CPU writes tile values via memory-mapped stores. The VGA controller reads them using pixel coordinates divided by tile size to compute the tile index.

---

## Snake Game

The Snake game is written in C and compiled to a RISC-V binary using the GCC cross-compiler targeting RV32I (`-march=rv32i -mabi=ilp32`). A custom Python assembler handles RV32I assembly encoding for the startup code.

**Game logic:**
- 32×16 tile grid
- Snake moves one tile per game tick
- Wraps at grid boundaries
- Food placed using a linear congruential random number generator
- Snake grows on food collection

**Toolchain:**
```
snake.c + start.S  →  riscv64-unknown-elf-gcc  →  snake.elf
snake.elf          →  objcopy                   →  snake_text.bin
snake_text.bin     →  bin2hex.py                →  snake_imem.hex
snake_imem.hex     →  $readmemh()               →  CPU instruction memory
```

**Simulation verification:**

```
Snake body tiles (green) : 2
Food tiles (red)         : 6
Head tiles (yellow)      : 1
SUCCESS — Snake is running on your CPU
```

---

## Project Structure

```
riscv-processor/
├── src/
│   ├── cpu_pipeline.sv       # 5-stage pipelined CPU (top-level)
│   ├── alu.sv                # 32-bit ALU — all RV32I operations
│   ├── registers.sv          # 32×32-bit register file
│   ├── control.sv            # Instruction decoder / control unit
│   ├── memory.sv             # Data memory (load/store)
│   ├── forwarding_unit.sv    # RAW hazard forwarding logic
│   ├── vga_controller.sv     # 640×480 60Hz VGA timing generator
│   ├── framebuffer.sv        # 32×16 tile display memory
│   └── system.sv             # Top-level: CPU + VGA + framebuffer
├── snake/
│   ├── snake.c               # Snake game in C
│   ├── start.S               # RISC-V startup assembly
│   ├── link.ld               # Linker script
│   ├── assembler.py          # Custom RV32I assembler (Python)
│   ├── bin2hex.py            # Binary to Verilog hex converter
│   └── snake_imem.hex        # Compiled Snake binary (CPU program)
├── testbenches/
│   ├── alu_tb.sv
│   ├── registers_tb.sv
│   ├── control_tb.sv
│   ├── memory_tb.sv
│   ├── cpu_pipeline_tb.sv
│   └── snake_tb.sv
├── demo/
│   ├── visualize_game.py     # Simulation frame visualizer (pygame)
│   └── play_snake.py         # Interactive Snake demo (pygame)
└── README.md
```

---

## Running the Simulation

### Requirements

```bash
brew install icarus-verilog
pip3 install pygame
```

### Run the Snake simulation and visualizer

```bash
# Compile simulation
iverilog -g2012 -o snake_sim \
  src/system.sv src/cpu_pipeline.sv src/forwarding_unit.sv \
  src/alu.sv src/registers.sv src/control.sv src/memory.sv \
  src/framebuffer.sv src/vga_controller.sv \
  testbenches/snake_tb.sv

# Launch visualizer (runs simulation automatically)
python3 demo/visualize_game.py
```

### Play Snake interactively

```bash
python3 demo/play_snake.py
```

Arrow keys to move. R to restart.

### Run individual component testbenches

```bash
# Example: verify ALU
iverilog -g2012 -o alu_sim src/alu.sv testbenches/alu_tb.sv
vvp alu_sim
```

---

## Tools

| Tool | Purpose |
|------|---------|
| Icarus Verilog | SystemVerilog simulation |
| WaveTrace (VS Code) | Waveform visualization |
| riscv64-unknown-elf-gcc | C to RISC-V cross-compiler |
| Python 3 | Assembler, hex converter, visualizer |
| pygame | Demo visualization |
| Yosys + nextpnr | FPGA synthesis (targeting ECP5) |

---

## Skills Demonstrated

- SystemVerilog RTL design and simulation
- Computer architecture — pipeline design, hazard detection and resolution
- RISC-V ISA implementation (RV32I full base integer set)
- Hardware/software co-design — C program running on custom hardware
- Cross-compilation toolchain (GCC, linker scripts, object file manipulation)
- Self-checking testbench-driven verification methodology
- VGA display controller design

---

## Author

**Gurjot Dhillon** — Computer Engineering, Toronto Metropolitan University

GitHub: [@dhillongurjot](https://github.com/dhillongurjot)
