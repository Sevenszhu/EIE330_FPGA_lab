# FPGA Laboratory 1 Pre-Lab Report

**Designs:** One-Bit Full Adder and One-Bit Magnitude Comparator  
**HDL:** Verilog  
**Simulation tool:** Icarus Verilog


tools: ChatGPT for better .md format ,and some trasnlations

---

## Step 1: Preliminary Research

### 1.1 Design Objectives

This laboratory contains two small combinational-logic designs.

- **Task 1 — Full adder:** Three one-bit inputs, A, B, and C, are added. O0 is the sum bit and carry is the carry-out bit.
- **Task 2 — Magnitude comparator:** Two one-bit inputs, A and B, are compared. The three outputs indicate A > B, A = B, and A < B.

Both circuits are asynchronous combinational circuits. Their outputs respond directly to input changes, so no clock or state register is required.

### 1.2 FPGA and I/O Considerations

The target Cyclone IV FPGA provides far more logic resources than these two circuits require(10KLUT). Each design can be implemented using only a small number of logic elements.

The FPGA is provided in a BGA package. For this low-speed experiment, the relevant board-level concerns are the assigned pins, I/O-bank voltage, and the electrical polarity of the switches and LEDs. LVCMOS is suitable for the push-button and LED interfaces used in this experiment.

The push buttons are treated as active-low inputs. The LEDs may also be connected as active-low outputs, with the FPGA sinking current through a current-limiting resistor. Mechanical switch debounce is not included because the experiment focuses on combinational logic and functional simulation.Actually it has hardwire debounus ,RC constant is 0.5ms around

### 1.3 Estimated Resources

| Design | Inputs | Outputs | Expected implementation |
|---|---:|---:|---|
| Full adder | 3 | 2 | XOR and majority logic |
| Comparator | 2 | 3 | Three one-bit comparison functions |

The final resource count and pin assignments should be confirmed after synthesis and fitting in Quartus.

---

## Step 2: FPGA Solution

Both modules are described with continuous assignments. Two parameters are included to support active-low board connections:

- INVERSE_INPUT inverts all external inputs before they enter the core logic.
- INVERSE_OUT inverts all core outputs before they reach the external pins.

This keeps the logical function separate from the polarity of the board peripherals. In the functional simulation, both parameters are set to 1.

Because the input spaces are small, exhaustive simulation is practical:

- The full adder requires 2³ = 8 test cases.
- The comparator requires 2² = 4 test cases.

---

## Step 3: Verilog Source Code

### 3.1 Task 1 — Full Adder

Source file: task1/adder.v

~~~verilog
`timescale 1ns/1ps
module adder #(
    parameter INVERSE_OUT   = 0,
    parameter INVERSE_INPUT = 0
)(
    input  wire A,
    input  wire B,
    input  wire C,
    output wire O0,
    output wire carry
);

wire A_internal;
wire B_internal;
wire C_internal;

wire O0_internal;
wire carry_internal;

assign A_internal = A ^ INVERSE_INPUT;
assign B_internal = B ^ INVERSE_INPUT;
assign C_internal = C ^ INVERSE_INPUT;

assign O0_internal =
    A_internal ^ B_internal ^ C_internal;

assign carry_internal =
    (A_internal & B_internal) |
    (A_internal & C_internal) |
    (B_internal & C_internal);

assign O0    = O0_internal    ^ INVERSE_OUT;
assign carry = carry_internal ^ INVERSE_OUT;

endmodule
~~~

### 3.2 Task 2 — Magnitude Comparator

Source file: task2/cmp.v

~~~verilog
`timescale 1ns/1ps
module cmp #(
    parameter INVERSE_OUT   = 0,
    parameter INVERSE_INPUT = 0
)(
    input  wire A,
    input  wire B,
    output wire GT,
    output wire EQ,
    output wire LT
);

wire A_internal;
wire B_internal;
wire GT_internal;
wire EQ_internal;
wire LT_internal;

assign A_internal = A ^ INVERSE_INPUT;
assign B_internal = B ^ INVERSE_INPUT;

assign GT_internal = (A_internal > B_internal);
assign EQ_internal = (A_internal == B_internal);
assign LT_internal = (A_internal < B_internal);

assign GT = GT_internal ^ INVERSE_OUT;
assign EQ = EQ_internal ^ INVERSE_OUT;
assign LT = LT_internal ^ INVERSE_OUT;

endmodule
~~~

---

## Step 4: Functional Simulation

### 4.1 Simulation Method

