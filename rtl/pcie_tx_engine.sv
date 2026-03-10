module pcie_tx_engine (
    input  logic        clk,
    input  logic        rst,

    input  logic        packet_valid,
    output logic        packet_ready,
    input  logic [67:0] packet_data,

    output logic        pcie_tx_valid,
    input  logic        pcie_tx_ready,
    output logic [67:0] pcie_tx_data
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            pcie_tx_valid <= 1'b0;
            pcie_tx_data  <= '0;
        end else begin
            if (!pcie_tx_valid && packet_valid) begin
                pcie_tx_valid <= 1'b1;
                pcie_tx_data  <= packet_data;
            end else if (pcie_tx_valid && pcie_tx_ready) begin
                pcie_tx_valid <= 1'b0;
            end
        end
    end

    assign packet_ready = !pcie_tx_valid;

endmodule
