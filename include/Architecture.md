# RISC-V SoC with Configurable NTT Accelerator for Post-Quantum Cryptography
## System Specification — Phase 1
### Version 1.0

---

# 1. Project Overview

The project implements a RISC-V based SoC containing a configurable
Number Theoretic Transform (NTT) accelerator targeted at
Post-Quantum Cryptography (PQC) workloads.

The accelerator is designed to support configurable NTT sizes and
runtime modulus selection for workloads associated with ML-KEM
(Kyber) and ML-DSA (Dilithium).

The design target is an end-to-end ASIC implementation:

RTL
→ Simulation/Verification
→ Synthesis
→ Static Timing Analysis (STA)
→ Floorplanning
→ Power Planning
→ Placement
→ Clock Tree Synthesis (CTS)
→ Routing
→ DRC/LVS
→ GDSII


# 2. Current Project Architecture

The SoC consists of:

1. RISC-V processor
2. Instruction Memory Interface
3. Data Memory Interface
4. System SRAM
5. Control/Configuration Registers
6. Single-channel DMA controller
7. NTT input/output buffers
8. Configurable NTT accelerator
9. Modular arithmetic units
10. Twiddle-factor storage


# 3. RISC-V Core

Core:
    PicoRV32

CPU architecture:
    32-bit RISC-V

The PicoRV32 core is used as an existing/proven processor RTL
rather than designing a CPU from scratch.

The CPU is responsible for:

- Configuring the NTT accelerator
- Configuring the DMA
- Starting NTT operations
- Monitoring accelerator status
- Reading/writing system data


# 4. RISC-V Memory Interfaces

The processor interface is divided into:

    Instruction Memory Interface
    Data Memory Interface

The design does NOT use separate conventional I-cache/D-cache blocks
in the current architecture.

The interfaces provide access to the required instruction and data
memory resources of the SoC.


# 5. NTT Accelerator

The accelerator performs the Number Theoretic Transform.

Supported NTT sizes:

    256-point NTT
    512-point NTT

NTT architecture:

    Radix-2 Cooley-Tukey NTT

Maximum number of stages:

    log2(512) = 9 stages

Therefore:

    256-point NTT → 8 stages
    512-point NTT → 9 stages


# 6. Supported Moduli

The accelerator supports runtime selection between two moduli:

    Kyber:
        q = 3,329

    Dilithium:
        q = 8,380,417

Modulus selection is controlled through a configuration register.

Conceptually:

    MODULUS_SEL = 0 → q = 3329
    MODULUS_SEL = 1 → q = 8380417


# 7. Supported NTT Configurations

The hardware supports:

    256-point NTT with q = 3,329
    256-point NTT with q = 8,380,417
    512-point NTT with q = 3,329
    512-point NTT with q = 8,380,417

Important:

The accelerator is a configurable NTT engine supporting these
size/modulus combinations.

The supported combinations should not automatically be interpreted
as the exact parameter set of a standardized ML-KEM or ML-DSA
operation.


# 8. Coefficient Width

Largest supported modulus:

    q = 8,380,417

Maximum reduced coefficient:

    q - 1 = 8,380,416

Since:

    8,380,416 < 2^24

the coefficient requires 24 bits.

Decision:

    NTT coefficient width = 24 bits

Both modulus modes use the same 24-bit coefficient datapath.

The Kyber mode does NOT use a separate 12-bit datapath.


# 9. Internal NTT Datapath

NTT coefficient width:

    24 bits

Internal NTT datapath width:

    24 bits

Both supported moduli use the same datapath width.

Reason:

Using a common 24-bit datapath simplifies:

- RTL
- datapath selection
- verification
- timing analysis
- integration
- physical implementation


# 10. Modular Addition

The modular addition operation is:

    (A + B) mod q

Since:

    A < q
    B < q

the maximum sum is less than:

    2q

For the largest modulus:

    2 × 8,380,417 = 16,760,834

which requires at most 25 bits.

Therefore:

    Modular addition intermediate width = 25 bits
    Modular addition output width       = 24 bits


