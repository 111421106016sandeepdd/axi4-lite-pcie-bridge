SIM_OUT = build/axi_pcie_bridge.out
VCD = build/axi_pcie_bridge.vcd

RTL = rtl/packet_builder.sv \
      rtl/pcie_tx_engine.sv \
      rtl/pcie_rx_engine.sv \
      rtl/axi_pcie_bridge_top.sv

TB = tb/tb_axi_pcie_bridge.sv

build:
	mkdir -p build

compile: build
	iverilog -g2012 -Wall -o $(SIM_OUT) $(RTL) $(TB)

run: compile
	vvp $(SIM_OUT)

wave:
	gtkwave $(VCD)

clean:
	rm -rf build
