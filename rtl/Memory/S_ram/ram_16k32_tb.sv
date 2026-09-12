module ram_16k32_tb;

reg clk;
reg we;
reg [13:0] addr;
reg [31:0] din;
wire [31:0] dout;

integer errors;
integer i;

reg [31:0] expected_mem [0:16383];

ram_16k32 DUT (
    .clk  (clk),
    .we   (we),
    .addr (addr),
    .din  (din),
    .dout (dout)
);

always #5 clk = ~clk;


//----------------------------------
// WRITE TASK
//----------------------------------

task write_mem;
    input [13:0] address;
    input [31:0] data;

    begin

        @(negedge clk);

        we   = 1;
        addr = address;
        din  = data;

        @(posedge clk);
        #1;

        expected_mem[address] = data;

        $display("WRITE: Address=%0d Data=%h",
                 address, data);

    end
endtask


//----------------------------------
// READ + CHECK TASK
//----------------------------------

task read_check;
    input [13:0] address;
    input [31:0] expected;

    begin

        @(negedge clk);

        we   = 0;
        addr = address;

        @(posedge clk);
        #1;

        if (dout === expected) begin

            $display("PASS: Address=%0d Expected=%h Got=%h",
                     address, expected, dout);

        end

        else begin

            $display("FAIL: Address=%0d Expected=%h Got=%h",
                     address, expected, dout);

            errors = errors + 1;

        end

    end
endtask


//----------------------------------
// MAIN TEST
//----------------------------------

initial begin

    clk    = 0;
    we     = 0;
    addr   = 0;
    din    = 0;
    errors = 0;

    // Initialize reference memory
    for (i = 0; i < 16384; i = i + 1)
        expected_mem[i] = 32'h00000000;


    //----------------------------------
    // RANDOM TEST VECTORS
    //----------------------------------

    repeat (100) begin

        // RANDOM WRITE

        write_mem(
            $urandom_range(0, 16383),
            $urandom
        );


        // RANDOM READ

        begin
            integer random_addr;

            random_addr = $urandom_range(0, 16383);

            read_check(
                random_addr,
                expected_mem[random_addr]
            );
        end

    end


    //----------------------------------
    // FINAL RESULT
    //----------------------------------

    if (errors == 0)

        $display("\n******** ALL TESTS PASSED ********");

    else

        $display("\n******** %0d TESTS FAILED ********",
                 errors);

    $finish;

end

endmodule
