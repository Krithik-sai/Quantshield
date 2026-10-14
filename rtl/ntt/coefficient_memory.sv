module coefficient_memory (
    input  logic        clk,

    // Read addresses from NTT controller
    input  logic [7:0]  a_addr,
    input  logic [7:0]  b_addr,

    // Read data going to butterfly
    output logic [23:0] a_data_out,
    output logic [23:0] b_data_out,

    // Initial coefficient loading
    input  logic        load_enable,
    input  logic [7:0]  load_addr,
    input  logic [23:0] load_data,

    // Butterfly result write-back
    input  logic        write_enable,
    input  logic [23:0] a_data_in,
    input  logic [23:0] b_data_in
);

    // 256 coefficients, each 24 bits
    logic [23:0] data [0:255];


    // =========================================
    // READ
    // =========================================

    always_comb begin
        a_data_out = data[a_addr];
        b_data_out = data[b_addr];
    end


    // =========================================
    // WRITE
    // =========================================

    always_ff @(posedge clk) begin

        // Initial loading of NTT coefficients
        if (load_enable) begin
            data[load_addr] <= load_data;
        end

        // Write butterfly results back
        if (write_enable) begin
            data[a_addr] <= a_data_in;
            data[b_addr] <= b_data_in;
        end

    end

endmodule