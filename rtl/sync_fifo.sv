`timescale 1ns/1ps
module sync_fifo #(
    parameter WIDTH = 76,
    parameter DEPTH = 4
)(
    input  logic             clk,
    input  logic             rst,

    input  logic             wr_en,
    input  logic [WIDTH-1:0] wr_data,
    output logic             full,

    input  logic             rd_en,
    output logic [WIDTH-1:0] rd_data,
    output logic             empty
);

    logic [WIDTH-1:0] mem [0:DEPTH-1];
    logic [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;
    logic [$clog2(DEPTH+1)-1:0] count;

    integer i;

    assign full  = (count == DEPTH);
    assign empty = (count == 0);
    assign rd_data = mem[rd_ptr];

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
            count  <= '0;
            for (i = 0; i < DEPTH; i = i + 1)
                mem[i] <= '0;
        end else begin
            case ({wr_en && !full, rd_en && !empty})
                2'b10: begin
                    mem[wr_ptr] <= wr_data;
                    wr_ptr <= (wr_ptr == DEPTH-1) ? '0 : wr_ptr + 1'b1;
                    count  <= count + 1'b1;
                end

                2'b01: begin
                    rd_ptr <= (rd_ptr == DEPTH-1) ? '0 : rd_ptr + 1'b1;
                    count  <= count - 1'b1;
                end

                2'b11: begin
                    mem[wr_ptr] <= wr_data;
                    wr_ptr <= (wr_ptr == DEPTH-1) ? '0 : wr_ptr + 1'b1;
                    rd_ptr <= (rd_ptr == DEPTH-1) ? '0 : rd_ptr + 1'b1;
                end

                default: begin
                    // hold state
                end
            endcase
        end
    end

endmodule