# 11. Modular Subtraction

The modular subtraction operation is:

    (A - B) mod q

If:

    A >= B

then:

    result = A - B

If:

    A < B

then:

    result = A - B + q

Implementation therefore uses subtract-and-correct behavior.

Decision:

    Modular subtraction output width = 24 bits

A 25-bit intermediate representation may be used internally to
detect underflow/correction conditions.


# 12. Modular Multiplication

The required operation is:

    (A × B) mod q

Each operand is 24 bits.

Therefore:

    24-bit × 24-bit

produces:

    48-bit product

Decision:

    Multiplier input width  = 24 bits
    Multiplier output width = 48 bits

Architecture:

    A[23:0]
        |
        +------+
               |
               v
          24 × 24 Multiplier
               |
               v
          Product[47:0]
               |
               v
        Barrett Reduction
               |
               v
          Result[23:0]


# 13. Barrett Reduction

The modular multiplier uses:

    Barrett Reduction

Montgomery reduction is NOT used in the current architecture.

Reason for selecting Barrett reduction:

- Suitable for configurable modulus operation
- Supports runtime modulus switching
- Avoids a conventional division operation
- Straightforward to implement for the selected fixed moduli
- Suitable for the project's hardware architecture

Barrett reduction input:

    48 bits

Barrett reduction output:

    24 bits

The exact internal intermediate widths and optimized implementation
will be finalized during the detailed Barrett RTL design.

For a 48-bit input product:

    x = A × B

the implementation can use a Barrett constant of the form:

    μ = floor(2^k / q)

with the detailed value and implementation architecture to be
finalized during the arithmetic-unit design.


# 14. Modular Arithmetic Block

The NTT accelerator contains:

    Modular Adder
    Modular Subtractor
    Modular Multiplier
    Barrett Reduction Unit

These blocks form the arithmetic foundation used by the NTT butterfly.


# 15. NTT Butterfly

The fundamental radix-2 butterfly performs:

    T  = (B × W) mod q

    A' = (A + T) mod q

    B' = (A - T) mod q

where:

    A, B = input coefficients
    W    = twiddle factor
    q    = selected modulus


Conceptual datapath:

                  B
                  |
                  v
            Modular Multiplier
                  |
                  v
                  T
             +----+----+
             |         |
             v         v
          Mod Add   Mod Sub
             ^         ^
             |         |
             +----A----+

             |         |
             v         v
            A'        B'


# 16. Butterfly Arithmetic

The butterfly contains:

    24 × 24-bit multiplier
    Barrett reduction
    Modular adder
    Modular subtractor

The modular multiplier internally performs:

    B × W
       ↓
    48-bit product
       ↓
    Barrett reduction
       ↓
    T = (B × W) mod q


# 17. NTT Datapath

The NTT datapath consists conceptually of:

    NTT Controller
          |
          +-- Twiddle Factor Storage
          |
          +-- Butterfly
          |
          +-- Modular Arithmetic
          |
          +-- NTT Buffers


# 18. NTT Parallelism

Current initial architecture:

    One configurable butterfly datapath

The design is NOT initially based on multiple parallel butterfly
units.

Reason:

The primary goals are:

- Correctness
- Verification simplicity
- Reasonable area
- Manageable timing
- Realistic one-year student tape-out implementation


# 19. NTT Buffer Architecture

The current architecture uses two logical NTT buffers:

    Buffer A
    Buffer B

Each buffer stores:

    512 coefficients × 32 bits

Therefore:

    512 × 32 = 16,384 bits
                   = 2 KB

Each buffer:

    2 KB

Total NTT local buffer capacity:

    4 KB


# 20. Buffer Word Width

Although a coefficient requires only 24 bits, the NTT buffer uses:

    32-bit words

Each coefficient occupies one 32-bit word.

Conceptually:

    31                    24 23                    0
    +----------------------+-----------------------+
    |      unused/pad      | coefficient[23:0]    |
    +----------------------+-----------------------+


