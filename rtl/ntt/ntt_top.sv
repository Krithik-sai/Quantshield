module ntt_top (
    input  logic        clk,
    input  logic        reset,
    input  logic        start,

    // Initial coefficient loading
    input  logic        load_enable,
    input  logic [7:0]  load_addr,
    input  logic [23:0] load_data,

    output logic        busy,
    output logic        done
);

    // =========================================
    // Controller signals
    // =========================================

    logic [7:0] a_addr;
    logic [7:0] b_addr;
    logic [6:0] twiddle_addr;

    logic write_enable;


    // =========================================
    // Memory signals
    // =========================================

    logic [23:0] a_data;
    logic [23:0] b_data;

    logic [23:0] a_result;
    logic [23:0] b_result;


    // =========================================
    // Twiddle
    // =========================================

    logic [23:0] w;


    // =========================================
    // 1. NTT CONTROLLER
    // =========================================

    ntt_controller u_controller (
        .clk          (clk),
        .reset        (reset),
        .start        (start),

        .a_addr       (a_addr),
        .b_addr       (b_addr),
        .twiddle_addr (twiddle_addr),

        .write_enable (write_enable),

        .busy         (busy),
        .done         (done)
    );


    // =========================================
    // 2. TWIDDLE ROM
    // =========================================

    twiddle_rom u_twiddle_rom (
        .twiddle_addr (twiddle_addr),
        .w            (w)
    );


    // =========================================
    // 3. COEFFICIENT MEMORY
    // =========================================

    coefficient_memory u_memory (
        .clk          (clk),

        .a_addr       (a_addr),
        .b_addr       (b_addr),

        .a_data_out   (a_data),
        .b_data_out   (b_data),

        .load_enable  (load_enable),
        .load_addr    (load_addr),
        .load_data    (load_data),

        .write_enable (write_enable),

        .a_data_in    (a_result),
        .b_data_in    (b_result)
    );


    // =========================================
    // 4. BUTTERFLY DATAPATH
    // =========================================

    butterfly_top u_butterfly (
        .modulus_sel_i (1'b0),       // 0 = Kyber
        .a_i           (a_data),
        .b_i           (b_data),
        .w_i           (w),

        .a_o           (a_result),
        .b_o           (b_result)
    );

endmodule