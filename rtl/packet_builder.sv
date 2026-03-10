`timescale 1ns/1ps
module packet_builder (
    input  logic        is_read,
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    output logic [67:0] packet
);
    // Packet format:
    // [67:64] = type
    // [63:32] = address
    // [31:0]  = data
    //
    // type = 4'h1 -> write
    // type = 4'h2 -> read

    always_comb begin
        if (is_read)
            packet = {4'h2, addr, 32'h0000_0000};
        else
            packet = {4'h1, addr, wdata};
    end

endmodule