# 21. Kyber Coefficient Packing

The architecture does NOT pack two 12-bit Kyber coefficients into
one 32-bit word.

Instead:

    One coefficient = one 32-bit word

Reason:

- Simplifies DMA
- Simplifies RISC-V access
- Simplifies addressing
- Simplifies NTT buffer logic
- Avoids mode-dependent packing
- Simplifies verification


# 22. Ping-Pong Buffering

The current proposed NTT architecture uses ping-pong buffering.

For each NTT stage:

    Input buffer → Butterfly → Output buffer

Buffers alternate between stages.

For example:

    Stage 0:
        A → B

    Stage 1:
        B → A

    Stage 2:
        A → B

    Stage 3:
        B → A

    ...

For a 512-point NTT:

    Stage 0 → A to B
    Stage 1 → B to A
    Stage 2 → A to B
    Stage 3 → B to A
    Stage 4 → A to B
    Stage 5 → B to A
    Stage 6 → A to B
    Stage 7 → B to A
    Stage 8 → A to B

Therefore, with input initially in Buffer A, the final output is
in Buffer B for the 512-point transform.


IMPORTANT:
Ping-pong buffering is currently the proposed architecture but
has NOT yet been permanently frozen against an in-place NTT
alternative.

A final comparison between ping-pong and in-place architectures
will be performed before the memory architecture is permanently
frozen.


# 23. System SRAM

Current preliminary system SRAM size:

    16 KB

System SRAM is intended to contain:

- Program/data
- Input coefficients
- Output coefficients
- DMA source/destination data
- General SoC storage


IMPORTANT:
16 KB is currently a preliminary architectural choice and should
not yet be considered permanently frozen until the final memory map,
DMA behavior, and software requirements are established.


# 24. NTT Local Memory vs System SRAM

The architecture distinguishes between:

    System SRAM
        ↓
    DMA
        ↓
    NTT local buffers
        ↓
    NTT engine

System SRAM:

    16 KB (preliminary)

NTT local buffers:

    4 KB total

The NTT local buffers are dedicated to the transform datapath,
while system SRAM serves as the general SoC memory.


# 25. DMA Controller

The architecture contains:

    Single-channel DMA controller

The DMA is responsible for coefficient transfers between:

    System SRAM
          ↕
    NTT accelerator input/output buffer

The DMA is intended to reduce CPU involvement in bulk coefficient
transfers.

The maximum coefficient vector for the 512-point mode is:

    512 coefficients × 4 bytes
    = 2048 bytes
    = 2 KB


# 26. DMA Operations

The DMA must support:

    System SRAM → NTT input buffer

and:

    NTT output buffer → System SRAM

The DMA will use configuration information such as:

    Source Address
    Destination Address
    Transfer Length
    Control
    Status


# 27. DMA Channel Count

DMA channel count:

    1

This is intentionally constrained to a single channel to keep the
architecture realistic and verifiable for the project.


# 28. NTT Configuration

The NTT accelerator supports runtime configuration of:

    NTT size
    Modulus

NTT size:

    256
    512

Modulus:

    q = 3329
    q = 8380417


# 29. Configuration Registers

The control interface is expected to contain registers/functions
for:

    CONTROL
        START
        NTT_SIZE
        MODULUS_SEL

    STATUS
        BUSY
        DONE

DMA-related registers:

    DMA_SRC
    DMA_DST
    DMA_LENGTH
    DMA_CONTROL

Exact register addresses and bit positions are NOT YET FROZEN.


# 30. Proposed NTT Configuration Encoding

NTT size:

    NTT_SIZE = 01 → 256
    NTT_SIZE = 10 → 512
    00 and 11 → Reserved

Modulus:

    MODULUS_SEL = 0 → q = 3329
    MODULUS_SEL = 1 → q = 8380417


# 31. Clock Architecture

Initial architecture:

    Single synchronous clock domain

PicoRV32, DMA, NTT accelerator, control registers and memory
interfaces operate within the same primary clock domain.

