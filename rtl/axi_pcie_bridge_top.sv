module axi_pcie_bridge_top (
    input  logic        clk,
    input  logic        rst,

    input  logic [31:0] s_axi_awaddr,
    input  logic        s_axi_awvalid,
    output logic        s_axi_awready,

    input  logic [31:0] s_axi_wdata,
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
    input  logic        s_axi_rready
);

    typedef enum logic [1:0] {
        IDLE      = 2'd0,
        SEND_PKT  = 2'd1,
        WAIT_RESP = 2'd2
    } state_t;

    state_t state;

    logic [31:0] awaddr_reg, wdata_reg, araddr_reg;
    logic        aw_captured, w_captured;
    logic        req_is_read;

    logic [67:0] packet;
    logic        packet_valid;
    logic        packet_ready;

    logic        pcie_tx_valid;
    logic        pcie_tx_ready;
    logic [67:0] pcie_tx_data;

    logic        resp_valid;
    logic [31:0] resp_rdata;
    logic        resp_is_read;

    packet_builder u_packet_builder (
        .is_read(req_is_read),
        .addr   (req_is_read ? araddr_reg : awaddr_reg),
        .wdata  (wdata_reg),
        .packet (packet)
    );

    pcie_tx_engine u_pcie_tx_engine (
        .clk          (clk),
        .rst          (rst),
        .packet_valid (packet_valid),
        .packet_ready (packet_ready),
        .packet_data  (packet),
        .pcie_tx_valid(pcie_tx_valid),
        .pcie_tx_ready(pcie_tx_ready),
        .pcie_tx_data (pcie_tx_data)
    );

    pcie_rx_engine u_pcie_rx_engine (
        .clk          (clk),
        .rst          (rst),
        .pcie_tx_valid(pcie_tx_valid),
        .pcie_tx_ready(pcie_tx_ready),
        .pcie_tx_data (pcie_tx_data),
        .resp_valid   (resp_valid),
        .resp_rdata   (resp_rdata),
        .resp_is_read (resp_is_read)
    );

    assign s_axi_bresp = 2'b00;
    assign s_axi_rresp = 2'b00;

    assign s_axi_awready = (state == IDLE) && !aw_captured;
    assign s_axi_wready  = (state == IDLE) && !w_captured;
    assign s_axi_arready = (state == IDLE) && !aw_captured && !w_captured;

    assign packet_valid = (state == SEND_PKT);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state        <= IDLE;
            awaddr_reg   <= 32'h0;
            wdata_reg    <= 32'h0;
            araddr_reg   <= 32'h0;
            aw_captured  <= 1'b0;
            w_captured   <= 1'b0;
            req_is_read  <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_rvalid <= 1'b0;
            s_axi_rdata  <= 32'h0;
        end else begin
            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 1'b0;

            if (s_axi_rvalid && s_axi_rready)
                s_axi_rvalid <= 1'b0;

            if (s_axi_awvalid && s_axi_awready) begin
                awaddr_reg  <= s_axi_awaddr;
                aw_captured <= 1'b1;
            end

            if (s_axi_wvalid && s_axi_wready) begin
                wdata_reg   <= s_axi_wdata;
                w_captured  <= 1'b1;
            end

            case (state)
                IDLE: begin
                    if (aw_captured && w_captured) begin
                        req_is_read <= 1'b0;
                        state       <= SEND_PKT;
                    end else if (s_axi_arvalid && s_axi_arready) begin
                        araddr_reg  <= s_axi_araddr;
                        req_is_read <= 1'b1;
                        state       <= SEND_PKT;
                    end
                end

                SEND_PKT: begin
                    if (packet_valid && packet_ready) begin
                        state <= WAIT_RESP;
                    end
                end

                WAIT_RESP: begin
                    if (resp_valid) begin
                        if (resp_is_read) begin
                            s_axi_rdata  <= resp_rdata;
                            s_axi_rvalid <= 1'b1;
                        end else begin
                            s_axi_bvalid <= 1'b1;
                        end

                        aw_captured <= 1'b0;
                        w_captured  <= 1'b0;
                        state       <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
