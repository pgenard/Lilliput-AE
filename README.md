# 🔐 Lilliput-AE Basic Verilog Design ~1000 LoCs.

## About

Exploring **Cryptography** and **Hardware Design**.

This repository contains a Verilog RTL implementation of the **Lilliput-TBC-128** tweakable block cipher and the **SCT-2** mode authenticated encryption construction.

The current development and verification process is focused exclusively on RTL simulation.

## Why Lilliput?

**Lilliput** is a lightweight tweakable block cipher designed for resource-constrained environments.

**Lilliput-TBC-128**: underlying 128-bit tweakable block cipher.

**SCT-2**: authenticated encryption construction built around the tweakable block cipher.

## Project Files

| File	                | Purpose                                        |
|-----------------------|------------------------------------------------|
| lilliput_sbox.v	| Lilliput substitution box                      |
| lilliput_round.v	| TBC round transformation                       |
| lilliput_tweakey.v	| Tweakey processing                             |
| lilliput_tbc_128.v	| 128-bit tweakable block cipher                 |
| lilliput_sct2.v	| SCT-2 authenticated encryption controller      |
| tb_lilliput_sct2.v	| SCT-2 simulation testbench                     |
| expected_sct2_zero.tv	| Expected results for the zero reference vector |
| random_tests.tv       | Randomized TBC reference test cases            |
| random_sct2_tests.tv	| Randomized SCT-2 reference test cases          |

## Testing

The complete RTL design is verified using **Icarus Verilog**.

The verification strategy uses reference test vectors to compare the simulated ciphertext and authentication tag against expected results.

### Compilation

#### Lilliput-TBC-128

```bash
iverilog -g2012 -Wall -o lilliput_tbc \
                         lilliput_sbox.v \
			 lilliput_tweakey.v \
			 lilliput_round.v \
			 lilliput_tbc_128.v \
			 tb_lilliput_tbc_128.v
```

#### Lilliput-SCT-2

```bash
iverilog -g2012 -o lilliput_sct2 \
                   lilliput_sbox.v \
		   lilliput_round.v \
		   lilliput_tweakey.v \
		   lilliput_tbc_128.v \
		   lilliput_sct2.v \
		   tb_lilliput_sct2.v
```

### Simulation

```bash
vvp lilliput_tbc
```

```bash
vvp lilliput_sct2
```

### Verification

#### Lilliput-SCT-2

```bash
----------------------------------------
 Lilliput-AE SCT-2
----------------------------------------
[...]
PASS: RANDOM 01
PASS: RANDOM 02
...
PASS: RANDOM 100

----------------------------------------
 Verification Summary
----------------------------------------

Total tests : 101
Passed      : 101
Failed      : 0

RESULT: ALL TESTS PASSED
----------------------------------------

```

## Tools

- **Verilog** HDL.
- **Icarus Verilog**.
- **GTKWave** (optional waveform inspection).
- Linux command line.

No FPGA board is required to run the simulation.

## Author
**Pierre GENARD**

### Happy Hacking! 🔐
