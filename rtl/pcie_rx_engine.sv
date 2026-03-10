`timescale 1ns/1ps
module pcie_rx_engine (
    input  logic        clk,
    input  logic        rst,

    input  logic        pcie_tx_valid,
    output logic        pcie_tx_ready,
    input  logic [67:0] pcie_tx_data,

    output logic        resp_valid,
    output logic [31:0] resp_rdata,
    output logic        resp_is_read
);

    logic [31:0] mem [0:255];

    logic [3:0]  pkt_type;
    logic [31:0] pkt_addr;
    logic [31:0] pkt_data;

    integer i;

    assign pcie_tx_ready = 1'b1;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            resp_valid   <= 1'b0;
            resp_rdata   <= 32'h0;
            resp_is_read <= 1'b0;

            for (i = 0; i < 256; i = i + 1)
                mem[i] <= 32'h0;
        end else begin
            resp_valid <= 1'b0;

            if (pcie_tx_valid && pcie_tx_ready) begin
                pkt_type = pcie_tx_data[67:64];
                pkt_addr = pcie_tx_data[63:32];
                pkt_data = pcie_tx_data[31:0];

                case (pkt_type)
                    4'h1: begin
                        mem[pkt_addr[9:2]] <= pkt_data;
                        resp_valid   <= 1'b1;
                        resp_rdata   <= 32'h0;
                        resp_is_read <= 1'b0;
                    end

                    4'h2: begin
                        resp_valid   <= 1'b1;
                        resp_rdata   <= mem[pkt_addr[9:2]];
                        resp_is_read <= 1'b1;
                    end

                    default: begin
                        resp_valid   <= 1'b1;
                        resp_rdata   <= 32'hDEAD_BEEF;
                        resp_is_read <= 1'b1;
                    end
                endcase
            end
        end
    end

endmodule
