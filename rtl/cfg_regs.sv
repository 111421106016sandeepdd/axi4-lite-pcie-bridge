`timescale 1ns/1ps
module cfg_regs (
    input  logic        clk,
    input  logic        rst,

    output logic        bridge_enable,
    output logic [31:0] base_addr,
    output logic [31:0] limit_addr
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            bridge_enable <= 1'b1;
            base_addr     <= 32'h0000_0000;
            limit_addr    <= 32'h0000_03FF; // 1 KB window
        end
    end

endmodule
