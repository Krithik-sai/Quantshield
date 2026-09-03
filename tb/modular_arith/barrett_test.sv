`timescale 1ns/1ps

module tb_barrett_mult;

    // Inputs
    logic [23:0] B;
    logic [23:0] W;
    logic        mod_sel;

    // Output
    logic [23:0] result_T;

    // Expected result
    logic [23:0] expected_T;

    logic [47:0] expected_product;

    // DUT
    barrett_mult DUT (
        .B(B),
        .W(W),
        .mod_sel(mod_sel),
        .result_T(result_T)
    );

    // Test task
    task test_case(
        input logic [23:0] test_B,
        input logic [23:0] test_W,
        input logic        test_mod_sel
    );

        begin
            B       = test_B;
            W       = test_W;
            mod_sel = test_mod_sel;

            #10;

            if (test_mod_sel == 1'b0) begin
                expected_product = test_B * test_W;
                expected_T = expected_product % 24'd3329;
            end
            else begin
                expected_product = test_B * test_W;
                expected_T = expected_product % 24'd8380417;
            end
            if (result_T == expected_T)
                $display("PASS: B=%0d W=%0d mod_sel=%0d Result=%0d Expected=%0d",
                         test_B, test_W, test_mod_sel, result_T, expected_T);
            else
                $display("FAIL: B=%0d W=%0d mod_sel=%0d Result=%0d Expected=%0d",
                         test_B, test_W, test_mod_sel, result_T, expected_T);
        end

    endtask


    initial begin

        $display("========================================");
        $display("      Barrett Multiplier Testbench");
        $display("========================================");

        // -----------------------------
        // Kyber tests
        // mod_sel = 0
        // q = 3329
        // -----------------------------

        test_case(24'd10,   24'd20,   1'b0);
        test_case(24'd100,  24'd200,  1'b0);
        test_case(24'd1000, 24'd2000, 1'b0);
        test_case(24'd3328, 24'd3328, 1'b0);

        // -----------------------------
        // Dilithium tests
        // mod_sel = 1
        // q = 8380417
        // -----------------------------

        test_case(24'd10,      24'd20,      1'b1);
        test_case(24'd1000,    24'd2000,    1'b1);
        test_case(24'd100000,  24'd200000,  1'b1);
        test_case(24'd8380416, 24'd8380416, 1'b1);

        $display("========================================");
        $display("             Test Complete");
        $display("========================================");

        $finish;

    end

endmodule