Multiple clock domains are NOT currently planned.


# 32. Reset

A common system reset strategy will be used across the SoC.

The exact reset polarity and synchronous/asynchronous implementation
will be finalized based on the selected standard-cell library and
ASIC implementation flow.


# 33. System Data Flow

Typical operation:

    1. Input coefficients are stored in System SRAM.

    2. RISC-V configures:
           NTT size
           Modulus
           DMA parameters

    3. DMA transfers coefficients:
           System SRAM → NTT input buffer

    4. NTT controller starts the transform.

    5. NTT performs the required stages.

    6. Each butterfly uses modular arithmetic.

    7. Barrett reduction performs modular multiplication reduction.

    8. NTT output is stored in the NTT output buffer.

    9. DMA transfers results:
           NTT output buffer → System SRAM

    10. RISC-V detects completion and can access the results.


# 34. Complete High-Level Data Flow

                         PicoRV32
                             |
                    Configuration
                             |
                             v
                    Control Registers
                             |
                  +----------+----------+
                  |                     |
                  v                     v
                 DMA                 NTT Control
                  |                     |
                  v                     v
             System SRAM          NTT Accelerator
                  |                     |
                  |                     |
                  +-----> NTT Buffer ---+
                              |
                              v
                       NTT Butterfly
                              |
                     +--------+--------+
                     |        |        |
                     v        v        v
                  Mod Add  Mod Sub  Mod Mult
                                      |
                                      v
                               Barrett Reduction
                                      |
                                      v
                                  NTT Output
                                      |
                                      v
                                     DMA
                                      |
                                      v
                                 System SRAM


# 35. Team Structure

The project is divided into three primary RTL teams.

---

## Team 1 — Modular Arithmetic / NTT

Members:

    4

Responsibilities:

    Modular Addition
    Modular Subtraction
    Modular Multiplication
    Barrett Reduction Unit
    NTT Butterfly
    NTT Datapath
    NTT Controller
    Twiddle-Factor Storage
    256-point NTT support
    512-point NTT support
    Runtime modulus switching
    NTT-specific verification

The team is responsible for the complete computational core of
the configurable NTT accelerator.

Main hierarchy:

    Modular Arithmetic
          ↓
    Butterfly
          ↓
    NTT Datapath
          ↓
    NTT Controller
          ↓
    Configurable NTT Accelerator


---

## Team 2 — RISC-V / SoC

Members:

    3

Responsibilities:

    PicoRV32 integration
    Instruction Memory Interface
    Data Memory Interface
    SoC-level interconnection
    Control and configuration interface
    NTT accelerator control interface
    CPU-to-accelerator communication
    CPU-side software/firmware
    System-level integration
    RISC-V subsystem verification

The team is responsible for making the NTT accelerator programmable
and accessible from the RISC-V processor.

Main hierarchy:

    PicoRV32
        ↓
    Instruction/Data Interfaces
        ↓
    SoC Interconnect
        ↓
    Control/Configuration Interface
        ↓
    NTT Accelerator


---

## Team 3 — Memory / DMA

Members:

    3

Responsibilities:

    System SRAM
    NTT local memory
    NTT input/output buffers
    Memory addressing
    Memory interface
    Single-channel DMA controller
    SRAM ↔ NTT buffer transfers
    DMA control registers
    DMA status
    Transfer-length management
    Memory subsystem verification

The team is responsible for all data movement and memory resources
required by the SoC and NTT accelerator.

Main hierarchy:

    System SRAM
          ↓
        DMA
          ↓
    NTT Input Buffer
          ↓
    NTT Accelerator
          ↓
    NTT Output Buffer
          ↓
        DMA
          ↓
    System SRAM


---

# 36. Team Responsibility Boundaries

The three teams should have clear RTL ownership.

### Team 1 — Modular Arithmetic / NTT

Owns:

    Arithmetic → Butterfly → NTT

### Team 2 — RISC-V / SoC

Owns:

    CPU → SoC Interface → Control

### Team 3 — Memory / DMA

