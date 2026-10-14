module dma_registers #(
    parameter ADDR_WIDTH = 10
)(
    input  logic                  clk,
    input  logic                  rst,

    input  logic                  cpu_wr_en,
    input  logic [3:0]            cpu_addr,
    input  logic [31:0]           cpu_wdata,
    output logic [31:0]           cpu_rdata,

    output logic [ADDR_WIDTH-1:0] source_addr,
    output logic [ADDR_WIDTH-1:0] dest_addr,
    output logic [31:0]            transfer_length,
    output logic                   dma_start,

    input  logic                   dma_busy,
    input  logic                   dma_done
);

    localparam REG_SOURCE  = 4'h0;
    localparam REG_DEST    = 4'h4;
    localparam REG_LENGTH  = 4'h8;
    localparam REG_CONTROL = 4'hC;
    localparam REG_STATUS  = 4'h0;

    always_ff @(posedge clk) begin
        if (rst) begin
            source_addr     <= '0;
            dest_addr       <= '0;
            transfer_length <= '0;
            dma_start       <= 1'b0;
        end
        else begin
            dma_start <= 1'b0;

            if (cpu_wr_en) begin
                case (cpu_addr)

                    REG_SOURCE:
                        source_addr <= cpu_wdata[ADDR_WIDTH-1:0];

                    REG_DEST:
                        dest_addr <= cpu_wdata[ADDR_WIDTH-1:0];

                    REG_LENGTH:
                        transfer_length <= cpu_wdata;

                    REG_CONTROL:
                        dma_start <= cpu_wdata[0];

                    default:
                        ;
                endcase
            end
        end
    end

    always_comb begin
        cpu_rdata = 32'b0;

        case (cpu_addr)

            REG_SOURCE:
                cpu_rdata = source_addr;

            REG_DEST:
                cpu_rdata = dest_addr;

            REG_LENGTH:
                cpu_rdata = transfer_length;

            REG_CONTROL:
                cpu_rdata = {31'b0, dma_start};

            default:
                cpu_rdata = {30'b0, dma_done, dma_busy};

        endcase
    end

endmodule