The testbenches enumerate every possible input combination with a 2 ns interval between test vectors. Each testbench also checks the observed outputs automatically and prints PASS when no mismatch is found.

The simulations were compiled and executed with Icarus Verilog. The following waveform and CSV files were generated:

| Task | Testbench | Waveform | CSV data |
|---|---|---|---|
| Full adder | task1/tb_adder.v | task1/wave_adder.vcd | task1/wave_adder.csv |
| Comparator | task2/tb_cmp.v | task2/wave_cmp.vcd | task2/wave_cmp.csv |

The VCD files record time in picoseconds. The tables below convert the timestamps to nanoseconds and retain only the top-level input and output signals.

### 4.2 Task 1 Results

Simulation parameters: INVERSE_INPUT = 1 and INVERSE_OUT = 1.

| Time (ns) | A | B | C | O0 | carry |
|---:|:-:|:-:|:-:|:-:|:-:|
| 0  | 0 | 0 | 0 | 0 | 0 |
| 2  | 0 | 0 | 1 | 1 | 0 |
| 4  | 0 | 1 | 0 | 1 | 0 |
| 6  | 0 | 1 | 1 | 0 | 1 |
| 8  | 1 | 0 | 0 | 1 | 0 |
| 10 | 1 | 0 | 1 | 0 | 1 |
| 12 | 1 | 1 | 0 | 0 | 1 |
| 14 | 1 | 1 | 1 | 1 | 1 |

All eight input combinations passed the automatic checks.

### 4.3 Task 2 Results

Simulation parameters: INVERSE_INPUT = 1 and INVERSE_OUT = 1.

| Time (ns) | A | B | GT | EQ | LT |
|---:|:-:|:-:|:-:|:-:|:-:|
| 0 | 0 | 0 | 1 | 0 | 1 |
| 2 | 0 | 1 | 0 | 1 | 1 |
| 4 | 1 | 0 | 1 | 1 | 0 |
| 6 | 1 | 1 | 1 | 0 | 1 |

All four input combinations passed the automatic checks.

The values in this table are external pin levels. With active-low LEDs, a value of 0 indicates the selected comparison result. For example, at 2 ns the GT output is low, while at 4 ns the LT output is low. This is consistent with the inverted switch inputs used by the internal comparison logic.

---

## Step 5: Timing Analysis

Neither design contains a clocked path, so setup time, hold time, and maximum clock frequency do not apply to the functional model.

The continuous assignments in the Verilog source have no explicit delay. Therefore, functional simulation only verifies logical correctness and does not represent the physical propagation delay through the FPGA. The actual input-to-output delay must be obtained from the post-fit timing report after synthesis, placement, and routing in Quartus.

Both circuits have short combinational paths:

- The full-adder sum path contains XOR logic.
- The full-adder carry path contains AND-OR majority logic.
- The comparator outputs are generated by one-bit comparison logic.

The functional simulation completed without a logical mismatch. Timing compliance must be checked separately with the post-fit timing report.

---

## Conclusion

The one-bit full adder and one-bit magnitude comparator were implemented as parameterized combinational Verilog modules. Active-low input and output interfaces are supported without changing the core logic. Exhaustive functional simulation covered all 12 possible input combinations, and both self-checking testbenches completed with zero errors.


##want your csv/vcd? base64 is here
adder_vcd