Owns:

    SRAM → DMA → NTT Buffers


The overall integration is:

                         ┌──────────────────┐
                         │     RISC-V       │
                         │      / SoC       │
                         │    Team 2        │
                         └────────┬─────────┘
                                  │
                           Control / Config
                                  │
                                  ▼
       ┌──────────────────────────┴──────────────────────────┐
       │                                                     │
       │                                                     │
       ▼                                                     ▼
┌──────────────────┐                                ┌──────────────────┐
│  Memory / DMA    │                                │ Modular / NTT    │
│     Team 3       │                                │      Team 1      │
│                  │                                │                  │
│ SRAM             │──── NTT Data ────────────────►│ NTT Accelerator  │
│ DMA              │                                │                  │
│ Input Buffer     │◄──── NTT Results ─────────────│ Butterfly        │
│ Output Buffer    │                                │ Modular Arithmetic│
└──────────────────┘                                │ Barrett          │
                                                    └──────────────────┘


# 37. Verification Responsibility

Verification is distributed among all three teams.

## Team 1 — Modular Arithmetic / NTT

Responsible for verifying:

    Modular Add
    Modular Sub
    Modular Mult
    Barrett Reduction
    Butterfly
    NTT
    256-point operation
    512-point operation
    Both supported moduli


## Team 2 — RISC-V / SoC

Responsible for verifying:

    PicoRV32 integration
    Instruction interface
    Data interface
    Register access
    NTT configuration
    Start/Busy/Done behavior
    CPU-to-accelerator communication


## Team 3 — Memory / DMA

Responsible for verifying:

    SRAM
    NTT buffers
    Address generation
    DMA transfers
    DMA control
    DMA status
    SRAM → NTT transfers
    NTT → SRAM transfers


## Cross-Team/System Verification

After the individual blocks are verified, all three teams participate
in system-level verification.

The complete flow is:

    RISC-V
       ↓
    Configure DMA/NTT
       ↓
    DMA
       ↓
    SRAM → NTT Buffer
       ↓
    NTT Accelerator
       ↓
    NTT Buffer
       ↓
    DMA
       ↓
    SRAM
       ↓
    RISC-V reads result


# 38. Team Interface Dependencies

The primary dependencies are:

    Team 1 ↔ Team 3

    NTT requires data from the Memory/DMA subsystem.

    Team 2 ↔ Team 3

    RISC-V configures and controls the DMA and accesses memory.

    Team 2 ↔ Team 1

    RISC-V configures and starts the NTT accelerator.

Therefore:

                 RISC-V / SoC
                     Team 2
                    /      \
                   /        \
                  ▼          ▼
          Memory / DMA    Modular / NTT
             Team 3         Team 1
                  \          /
                   \        /
                    ▼      ▼
                  Full SoC


# 39. Recommended Team Workflow

The teams should develop their RTL independently using frozen
interfaces.

Initial development:

    Team 1:
        Modular arithmetic
        ↓
        Butterfly
        ↓
        NTT

    Team 2:
        PicoRV32
        ↓
        SoC interface
        ↓
        Control registers

    Team 3:
        SRAM interface
        ↓
        DMA
        ↓
        NTT buffers


Integration:

    Team 1 + Team 3
        ↓
    NTT data path integration

    Team 2 + Team 3
        ↓
    CPU / DMA / Memory integration

    Team 2 + Team 1
        ↓
    CPU / NTT control integration

    All three teams
        ↓
    Full SoC integration
        ↓
    System verification


# 37. End-to-End Verification Flow

The final system should be verified through:

    RISC-V
       ↓
    Configure NTT
       ↓
    Configure DMA
       ↓
    DMA transfers input
       ↓
    NTT execution
       ↓
    NTT completion
       ↓
    DMA transfers output
       ↓
    RISC-V reads output
       ↓
    Compare against reference model


# 38. ASIC Implementation Target

