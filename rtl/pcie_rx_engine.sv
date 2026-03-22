`timescale 1ns/1ps
module pcie_rx_engine (
    input  logic        clk,
    input  logic        rst,

    input  logic        pcie_tx_valid,
    output logic        pcie_tx_ready,
    input  logic [75:0] pcie_tx_data,

    input  logic        bridge_enable,
    input  logic [31:0] base_addr,
    input  logic [31:0] limit_addr,

    output logic        cpl_valid,
    output logic [75:0] cpl_packet
);

    logic [31:0] mem [0:255];

    logic [3:0]  tag;
    logic [3:0]  strb;
    logic [3:0]  pkt_type;
    logic [31:0] addr;
    logic [31:0] data;

    logic        addr_hit;
    integer      i;

    assign pcie_tx_ready = 1'b1;

    assign tag      = pcie_tx_data[75:72];
assign strb     = pcie_tx_data[71:68];
assign pkt_type = pcie_tx_data[67:64];
assign addr     = pcie_tx_data[63:32];
assign data     = pcie_tx_data[31:0];

assign addr_hit = (addr >= base_addr) && (addr <= limit_addr);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            cpl_valid  <= 1'b0;
            cpl_packet <= '0;
            for (i = 0; i < 256; i = i + 1)
                mem[i] <= 32'h0;
        end else begin
            cpl_valid <= 1'b0;

            if (pcie_tx_valid && pcie_tx_ready) begin
                if (!bridge_enable || !addr_hit) begin
                    // 4'hF = error completion
                    cpl_valid  <= 1'b1;
                    cpl_packet <= {tag, 4'h0, 4'hF, addr, 32'hDEAD_BEEF};
                end else begin
                    case (pkt_type)
                        4'h1: begin
                            // Memory Write Request
                            if (strb[0]) mem[addr[9:2]][7:0]   <= data[7:0];
                            if (strb[1]) mem[addr[9:2]][15:8]  <= data[15:8];
                            if (strb[2]) mem[addr[9:2]][23:16] <= data[23:16];
                            if (strb[3]) mem[addr[9:2]][31:24] <= data[31:24];

                            // 4'h8 = completion without data
                            cpl_valid  <= 1'b1;
                            cpl_packet <= {tag, 4'h0, 4'h8, addr, 32'h0000_0000};
                        end

                        4'h2: begin
                            // Memory Read Request
                            // 4'h9 = completion with data
                            cpl_valid  <= 1'b1;
                            cpl_packet <= {tag, 4'h0, 4'h9, addr, mem[addr[9:2]]};
                        end

                        default: begin
                            cpl_valid  <= 1'b1;
                            cpl_packet <= {tag, 4'h0, 4'hF, addr, 32'hBAD0_0001};
                        end
                    endcase
                end
            end
        end
    end

endmodule
