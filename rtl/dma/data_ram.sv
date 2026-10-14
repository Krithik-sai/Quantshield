module data_ram #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 10
)(
    input  logic                  clk,
    input  logic                  rst,

    input  logic [ADDR_WIDTH-1:0] rd_addr,
    input  logic                  rd_en,
    output logic [DATA_WIDTH-1:0] rd_data,

    input  logic [ADDR_WIDTH-1:0] wr_addr,
    input  logic                  wr_en,
    input  logic [DATA_WIDTH-1:0] wr_data
);

    localparam DEPTH = 1 << ADDR_WIDTH;

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    integer i;

    always_ff @(posedge clk) begin
        if (rst) begin
            rd_data <= '0;

            for (i = 0; i < DEPTH; i = i + 1)
                mem[i] <= '0;

        end else begin
            if (wr_en)
                mem[wr_addr] <= wr_data;

            if (rd_en)
                rd_data <= mem[rd_addr];
        end
    end

endmodule
