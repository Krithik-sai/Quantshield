module dma_top #(
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 32
)(
    input  logic        clk,
    input  logic        rst,

    // CPU interface
    input  logic        cpu_wr_en,
    input  logic [3:0]  cpu_addr,
    input  logic [31:0] cpu_wdata,
    output logic [31:0] cpu_rdata,

    // Generic peripheral interface
    output logic [DATA_WIDTH-1:0] peripheral_data_out,
    output logic                  peripheral_valid,
    input  logic                  peripheral_ready,

    input  logic [DATA_WIDTH-1:0] peripheral_data_in,
    input  logic                  peripheral_valid_in,
    output logic                  peripheral_ready_out
);

    // =========================================================
    // DMA REGISTERS
    // =========================================================

    logic [ADDR_WIDTH-1:0] source_addr;
    logic [ADDR_WIDTH-1:0] dest_addr;
    logic [31:0] transfer_length;
    logic dma_start;

    logic dma_busy;
    logic dma_done;


    // =========================================================
    // RAM SIGNALS
    // =========================================================

    logic [ADDR_WIDTH-1:0] ram_rd_addr;
    logic ram_rd_en;
    logic [DATA_WIDTH-1:0] ram_rd_data;

    logic [ADDR_WIDTH-1:0] ram_wr_addr;
    logic ram_wr_en;
    logic [DATA_WIDTH-1:0] ram_wr_data;


    // =========================================================
    // DMA CONTROLLER <-> PERIPHERAL
    // =========================================================

    logic [DATA_WIDTH-1:0] controller_data_out;
    logic controller_valid;
    logic controller_ready;

    logic [DATA_WIDTH-1:0] controller_data_in;
    logic controller_valid_in;
    logic controller_ready_out;


    // =========================================================
    // PERIPHERAL INTERFACE INTERNAL SIGNAL
    // =========================================================

    logic interface_peripheral_ready;


    // =========================================================
    // DMA REGISTERS
    // =========================================================

    dma_registers #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_dma_registers (
        .clk(clk),
        .rst(rst),

        .cpu_wr_en(cpu_wr_en),
        .cpu_addr(cpu_addr),
        .cpu_wdata(cpu_wdata),
        .cpu_rdata(cpu_rdata),

        .source_addr(source_addr),
        .dest_addr(dest_addr),
        .transfer_length(transfer_length),
        .dma_start(dma_start),

        .dma_busy(dma_busy),
        .dma_done(dma_done)
    );


    // =========================================================
    // DATA RAM
    // =========================================================

    data_ram #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_data_ram (
        .clk(clk),
        .rst(rst),

        .rd_addr(ram_rd_addr),
        .rd_en(ram_rd_en),
        .rd_data(ram_rd_data),

        .wr_addr(ram_wr_addr),
        .wr_en(ram_wr_en),
        .wr_data(ram_wr_data)
    );


    // =========================================================
    // DMA CONTROLLER
    // =========================================================

    dma_controller #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_dma_controller (
        .clk(clk),
        .rst(rst),

        .source_addr(source_addr),
        .dest_addr(dest_addr),
        .transfer_length(transfer_length),
        .dma_start(dma_start),

        .dma_busy(dma_busy),
        .dma_done(dma_done),

        .ram_rd_addr(ram_rd_addr),
        .ram_rd_en(ram_rd_en),
        .ram_rd_data(ram_rd_data),

        .ram_wr_addr(ram_wr_addr),
        .ram_wr_en(ram_wr_en),
        .ram_wr_data(ram_wr_data),

        .peripheral_data_out(controller_data_out),
        .peripheral_valid(controller_valid),
        .peripheral_ready(controller_ready),

        .peripheral_data_in(controller_data_in),
        .peripheral_valid_in(controller_valid_in),
        .peripheral_ready_out(controller_ready_out)
    );


    // =========================================================
    // GENERIC PERIPHERAL INTERFACE
    // =========================================================

    dma_peripheral_if #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_peripheral_if (
        .clk(clk),
        .rst(rst),

        .dma_data_out(controller_data_out),
        .dma_valid(controller_valid),
        .dma_ready(controller_ready),

        .peripheral_data_in(peripheral_data_in),
        .peripheral_valid(peripheral_valid_in),
        .peripheral_ready(interface_peripheral_ready),

        .dma_data_in(controller_data_in),
        .dma_data_in_valid(controller_valid_in)
    );


    // =========================================================
    // EXTERNAL PERIPHERAL CONNECTION
    // =========================================================

    assign peripheral_data_out = controller_data_out;
    assign peripheral_valid = controller_valid;
    assign peripheral_ready_out = controller_ready_out;

endmodule
