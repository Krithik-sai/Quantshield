// ============================================================
// 2 KB Entity Buffer
// Capacity : 2048 bytes
// Data     : 8 bits
// Address  : 11 bits
// ============================================================
`timescale 1ns/1ps
module E_buffer_rtl (
    input  logic        clk,
    input  logic        rst,

    // Write interface
    input  logic        wr_en,
    input  logic [10:0] wr_addr,
    input  logic [7:0]  wr_data,

    // Read interface
    input  logic [10:0] rd_addr,
    output logic [7:0]  rd_data
);

    // 2048 x 8-bit = 16384 bits = 2 KB
    logic [7:0] buffer_mem [0:2047];

    // --------------------------------------------------------
    // Write
    // --------------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < 2048; i++)
                buffer_mem[i] <= '0;
        end
        else if (wr_en) begin
            buffer_mem[wr_addr] <= wr_data;
        end
    end

    // --------------------------------------------------------
    // Asynchronous read
    // --------------------------------------------------------
    always_comb begin
        rd_data = buffer_mem[rd_addr];
    end

endmodule
