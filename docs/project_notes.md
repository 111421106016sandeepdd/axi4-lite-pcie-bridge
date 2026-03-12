# AXI4-Lite to PCIe-Style Bridge

## Objective
Design a simplified protocol bridge that translates AXI4-Lite style transactions into PCIe-style packetized transactions.

## Key Features
- AXI-side transaction handling
- Packet builder for PCIe-style requests
- FSM-based control logic
- Simulation-based verification

## Verification
The design was verified using a SystemVerilog testbench and waveform inspection.

## Future Improvements
- Add more complete PCIe packet modeling
- Extend support for more transaction types
- Add richer verification scenarios
