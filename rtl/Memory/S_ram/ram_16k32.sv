module ram_16k32 (
	input clk,
	input we,
	input [13:0] addr,
	input [31:0] din,
	output reg [31:0] dout,
	input rst
	);
integer i;
	reg [31:0] mem [0:16383];

	always @(posedge clk or negedge rst) begin
		if (rst) begin
			for (i = 0; i < 16384; i = i + 1)
        			mem[i] <= 32'h00000000;
			end
		else begin
		if (we) mem[addr] <= din;
		else dout <= mem[addr];
		end
	end
endmodule
