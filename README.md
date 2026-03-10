# AXI4-Lite to PCIe-Style Bridge | Verilog

## Overview
This project implements a simplified AXI4-Lite to PCIe-style bridge in Verilog. The design accepts AXI memory read/write transactions, converts them into packetized PCIe-style transfers, and returns responses back to the AXI side.

The project demonstrates protocol translation, handshake-based communication, FSM-based control logic, and simulation-based verification.

## Architecture
The bridge consists of the following blocks:

- AXI request capture logic
- Packet builder
- PCIe transmit engine
- PCIe receive engine with simple memory model
- AXI response generation logic

### Block Flow
AXI Interface -> Request Capture -> Packet Builder -> PCIe TX Engine -> PCIe RX Engine -> AXI Response

## Packet Format
The bridge uses a simplified PCIe-style packet format:

[67:64] : packet type  
[63:32] : address  
[31:0]  : data  

### Packet Types
4'h1 : Write request  
4'h2 : Read request  

## FSM Design
The top-level control logic uses a 3-state FSM:

IDLE      : Waits for AXI request  
SEND_PKT  : Generates and sends packet  
WAIT_RESP : Waits for PCIe response  

## Verification
The testbench verifies:

1. Read from empty memory returns 0  
2. Write to address 0x10 and read back 0x1234ABCD  
3. Write to address 0x20 and read back 0xDEADBEEF  

## Simulation

Compile:

iverilog -g2012 -Wall \
-o build/axi_pcie_bridge.out \
rtl/packet_builder.sv \
rtl/pcie_tx_engine.sv \
rtl/pcie_rx_engine.sv \
rtl/axi_pcie_bridge_top.sv \
tb/tb_axi_pcie_bridge.sv

Run:

vvp build/axi_pcie_bridge.out

Waveform:

gtkwave build/axi_pcie_bridge.vcd

## Files

rtl/packet_builder.sv  
rtl/pcie_tx_engine.sv  
rtl/pcie_rx_engine.sv  
rtl/axi_pcie_bridge_top.sv  
tb/tb_axi_pcie_bridge.sv  

## Future Improvements

- Support burst transactions  
- Add backpressure testing  
- Expand packet format  
- Add error responses
