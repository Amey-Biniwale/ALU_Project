# Parameterized ALU – RTL Design & Verification

A fully parameterized, synthesizable Arithmetic Logic Unit (ALU) implemented in Verilog, supporting configurable data width via the `WIDTH` parameter (default: 8-bit). The design operates across two modes — **Arithmetic** and **Logical** — controlled by the `MODE` signal, and exposes 13 arithmetic and 14 logical operations selectable through a 4-bit `CMD` input.

---

## Features

- **Parameterized width** — scalable to any datapath width at instantiation
- **Dual-mode operation** — Arithmetic (`MODE=1`) and Logical (`MODE=0`)
- **27 operations** — including signed/unsigned arithmetic, multiply with 2-cycle latency, bitwise logic, shifts, and barrel rotation
- **Clock Enable (CE)** — output latch-hold when de-asserted
- **Asynchronous reset (RST)** — all registers cleared immediately
- **INP_VALID checking** — per-operand validity control with automatic ERR flagging
- **Overflow & carry detection** — separate `OFLOW` and `COUT` flags for signed and unsigned arithmetic
- **Comparison outputs** — dedicated `E`, `G`, `L` flags for equality, greater-than, and less-than

---

## Operations

| Mode | CMD Range | Examples |
|------|-----------|---------|
| Arithmetic (`MODE=1`) | 0–12 | ADD, SUB, ADD_CIN, SUB_CIN, INC/DEC, CMP, MUL_INC, MUL_SHI, SIGNED_ADD, SIGNED_SUB |
| Logical (`MODE=0`) | 0–13 | AND, NAND, OR, NOR, XOR, XNOR, NOT, Shift L/R, Rotate L/R |

---

## Verification

The design is verified using a self-checking testbench (`alu_tb`) that instantiates both the DUT and a Verilog reference model in parallel. Identical stimuli are applied to both and outputs are compared on every test vector.

- **56 test vectors** across direct, corner-case, and error-injection categories
- **37 passed / 19 failed** — failures traced to signed flag leakage, 2-cycle multiply intermediate state, INC/DEC result width, and missing default ERR assertion
- **98.12% total coverage** (Questa SIM) — 100% statement, 100% branch, 95.83% FEC expression, 94.79% toggle
- Waveform analysis performed in **Vivado**
- Simulation run on **Synopsys VCS**

---

## File Structure
<img width="266" height="233" alt="image" src="https://github.com/user-attachments/assets/c11cd02b-54cc-4ad3-a80b-5f538242dcd6" />


---

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `WIDTH` | 8 | Operand and result bit-width |
| `CMD_WIDTH` | 4 | Command bus width |

---

## Tools Used

| Purpose | Tool |
|---------|------|
| Simulation | Synopsys VCS |
| Waveform | Vivado |
| Coverage | Questa SIM |
