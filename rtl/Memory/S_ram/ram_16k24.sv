module ram_16k24 (
	input clk,
	input we,
	input [13:0] addr,
	input [23:0] din,
	output reg [23:0] dout
	);
	
	reg [23:0] mem [0:1023];
	
	always @(posedge clk) begin
		if (we)
			mem[addr] <= din;
		dout <= mem[addr];
	end
endmodule
