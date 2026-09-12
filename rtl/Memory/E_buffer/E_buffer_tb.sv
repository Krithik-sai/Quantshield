`timescale 1ns/1ps

module E_buffer_tb;

    // ========================================================
    // Testbench signals
    // ========================================================

    logic        clk;

    logic        wr_en;
    logic [10:0] wr_addr;
    logic [7:0]  wr_data;

    logic [10:0] rd_addr;
    logic [7:0]  rd_data;

    // ========================================================
    // DUT
    // ========================================================

    E_buffer_rtl dut (
        .clk     (clk),
	.rst	 (rst),
        .wr_en   (wr_en),
        .wr_addr (wr_addr),
        .wr_data (wr_data),
        .rd_addr (rd_addr),
        .rd_data (rd_data)
    );

    // ========================================================
    // Clock generation
    // 10 ns period = 100 MHz
    // ========================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ========================================================
    // Write task
    // ========================================================

    task automatic write_mem(
        input logic [10:0] addr,
        input logic [7:0]  data
    );
        begin
            @(negedge clk);

            wr_en   = 1'b1;
            wr_addr = addr;
            wr_data = data;

            @(negedge clk);

            wr_en = 1'b0;
        end
    endtask

    // ========================================================
    // Read task
    // ========================================================

    task automatic read_mem(
        input logic [10:0] addr,
        input logic [7:0] expected
    );
        begin
            rd_addr = addr;

            #1;

            if (rd_data !== expected) begin
                $display("ERROR: Address = %0d, Expected = %h, Got = %h",
                         addr, expected, rd_data);
            end
            else begin
                $display("PASS : Address = %0d, Data = %h",
                         addr, rd_data);
            end
        end
    endtask

    // ========================================================
    // Test sequence
    // ========================================================

    initial begin

        // Initialize
        wr_en   = 1'b0;
        wr_addr = 11'd0;
        wr_data = 8'h00;
        rd_addr = 11'd0;

        $display("==============================================");
        $display("      2 KB ENTITY BUFFER TEST");
        $display("==============================================");

        // ----------------------------------------------------
        // Test 1: Write and read address 0
        // ----------------------------------------------------

        write_mem(11'd0, 8'hAA);
        read_mem(11'd0, 8'hAA);

        // ----------------------------------------------------
        // Test 2: Write/read different addresses
        // ----------------------------------------------------

        write_mem(11'd1,    8'h11);
        write_mem(11'd100,  8'h55);
        write_mem(11'd500,  8'hAB);
        write_mem(11'd1024, 8'hCD);
        write_mem(11'd2047, 8'hFF);

        read_mem(11'd1,    8'h11);
        read_mem(11'd100,  8'h55);
        read_mem(11'd500,  8'hAB);
        read_mem(11'd1024, 8'hCD);
        read_mem(11'd2047, 8'hFF);

        // ----------------------------------------------------
        // Test 3: Overwrite existing data
        // ----------------------------------------------------

        write_mem(11'd100, 8'h99);
        read_mem(11'd100, 8'h99);

        // ----------------------------------------------------
        // Test 4: Fill several locations
        // ----------------------------------------------------

        for (int i = 0; i < 20; i++) begin
            write_mem(i, 8'(i));
        end

        for (int i = 0; i < 20; i++) begin
            read_mem(i, 8'(i));
        end

        // ----------------------------------------------------
        // Test 5: Boundary addresses
        // ----------------------------------------------------

        write_mem(11'd0,    8'h12);
        write_mem(11'd2047, 8'h34);

        read_mem(11'd0,    8'h12);
        read_mem(11'd2047, 8'h34);

        // ----------------------------------------------------
        // Finish
        // ----------------------------------------------------

        $display("==============================================");
        $display("        TESTBENCH COMPLETE");
        $display("==============================================");

        #20;
        $finish;
    end

endmodule
