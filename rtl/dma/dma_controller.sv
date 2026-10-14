module dma_controller #(
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 32
)(
    input  logic                  clk,
    input  logic                  rst,

    // Configuration from DMA registers
    input  logic [ADDR_WIDTH-1:0] source_addr,
    input  logic [ADDR_WIDTH-1:0] dest_addr,
    input  logic [31:0]           transfer_length,
    input  logic                  dma_start,

    // Status
    output logic                  dma_busy,
    output logic                  dma_done,

    // RAM read interface
    output logic [ADDR_WIDTH-1:0] ram_rd_addr,
    output logic                  ram_rd_en,
    input  logic [DATA_WIDTH-1:0] ram_rd_data,

    // RAM write interface
    output logic [ADDR_WIDTH-1:0] ram_wr_addr,
    output logic                  ram_wr_en,
    output logic [DATA_WIDTH-1:0] ram_wr_data,

    // Peripheral output
    output logic [DATA_WIDTH-1:0] peripheral_data_out,
    output logic                  peripheral_valid,
    input  logic                  peripheral_ready,

    // Peripheral input
    input  logic [DATA_WIDTH-1:0] peripheral_data_in,
    input  logic                  peripheral_valid_in,
    output logic                  peripheral_ready_out
);

    typedef enum logic [2:0] {
        IDLE,
        READ_RAM,
        SEND_PERIPHERAL,
        RECEIVE_PERIPHERAL,
        WRITE_RAM,
        DONE
    } state_t;

    state_t state;

    logic [ADDR_WIDTH-1:0] current_source;
    logic [ADDR_WIDTH-1:0] current_dest;
    logic [31:0] remaining;
    logic [DATA_WIDTH-1:0] data_buffer;

    always_ff @(posedge clk) begin

        if (rst) begin
            state         <= IDLE;
            current_source <= '0;
            current_dest   <= '0;
            remaining      <= '0;
            data_buffer    <= '0;
            dma_busy       <= 1'b0;
            dma_done       <= 1'b0;

        end else begin

            dma_done <= 1'b0;

            case (state)

                IDLE: begin
                    dma_busy <= 1'b0;

                    if (dma_start && transfer_length != 0) begin

                        current_source <= source_addr;
                        current_dest   <= dest_addr;
                        remaining      <= transfer_length;

                        dma_busy <= 1'b1;

                        state <= READ_RAM;
                    end
                end


                READ_RAM: begin
                    state <= SEND_PERIPHERAL;
                end


                SEND_PERIPHERAL: begin
                    if (peripheral_ready) begin

                        data_buffer <= ram_rd_data;

                        if (remaining == 1) begin
                            state <= DONE;
                        end else begin
                            current_source <= current_source + 1'b1;
                            remaining <= remaining - 1'b1;

                            state <= READ_RAM;
                        end
                    end
                end


                RECEIVE_PERIPHERAL: begin
                    if (peripheral_valid_in) begin
                        data_buffer <= peripheral_data_in;
                        state <= WRITE_RAM;
                    end
                end


                WRITE_RAM: begin
                    if (remaining == 1) begin
                        state <= DONE;
                    end else begin
                        current_dest <= current_dest + 1'b1;
                        remaining <= remaining - 1'b1;

                        state <= RECEIVE_PERIPHERAL;
                    end
                end


                DONE: begin
                    dma_busy <= 1'b0;
                    dma_done <= 1'b1;

                    state <= IDLE;
                end


                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end


    // RAM read signals
    assign ram_rd_addr = current_source;

    assign ram_rd_en =
        (state == READ_RAM);


    // RAM write signals
    assign ram_wr_addr = current_dest;

    assign ram_wr_en =
        (state == WRITE_RAM);

    assign ram_wr_data =
        data_buffer;


    // RAM -> Peripheral
    assign peripheral_data_out =
        ram_rd_data;

    assign peripheral_valid =
        (state == SEND_PERIPHERAL);

    // Peripheral -> RAM
    assign peripheral_ready_out =
        (state == RECEIVE_PERIPHERAL);

endmodule
