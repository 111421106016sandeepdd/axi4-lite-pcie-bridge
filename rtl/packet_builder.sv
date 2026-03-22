`timescale 1ns/1ps
module packet_builder (
    input  logic        is_read,
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    input  logic [3:0]  wstrb,
    input  logic [3:0]  tag,
    output logic [75:0] packet
);
    // Simplified internal PCIe-style packet format
    // [75:72] = tag
    // [71:68] = write strobe / reserved
    // [67:64] = packet type
    // [63:32] = address
    // [31:0]  = data
    //
    // 4'h1 = Memory Write Request
    // 4'h2 = Memory Read Request
    // 4'h8 = Completion without Data
    // 4'h9 = Completion with Data

    always_comb begin
        if (is_read)
            packet = {tag, 4'h0, 4'h2, addr, 32'h0000_0000};
        else
            packet = {tag, wstrb, 4'h1, addr, wdata};
    end

endmodule
