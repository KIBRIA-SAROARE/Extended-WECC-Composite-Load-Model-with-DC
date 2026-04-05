# Extended WECC Composite Load Model with Data Center Load


This repository extends the [WECC Composite Load Model (CLM)](https://www.wecc.org/) with a **data center (DC) composite load component** that captures IT load behind UPS, cooling load with motor/VFD split, and AI workload variability. The model is implemented in positive-sequence **phasor mode** in MATLAB/Simulink R2023b using Simscape Electrical blocks.


## Table of Contents

- [Overview](#overview)
- [Model Architecture](#model-architecture)
- [Repository Structure](#repository-structure)
- [Getting Started](#getting-started)
- [Model Components](#model-components)
- [Running Simulations](#running-simulations)
- [Results](#results)
- [Key Findings](#key-findings)
- [Parameters](#parameters)
  

## Overview

The WECC Composite Load Model is the industry standard for representing aggregate load behavior in power system transient stability studies. It captures Fault-Induced Delayed Voltage Recovery (FIDVR) caused by stalling of residential single-phase A/C compressor motors. However, the rapid growth of hyperscale AI data centers — projected to consume 8–12% of U.S. electricity by 2030 — introduces load characteristics that existing models cannot represent.

This project adds a **DC Composite Load Model** alongside the standard WECC CLM components (Motors A–D, Electronic Load, Static Load) to study how AI data center workloads interact with FIDVR phenomena.

### What makes data center loads different?

| Characteristic | Traditional Load (WECC CLM) | Data Center (This Work) |
|---|---|---|
| Fault behavior | Stays on grid | UPS isolates IT load from grid |
| Post-fault | Continuous recovery | **Load rebound** when UPS returns to grid |
| Power variability | Seasonal/diurnal | GPU workload-dependent (seconds-scale) |
| Cooling | Residential A/C | Industrial chillers + VFDs |
| Grid visibility during fault | Partial | Zero (battery-backed) |



## Model Architecture

![Model Architecture](Figures/Extended CPLD Architecture)

The extended model connects to the standard WECC CLM load bus and comprises three sub-components:

1. **IT Load + UPS** (60% of P_dc): Server/GPU load with static transfer switch, battery backup, and diesel generator fallback. Implements a three-state machine (Grid → Battery → Diesel → Grid).

2. **Cooling Load** (30% of P_dc): Split between motor-driven chillers (60%, susceptible to stalling) and VFD-driven units (40%, ride-through capable). Includes thermal relay protection.

3. **Auxiliary Load** (10% of P_dc): Lighting, networking, and office equipment modeled as constant impedance.

An **AI Workload Profile Generator** produces three distinct power demand patterns:
- **Training**: 95% sustained utilization with periodic checkpoint dips and GPU synchronization oscillations
- **Inference**: 45% base with multi-frequency bursty patterns from user queries
- **Idle**: 15% baseline housekeeping



## Repository Structure

```
Extended-WECC-Composite-Load-Model-with-DC/
├── compositeload.slx          # Main Simulink model (R2023b)
├── plot_compare.m             # MATLAB script for comparison plots and metrics
├── mode_comparison.csv        # Computed metrics table for three workload modes
├── Training.mat               # Simulation output — training mode
├── Inference.mat              # Simulation output — inference mode
├── IDLE.mat                   # Simulation output — idle mode
├── Figures/                   # Generated figures for the paper
│   ├── Extended CPLD Architecture.png
│   └── ...                    # FIDVR, oscillation, comparison plots
└── README.md
```



## Getting Started

### Prerequisites

- MATLAB R2023b (or later)
- Simulink
- Simscape Electrical (Specialized Power Systems)

### Installation

```bash
git clone https://github.com/KIBRIA-SAROARE/Extended-WECC-Composite-Load-Model-with-DC.git
cd Extended-WECC-Composite-Load-Model-with-DC
```

### Quick Start

1. Open MATLAB R2023b
2. Navigate to the repository folder
3. Open the Simulink model:
   ```matlab
   open_system('compositeload.slx')
   ```
4. Verify the `powergui` block is set to **Phasor** mode at 60 Hz
5. Set simulation stop time (e.g., 20 s for quick test, 50 s for full FIDVR)
6. Run the simulation



## Model Components

### Base WECC CLM (100 MW)

| Component | Block Type | Fraction | Power | Torque |
|---|---|---|---|---|
| Motor A | Asynchronous Machine (pu) | 0.1462 | 14.62 MW | Constant (e_trq = 0) |
| Motor B | Asynchronous Machine (pu) | 0.1472 | 14.72 MW | Quadratic (e_trq = 2) |
| Motor C | Asynchronous Machine (pu) | 0.0365 | 3.65 MW | Quadratic (e_trq = 2) |
| Motor D | Dynamic Load + MATLAB Fcn | 0.3670 | 36.70 MW | Performance-based |
| Electronic | Dynamic Load + MATLAB Fcn | 0.1063 | 10.63 MW | Voltage-dependent |
| Static (Z) | Three-Phase RLC Load | — | 10.96 MW | Constant impedance |
| Static (I) | Three-Phase RLC Load | — | 8.72 MW | Constant current |

### DC Composite Load (100–500 MW)

| Sub-component | Fraction | Model Type | Key Feature |
|---|---|---|---|
| IT + UPS | 60% | MATLAB Function → Dynamic Load | UPS ride-through, load rebound |
| Cooling (Motor) | 18% | Stall model in MATLAB Function | Thermal relay, stall at V < 0.55 pu |
| Cooling (VFD) | 12% | Constant power to V = 0.5 pu | Ride-through capability |
| Auxiliary | 10% | Constant impedance | V² characteristic |

### Network

| Element | Rating | Key Parameter |
|---|---|---|
| Three-Phase Source | 220 kV | 10 GVA short-circuit level |
| Substation Transformer | 800 MVA | x_xf = 0.08 pu |
| Feeder Equivalent | π-section | R_fdr + jX_fdr |
| Fault | 3-phase | R_f = 1.0 Ω, t = 4.0–4.6 s |

### Solver Configuration

| Setting | Value |
|---|---|
| Simulation type | Phasor (60 Hz) |
| Solver | Fixed-step, ode3 |
| Step size | 5×10⁻⁴ s |
| MATLAB Function sample time | 1×10⁻³ s |
| Dynamic Load filtering | 0.1 s |



## Running Simulations

### Single Mode Simulation

1. In the Simulink model, locate the **mode selector** Constant block connected to the AI workload generator
2. Set its value:
   - `1` = Training
   - `2` = Inference  
   - `3` = Idle
3. Set the **P_dc** Constant block to desired DC size (e.g., `200` for 200 MW)
4. Run the simulation
5. Data is logged to workspace via `To Workspace` blocks

### Batch Comparison (Three Modes)

After running all three modes and saving the outputs:

```matlab
% Save simulation outputs after each run
% Mode 1: save('Training.mat', 'out')
% Mode 2: save('Inference.mat', 'out')
% Mode 3: save('IDLE.mat', 'out')

% Run comparison analysis
plot_compare
```

This generates:
- Overlay plots (full timeline, zoomed 50 ms and 100 ms)
- FIDVR recovery comparison
- Metrics table (console, CSV, and LaTeX)
- Bar chart of key oscillation metrics



## Results

### FIDVR Response

The model successfully captures the FIDVR phenomenon:

- **Pre-fault**: Steady-state at ~0.97 pu voltage, total load matching rated power
- **During fault** (t = 4.0–4.6 s): Voltage drops to ~0.1 pu, Motor D stalls, UPS transfers IT load to battery
- **Post-fault**: Motor D draws high stall current (G_stall × V²), voltage stays depressed
- **Recovery** (t = 5–20 s): Thermal relay gradually trips stalled Motor D, voltage recovers

### Workload Mode Comparison

| Metric | Training | Inference | Idle |
|---|---|---|---|
| V peak-to-peak (first 100 ms) | ~0.065 pu | ~0.045 pu | ~0.030 pu |
| P peak-to-peak (first 100 ms) | ~370 MW | ~525 MW | ~200 MW |
| UPS hunting cycles | 3–4 | 2–3 | 1 |
| FIDVR duration | ~15.2 s | ~15.1 s | ~15.0 s |
| Settling time | ~45 ms | ~40 ms | ~30 ms |



## Key Findings

### Finding 1: FIDVR Duration is Workload-Independent

Despite significant differences in AI workload profiles, the overall FIDVR recovery time is nearly identical across all three modes. The UPS battery backup isolates the IT load from the grid during the fault, making the voltage recovery trajectory dependent only on the Motor D thermal relay dynamics.

### Finding 2: Post-Fault Oscillations are Workload-Dependent

The first 50–100 ms after fault clearance shows dramatically different oscillatory behavior:

- **Training mode** produces the largest voltage oscillations (0.065 pu peak-to-peak) due to a **UPS hunting phenomenon**: the ~100 MW IT load rebound causes a secondary voltage dip below the UPS trip threshold, triggering repeated transfer cycles
- **Idle mode** produces smooth recovery with minimal oscillation since only ~19 MW rebounds
- **Inference mode** shows irregular oscillations reflecting its bursty workload character

### Finding 3: Load Rebound Scales with DC Size

The IT load rebound magnitude is approximately 0.57 × P_dc (reflecting F_it × P_base_train). At 300+ MW data centers, the rebound exceeds 170 MW, sustaining 5+ UPS hunting cycles that could interfere with protection relay coordination.



## Parameters

### DC Composite Load Parameters



#### System-Level

| Parameter | Description | Value |
|---|---|---|
| P_dc | Data center rated power | 100–500 MW |
| F_it | IT load fraction | 0.60 |
| F_cool | Cooling load fraction | 0.30 |
| F_aux | Auxiliary load fraction | 0.10 |
| F_vfd | VFD share of cooling | 0.40 |

#### UPS

| Parameter | Description | Value |
|---|---|---|
| V_ups,trip | Battery transfer threshold | 0.90 pu |
| V_ups,return | Grid return threshold | 0.95 pu |
| T_ups,batt | Battery hold-up time | 30 s |
| T_diesel | Diesel generator start time | 12 s |
| T_ups,xfer | Static switch transfer time | 0.004 s |
| PF_it | IT load power factor | 0.95 |

#### Cooling

| Parameter | Description | Value |
|---|---|---|
| R_stall | Stall resistance | 0.10 pu |
| X_stall | Stall reactance | 0.12 pu |
| V_stall | Stall voltage threshold | 0.55 pu |
| T_stall | Stall confirmation delay | 0.05 s |
| V_rst | Restart voltage | 0.90 pu |
| T_rst | Restart delay | 2.0 s |
| T_TH | Thermal time constant | 60 s |
| θ_th1 / θ_th2 | Thermal trip levels | 1.6 / 2.8 pu |
| PF_cool | Cooling power factor | 0.85 |

#### AI Workload Profiles

| Parameter | Training | Inference | Idle |
|---|---|---|---|
| Base utilization | 0.95 | 0.45 | 0.15 |
| Variability | Checkpoint dips + sync oscillation | Multi-freq bursts | None |
| Cooling coupling | 0.6 + 0.4 × P_ai | 0.6 + 0.4 × P_ai | 0.66 |



### WECC CLM Parameters

Motor and load parameters follow the standard WECC CLM specification as documented in:
- Kosterev et al., "Load modeling in power system studies: WECC progress update," IEEE PES General Meeting, 2008
- Harigovind M., "Modelling of WECC Composite Load Model," CUSAT / IIT Bombay, 2019



## Acknowledgments

- WECC Load Modeling Task Force for the composite load model specification
- Prof. Zakir Hussain Rather (IIT Bombay) and Harigovind M. for the foundational WECC CLM implementation reference
- MathWorks for Simscape Electrical toolbox documentation

[Note: This file is written with the help of generative AI]