JGRhdGUKCVN1biBPY3QgMTEgMjA6MDI6MTkgMjAyNgokZW5kCiR2ZXJzaW9uCglJY2FydXMgVmVy
aWxvZwokZW5kCiR0aW1lc2NhbGUKCTFwcwokZW5kCiRzY29wZSBtb2R1bGUgdGJfYWRkZXIgJGVu
ZAokdmFyIHdpcmUgMSAhIGNhcnJ5ICRlbmQKJHZhciB3aXJlIDEgIiBPMCAkZW5kCiR2YXIgcmVn
IDEgIyBBICRlbmQKJHZhciByZWcgMSAkIEIgJGVuZAokdmFyIHJlZyAxICUgQyAkZW5kCiR2YXIg
aW50ZWdlciAzMiAmIGVycm9ycyBbMzE6MF0gJGVuZAokc2NvcGUgbW9kdWxlIHRlc3QgJGVuZAok
dmFyIHdpcmUgMSAjIEEgJGVuZAokdmFyIHdpcmUgMSAkIEIgJGVuZAokdmFyIHdpcmUgMSAlIEMg
JGVuZAokdmFyIHdpcmUgMSAnIE8wX2ludGVybmFsICRlbmQKJHZhciB3aXJlIDEgKCBjYXJyeV9p
bnRlcm5hbCAkZW5kCiR2YXIgd2lyZSAxICEgY2FycnkgJGVuZAokdmFyIHdpcmUgMSAiIE8wICRl
bmQKJHZhciB3aXJlIDEgKSBDX2ludGVybmFsICRlbmQKJHZhciB3aXJlIDEgKiBCX2ludGVybmFs
ICRlbmQKJHZhciB3aXJlIDEgKyBBX2ludGVybmFsICRlbmQKJHZhciBwYXJhbWV0ZXIgMzIgLCBJ
TlZFUlNFX0lOUFVUICRlbmQKJHZhciBwYXJhbWV0ZXIgMzIgLSBJTlZFUlNFX09VVCAkZW5kCiR1
cHNjb3BlICRlbmQKJHVwc2NvcGUgJGVuZAokZW5kZGVmaW5pdGlvbnMgJGVuZAokY29tbWVudCBT
aG93IHRoZSBwYXJhbWV0ZXIgdmFsdWVzLiAkZW5kCiRkdW1wYWxsCmIxIC0KYjEgLAokZW5kCiMw
CiRkdW1wdmFycwoxKwoxKgoxKQoxKAoxJwpiMCAmCjAlCjAkCjAjCjAiCjAhCiRlbmQKIzIwMDAK
MSIKMCcKMCkKMSUKIzQwMDAKMSkKMCoKMCUKMSQKIzYwMDAKMSEKMCgKMCIKMScKMCkKMSUKIzgw
MDAKMCEKMSIKMSgKMCcKMSkKMSoKMCsKMCUKMCQKMSMKIzEwMDAwCjEhCjAiCjAoCjEnCjApCjEl
CiMxMjAwMAoxKQowKgowJQoxJAojMTQwMDAKMSIKMCcKMCkKMSUKIzE2MDAwCg==

adder_csv
VGltZSx0Yl9hZGRlci5jYXJyeSx0Yl9hZGRlci5PMCx0Yl9hZGRlci5BLHRiX2FkZGVyLkIsdGJf
YWRkZXIuQyx0Yl9hZGRlci5lcnJvcnNbMzE6MF0sdGJfYWRkZXIudGVzdC5BLHRiX2FkZGVyLnRl
c3QuQix0Yl9hZGRlci50ZXN0LkMsdGJfYWRkZXIudGVzdC5PMF9pbnRlcm5hbCx0Yl9hZGRlci50
ZXN0LmNhcnJ5X2ludGVybmFsLHRiX2FkZGVyLnRlc3QuY2FycnksdGJfYWRkZXIudGVzdC5PMCx0
Yl9hZGRlci50ZXN0LkNfaW50ZXJuYWwsdGJfYWRkZXIudGVzdC5CX2ludGVybmFsLHRiX2FkZGVy
LnRlc3QuQV9pbnRlcm5hbCx0Yl9hZGRlci50ZXN0LklOVkVSU0VfSU5QVVQsdGJfYWRkZXIudGVz
dC5JTlZFUlNFX09VVA0KMCwwLDAsMCwwLDAsMCwwLDAsMCwxLDEsMCwwLDEsMSwxLDEsMQ0KMjAw
MCwwLDEsMCwwLDEsMCwwLDAsMSwwLDEsMCwxLDAsMSwxLDEsMQ0KNDAwMCwwLDEsMCwxLDAsMCww
LDEsMCwwLDEsMCwxLDEsMCwxLDEsMQ0KNjAwMCwxLDAsMCwxLDEsMCwwLDEsMSwxLDAsMSwwLDAs
MCwxLDEsMQ0KODAwMCwwLDEsMSwwLDAsMCwxLDAsMCwwLDEsMCwxLDEsMSwwLDEsMQ0KMTAwMDAs
MSwwLDEsMCwxLDAsMSwwLDEsMSwwLDEsMCwwLDEsMCwxLDENCjEyMDAwLDEsMCwxLDEsMCwwLDEs
MSwwLDEsMCwxLDAsMSwwLDAsMSwxDQoxNDAwMCwxLDEsMSwxLDEsMCwxLDEsMSwwLDAsMSwxLDAs
MCwwLDEsMQ0K

cmp_vcd

