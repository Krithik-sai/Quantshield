module ntt_controller (
    input  logic       clk,
    input  logic       reset,
    input  logic       start,

    output logic [7:0] a_addr,
    output logic [7:0] b_addr,
    output logic [6:0] twiddle_addr,

    output logic       write_enable,

    output logic       busy,
    output logic       done
);

    typedef enum logic [2:0] {
        IDLE,
        READ,
        COMPUTE,
        WRITE,
        NEXT,
        FINISH
    } state_t;

    state_t state;

    logic [7:0] len;
    logic [7:0] group_start;
    logic [7:0] j;

    logic [6:0] zeta_index;


    // =========================================
    // Outputs
    // =========================================

    always_comb begin

        a_addr       = 8'd0;
        b_addr       = 8'd0;
        twiddle_addr = zeta_index;

        write_enable = 1'b0;

        busy = 1'b0;
        done = 1'b0;


        case (state)

            IDLE: begin
                busy = 1'b0;
            end


            READ: begin

                busy = 1'b1;

                a_addr = group_start + j;
                b_addr = group_start + j + len;

            end


            COMPUTE: begin

                busy = 1'b1;

                a_addr = group_start + j;
                b_addr = group_start + j + len;

            end


            WRITE: begin

                busy = 1'b1;

                a_addr = group_start + j;
                b_addr = group_start + j + len;

                write_enable = 1'b1;

            end


            NEXT: begin

                busy = 1'b1;

            end


            FINISH: begin

                done = 1'b1;

            end


            default: begin

                busy = 1'b0;
                done = 1'b0;

            end

        endcase

    end


    // =========================================
    // State machine
    // =========================================

    always_ff @(posedge clk or posedge reset) begin

        if (reset) begin

            state       <= IDLE;

            len         <= 8'd128;
            group_start <= 8'd0;
            j           <= 8'd0;

            zeta_index  <= 7'd1;

        end

        else begin

            case (state)

                IDLE: begin

                    if (start) begin

                        len         <= 8'd128;
                        group_start <= 8'd0;
                        j           <= 8'd0;
                        zeta_index  <= 7'd1;

                        state <= READ;

                    end

                end


                READ: begin

                    state <= COMPUTE;

                end


                COMPUTE: begin

                    state <= WRITE;

                end


                WRITE: begin

                    state <= NEXT;

                end


                NEXT: begin

                    if (j < len - 1) begin

                        j <= j + 1;

                        state <= READ;

                    end

                    else begin

                        j <= 8'd0;


                        if (group_start + (2 * len) < 256) begin

                            group_start <= group_start + (2 * len);

                            zeta_index <= zeta_index + 1;

                            state <= READ;

                        end


                        else if (len > 2) begin

                            len <= len >> 1;

                            group_start <= 8'd0;

                            zeta_index <= zeta_index + 1;

                            state <= READ;

                        end


                        else begin

                            state <= FINISH;

                        end

                    end

                end


                FINISH: begin

                    state <= IDLE;

                end


                default: begin

                    state <= IDLE;

                end

            endcase

        end

    end

endmodule