# LED Brightness Control Peripheral — FPGA (DE10-Lite)

A custom VHDL peripheral for the DE10-Lite FPGA board that extends basic LED control with PWM brightness modulation, gamma correction, and configurable flash modes. Built as a peripheral for the SCOMP simple computer architecture in Georgia Tech's ECE 2031 (Digital Design Lab).

## Features

- **16 discrete brightness levels** per LED via 8-bit PWM
- **Gamma correction** — squares the 4-bit brightness input for perceptually linear brightness steps
- **Flash mode** — configurable per-LED flashing with adjustable brightness
- **Individual LED control** — 10-bit mask allows targeting any combination of the 10 onboard LEDs in a single write
- **Memory-mapped I/O** — single 16-bit register write controls state, brightness, and LED selection

## Register Format

Each write to the peripheral uses a 16-bit word:

```
[15:14]  State bits     → 00 = OFF, 10 = ON (PWM), 11 = ON (flash + PWM), 01 = reserved
[13:10]  Brightness     → 0–15 (gamma-corrected internally: value² maps to 0–225 PWM range)
[9:0]    LED mask       → each bit selects which LED(s) to update
```

**Example:** `0xBC05` → state `10` (ON), brightness `15`, LEDs 0 and 2 selected.

## Architecture

The peripheral connects to the SCOMP processor via chip-select and write-enable signals at I/O address `0x020`:

```
SCOMP CPU ──► IO_DECODER ──► LEDController ──► DE10-Lite LEDs[9:0]
                (addr 0x020)     (CS, WRITE_EN)
```

Internally, `LEDController.vhd` runs three concurrent processes:

| Process | Function |
|---|---|
| **WRITE_PROCESS** | Parses the 16-bit register write — extracts state, gamma-corrects brightness (input²), and updates per-LED state/brightness arrays |
| **PWM_PROCESS** | Free-running 8-bit counter (0–255) at system clock rate for duty-cycle modulation |
| **FLASH_PROCESS** | Slower counter toggling a flash state signal for LED blinking mode |
| **LED_OUTPUT_PROCESS** | Combines state, PWM compare, and flash state to drive each LED output pin |

## Repository Contents

```
├── README.md
├── src/
│   ├── LEDController.vhd       # Peripheral VHDL — PWM, gamma correction, flash logic
│   └── IO_DECODER.vhd          # Address decoder (active at 0x020)
├── demo/
│   └── NewLEDsTest.asm         # SCOMP assembly — Christmas light wave + flash demo
├── bitstream/
│   └── SCOMP-1.sof             # Compiled Quartus bitstream for DE10-Lite
└── docs/
    └── ProjectSummary.pdf       # Project write-up with VHDL code walkthrough
```

## Demo

`NewLEDsTest.asm` runs two demo modes on the DE10-Lite:

**Wave mode** (switches off) — A brightness wave sweeps back and forth across the 10 LEDs. Each LED's brightness is computed as a function of its distance from a moving center point, creating a smooth trailing effect using the gamma-corrected PWM.

**Flash mode** (any switch on) — Even and odd LEDs alternate flashing at maximum brightness, demonstrating the independent flash control per LED.

[![Demo Video](https://img.youtube.com/vi/W9JOOEhFge8/maxresdefault.jpg)](https://youtu.be/W9JOOEhFge8)

## How It Works

**PWM brightness control:** An 8-bit counter increments every clock cycle. For each LED, if the counter value is less than that LED's stored brightness, the output is high — otherwise low. At the system clock rate, this cycling is invisible to the human eye, producing a perceived dimming effect.

**Gamma correction:** Human vision perceives brightness logarithmically, so linear PWM steps look uneven (the jump from 1→2 looks huge, while 14→15 is barely noticeable). The peripheral squares the 4-bit input (`brightness² = 0, 1, 4, 9, ... 225`) before comparing against the PWM counter, producing perceptually uniform brightness steps.

## Technologies

VHDL · Intel Quartus Prime · DE10-Lite (Cyclone V) · SCOMP Architecture · PWM · FPGA

## Course

ECE 2031 — Digital Design Lab, Georgia Tech (Spring 2025)