JGRhdGUKCVN1biBPY3QgMTEgMjA6MDI6MTkgMjAyNgokZW5kCiR2ZXJzaW9uCglJY2FydXMgVmVy
aWxvZwokZW5kCiR0aW1lc2NhbGUKCTFwcwokZW5kCiRzY29wZSBtb2R1bGUgdGJfY21wICRlbmQK
JHZhciB3aXJlIDEgISBMVCAkZW5kCiR2YXIgd2lyZSAxICIgR1QgJGVuZAokdmFyIHdpcmUgMSAj
IEVRICRlbmQKJHZhciByZWcgMSAkIEEgJGVuZAokdmFyIHJlZyAxICUgQiAkZW5kCiR2YXIgaW50
ZWdlciAzMiAmIGVycm9ycyBbMzE6MF0gJGVuZAokc2NvcGUgbW9kdWxlIHRlc3QgJGVuZAokdmFy
IHdpcmUgMSAkIEEgJGVuZAokdmFyIHdpcmUgMSAlIEIgJGVuZAokdmFyIHdpcmUgMSAnIEVRX2lu
dGVybmFsICRlbmQKJHZhciB3aXJlIDEgKCBMVF9pbnRlcm5hbCAkZW5kCiR2YXIgd2lyZSAxICEg
TFQgJGVuZAokdmFyIHdpcmUgMSApIEdUX2ludGVybmFsICRlbmQKJHZhciB3aXJlIDEgIiBHVCAk
ZW5kCiR2YXIgd2lyZSAxICMgRVEgJGVuZAokdmFyIHdpcmUgMSAqIEJfaW50ZXJuYWwgJGVuZAok
dmFyIHdpcmUgMSArIEFfaW50ZXJuYWwgJGVuZAokdmFyIHBhcmFtZXRlciAzMiAsIElOVkVSU0Vf
SU5QVVQgJGVuZAokdmFyIHBhcmFtZXRlciAzMiAtIElOVkVSU0VfT1VUICRlbmQKJHVwc2NvcGUg
JGVuZAokdXBzY29wZSAkZW5kCiRlbmRkZWZpbml0aW9ucyAkZW5kCiRjb21tZW50IFNob3cgdGhl
IHBhcmFtZXRlciB2YWx1ZXMuICRlbmQKJGR1bXBhbGwKYjEgLQpiMSAsCiRlbmQKIzAKJGR1bXB2
YXJzCjErCjEqCjApCjAoCjEnCmIwICYKMCUKMCQKMCMKMSIKMSEKJGVuZAojMjAwMAoxIwowIgow
JwoxKQowKgoxJQojNDAwMAowIQoxIgoxKAoxKgowKQowKwowJQoxJAojNjAwMAowIwoxIQoxJwow
KAowKgoxJQojODAwMAo=

cmp_csv

VGltZSx0Yl9jbXAuTFQsdGJfY21wLkdULHRiX2NtcC5FUSx0Yl9jbXAuQSx0Yl9jbXAuQix0Yl9j
bXAuZXJyb3JzWzMxOjBdLHRiX2NtcC50ZXN0LkEsdGJfY21wLnRlc3QuQix0Yl9jbXAudGVzdC5F
UV9pbnRlcm5hbCx0Yl9jbXAudGVzdC5MVF9pbnRlcm5hbCx0Yl9jbXAudGVzdC5MVCx0Yl9jbXAu
dGVzdC5HVF9pbnRlcm5hbCx0Yl9jbXAudGVzdC5HVCx0Yl9jbXAudGVzdC5FUSx0Yl9jbXAudGVz
dC5CX2ludGVybmFsLHRiX2NtcC50ZXN0LkFfaW50ZXJuYWwsdGJfY21wLnRlc3QuSU5WRVJTRV9J
TlBVVCx0Yl9jbXAudGVzdC5JTlZFUlNFX09VVA0KMCwxLDEsMCwwLDAsMCwwLDAsMSwwLDEsMCwx
LDAsMSwxLDEsMQ0KMjAwMCwxLDAsMSwwLDEsMCwwLDEsMCwwLDEsMSwwLDEsMCwxLDEsMQ0KNDAw
MCwwLDEsMSwxLDAsMCwxLDAsMCwxLDAsMCwxLDEsMSwwLDEsMQ0KNjAwMCwxLDEsMCwxLDEsMCwx
LDEsMSwwLDEsMCwxLDAsMCwwLDEsMQ0K

## 免责声明
本md偏重度使用Chatgpt，ai味可能超标，前半段技术可行性是翻译来的，难免也有ai味
但是我并不认为一个优秀的fpga工程师需要完美掌握md语法

