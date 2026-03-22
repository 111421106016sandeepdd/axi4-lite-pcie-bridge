`timescale 1ns/1ps
module axi_pcie_bridge_top (
    input  logic        clk,
    input  logic        rst,

    // AXI4-Lite slave interface
    input  logic [31:0] s_axi_awaddr,
    input  logic        s_axi_awvalid,
    output logic        s_axi_awready,

    input  logic [31:0] s_axi_wdata,
    input  logic [3:0]  s_axi_wstrb,
    input  logic        s_axi_wvalid,
    output logic        s_axi_wready,

    output logic [1:0]  s_axi_bresp,
    output logic        s_axi_bvalid,
    input  logic        s_axi_bready,

    input  logic [31:0] s_axi_araddr,
    input  logic        s_axi_arvalid,
    output logic        s_axi_arready,

    output logic [31:0] s_axi_rdata,
    output logic [1:0]  s_axi_rresp,
    output logic        s_axi_rvalid,
    input  logic        s_axi_rready,

    // Simple external stall control for testing backpressure
    input  logic        pcie_tx_ready
);

    typedef enum logic [1:0] {
        IDLE      = 2'b00,
        WAIT_RESP = 2'b01
    } state_t;

    state_t state;

    logic        req_is_read;
    logic [31:0] req_addr;
    logic [31:0] req_wdata;
    logic [3:0]  req_wstrb;
    logic [3:0]  req_tag;

    logic [75:0] packet;

    logic        fifo_full, fifo_empty;
    logic [75:0] fifo_rd_data;
    logic        fifo_wr_en, fifo_rd_en;

    logic        tx_packet_ready;
    logic        tx_valid;
    logic [75:0] tx_data;

    logic        bridge_enable;
    logic [31:0] base_addr;
    logic [31:0] limit_addr;

    logic        cpl_valid;
    logic [75:0] cpl_packet;

    logic        resp_valid;
    logic        resp_is_read;
    logic [31:0] resp_rdata;
    logic [1:0]  resp_status;

    logic        rx_ready_unused;

    cfg_regs u_cfg_regs (
        .clk           (clk),
        .rst           (rst),
        .bridge_enable (bridge_enable),
        .base_addr     (base_addr),
        .limit_addr    (limit_addr)
    );

    packet_builder u_packet_builder (
        .is_read (req_is_read),
        .addr    (req_addr),
        .wdata   (req_wdata),
        .wstrb   (req_wstrb),
        .tag     (req_tag),
        .packet  (packet)
    );

    sync_fifo #(
        .WIDTH (76),
        .DEPTH (4)
    ) u_sync_fifo (
        .clk     (clk),
        .rst     (rst),
        .wr_en   (fifo_wr_en),
        .wr_data (packet),
        .full    (fifo_full),
        .rd_en   (fifo_rd_en),
        .rd_data (fifo_rd_data),
        .empty   (fifo_empty)
    );

    pcie_tx_engine u_pcie_tx_engine (
        .clk           (clk),
        .rst           (rst),
        .packet_valid  (!fifo_empty),
        .packet_ready  (tx_packet_ready),
        .packet_data   (fifo_rd_data),
        .pcie_tx_valid (tx_valid),
        .pcie_tx_ready (pcie_tx_ready),
        .pcie_tx_data  (tx_data)
    );

    assign fifo_rd_en = tx_packet_ready && !fifo_empty;

    pcie_rx_engine u_pcie_rx_engine (
        .clk           (clk),
        .rst           (rst),
        .pcie_tx_valid (tx_valid),
        .pcie_tx_ready (rx_ready_unused),
        .pcie_tx_data  (tx_data),
        .bridge_enable (bridge_enable),
        .base_addr     (base_addr),
        .limit_addr    (limit_addr),
        .cpl_valid     (cpl_valid),
        .cpl_packet    (cpl_packet)
    );

    completion_manager u_completion_manager (
        .cpl_valid    (cpl_valid),
        .cpl_packet   (cpl_packet),
        .resp_valid   (resp_valid),
        .resp_is_read (resp_is_read),
        .resp_rdata   (resp_rdata),
        .resp_status  (resp_status)
    );

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state         <= IDLE;
            req_is_read   <= 1'b0;
            req_addr      <= 32'h0;
            req_wdata     <= 32'h0;
            req_wstrb     <= 4'h0;
            req_tag       <= 4'h0;
            fifo_wr_en    <= 1'b0;

            s_axi_awready <= 1'b1;
            s_axi_wready  <= 1'b1;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= 2'b00;

            s_axi_arready <= 1'b1;
            s_axi_rvalid  <= 1'b0;
            s_axi_rresp   <= 2'b00;
            s_axi_rdata   <= 32'h0;
        end else begin
            fifo_wr_en <= 1'b0;

            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 1'b0;

            if (s_axi_rvalid && s_axi_rready)
                s_axi_rvalid <= 1'b0;

            case (state)
                IDLE: begin
                    s_axi_awready <= !fifo_full;
                    s_axi_wready  <= !fifo_full;
                    s_axi_arready <= !fifo_full;

                    if (s_axi_awvalid && s_axi_wvalid && !fifo_full) begin
                        req_is_read <= 1'b0;
                        req_addr    <= s_axi_awaddr;
                        req_wdata   <= s_axi_wdata;
                        req_wstrb   <= s_axi_wstrb;
                        req_tag     <= req_tag + 1'b1;
                        fifo_wr_en  <= 1'b1;

                        s_axi_awready <= 1'b0;
                        s_axi_wready  <= 1'b0;
                        s_axi_arready <= 1'b0;
                        state         <= WAIT_RESP;
                    end else if (s_axi_arvalid && !fifo_full) begin
                        req_is_read <= 1'b1;
                        req_addr    <= s_axi_araddr;
                        req_wdata   <= 32'h0;
                        req_wstrb   <= 4'h0;
                        req_tag     <= req_tag + 1'b1;
                        fifo_wr_en  <= 1'b1;

                        s_axi_awready <= 1'b0;
                        s_axi_wready  <= 1'b0;
                        s_axi_arready <= 1'b0;
                        state         <= WAIT_RESP;
                    end
                end

                WAIT_RESP: begin
                    if (resp_valid) begin
                        if (resp_is_read) begin
                            s_axi_rvalid <= 1'b1;
                            s_axi_rdata  <= resp_rdata;
                            s_axi_rresp  <= resp_status;
                        end else begin
                            s_axi_bvalid <= 1'b1;
                            s_axi_bresp  <= resp_status;
                        end
                        state <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
