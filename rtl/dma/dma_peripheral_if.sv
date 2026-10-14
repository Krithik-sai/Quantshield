module dma_peripheral_if #(
    parameter DATA_WIDTH = 32
)(
    input  logic                  clk,
    input  logic                  rst,

    input  logic [DATA_WIDTH-1:0] dma_data_out,
    input  logic                  dma_valid,
    output logic                  dma_ready,

    input  logic [DATA_WIDTH-1:0] peripheral_data_in,
    input  logic                  peripheral_valid,
    output logic                  peripheral_ready,

    output logic [DATA_WIDTH-1:0] dma_data_in,
    output logic                  dma_data_in_valid
);

    always_ff @(posedge clk) begin
        if (rst) begin
            dma_data_in       <= '0;
            dma_data_in_valid <= 1'b0;
        end
        else begin
            dma_data_in_valid <= 1'b0;

            if (peripheral_valid && peripheral_ready) begin
                dma_data_in       <= peripheral_data_in;
                dma_data_in_valid <= 1'b1;
            end
        end
    end

    assign dma_ready = 1'b1;
    assign peripheral_ready = 1'b1;

endmodule
