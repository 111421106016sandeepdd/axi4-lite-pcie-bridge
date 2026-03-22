`timescale 1ns/1ps
module completion_manager (
    input  logic        cpl_valid,
    input  logic [75:0] cpl_packet,

    output logic        resp_valid,
    output logic        resp_is_read,
    output logic [31:0] resp_rdata,
    output logic [1:0]  resp_status
);

    wire [3:0] pkt_type = cpl_packet[67:64];

    always @(*) begin
        resp_valid   = cpl_valid;
        resp_is_read = 1'b0;
        resp_rdata   = 32'h0;
        resp_status  = 2'b00;

        if (cpl_valid) begin
            case (pkt_type)
                4'h8: begin
                    resp_is_read = 1'b0;
                    resp_status  = 2'b00;
                end

                4'h9: begin
                    resp_is_read = 1'b1;
                    resp_rdata   = cpl_packet[31:0];
                    resp_status  = 2'b00;
                end

                4'hF: begin
                    resp_is_read = 1'b0;
                    resp_status  = 2'b10;
                    resp_rdata   = cpl_packet[31:0];
                end

                default: begin
                    resp_is_read = 1'b0;
                    resp_status  = 2'b10;
                end
            endcase
        end
    end

endmodule