The project is intended to progress through:

    RTL
      ↓
    Functional Simulation
      ↓
    Lint
      ↓
    Synthesis
      ↓
    Gate-Level Netlist
      ↓
    Static Timing Analysis
      ↓
    Floorplanning
      ↓
    Power Planning
      ↓
    Placement
      ↓
    Clock Tree Synthesis
      ↓
    Routing
      ↓
    DRC
      ↓
    LVS
      ↓
    GDSII


# 39. Primary Design Goals

The architecture prioritizes:

    1. Functional correctness
    2. Configurability
    3. Verifiability
    4. Reasonable area
    5. Synthesizability
    6. Timing closure
    7. Realistic one-year tape-out implementation


# 40. Current Architectural Novelty

The main architectural features are:

    1. RISC-V controlled NTT accelerator

    2. Configurable NTT size:
           256 / 512

    3. Runtime modulus switching:
           q = 3329
           q = 8380417

    4. Common 24-bit datapath for both moduli

    5. Barrett-based modular multiplication

    6. Single-channel DMA for coefficient movement

    7. Hardware acceleration of NTT operations
       instead of performing the transform entirely in software


# 41. Specifications That Are CURRENTLY FROZEN

The following are considered frozen at the current Phase 1 level:

    CPU:
        PicoRV32
        32-bit

    NTT:
        Radix-2 Cooley-Tukey
        256-point
        512-point
        Maximum 9 stages

    Moduli:
        q = 3329
        q = 8380417

    Coefficient:
        24 bits

    NTT datapath:
        24 bits

    Multiplier:
        24 × 24 bits
        48-bit product

    Modular arithmetic:
        Modular Add
        Modular Sub
        Modular Multiply
        Barrett Reduction

    Reduction:
        Barrett
        NOT Montgomery

    SRAM word:
        32 bits

    Coefficient storage:
        One coefficient per 32-bit word

    Kyber packing:
        No 12-bit coefficient packing

    DMA:
        Single channel

    DMA function:
        SRAM ↔ NTT buffer coefficient transfer

    Clock:
        Single clock domain

    NTT parallelism:
        One initial butterfly datapath

    Team structure:
        4 + 3 + 1


# 42. Specifications NOT YET PERMANENTLY FROZEN

The following still require architectural analysis:

    1. Ping-pong buffer vs in-place NTT

    2. Exact NTT memory architecture

    3. Exact SRAM port configuration

    4. Exact twiddle ROM organization

    5. Exact butterfly scheduling

    6. Address-generation architecture

    7. Exact NTT latency

    8. Throughput target

    9. Exact Barrett intermediate widths

    10. Barrett constant implementation

    11. Exact system SRAM size
        (16 KB is currently preliminary)

    12. Exact SoC memory map

    13. Exact control-register addresses

    14. Exact DMA register map

    15. Exact CPU-to-SoC interconnect

    16. Exact reset implementation

    17. Number and implementation of SRAM macros

    18. Final clock-frequency target

    19. Final area target

    20. Final power target


# 43. Important Design Rule

Do not begin full RTL implementation until the remaining architectural
items are resolved.

RTL should begin with individually defined interfaces for:

    Modular Arithmetic
    Barrett Reduction
    Butterfly
    NTT Controller
    Twiddle ROM
    NTT Buffer
    DMA
    Control Registers
    PicoRV32 Interface
    System SRAM


# 44. Current Architecture Summary

The proposed system is:

    32-bit PicoRV32
          |
          v
    SoC Control / Memory Interfaces
          |
       +--+------------------+
       |                     |
       v                     v
    System SRAM             DMA
                             |
                             v
                       NTT Buffers
                             |
                             v
                    Configurable NTT
                             |
                     +-------+-------+
                     |               |
                  256/512        q selection
                     |               |
                     +-------+-------+
                             |
                       NTT Butterfly
                             |
                  +----------+----------+
                  |          |          |
               Mod Add    Mod Sub    Mod Mult
                                      |
                                      v
                               Barrett Reduction
                                      |
                                      v
                                  NTT Output


END OF PHASE 1 SPECIFICATION — VERSION 1.0