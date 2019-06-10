`timescale 1ns / 1ps

module calc_pos(
	input wire[3:0] x,
	input wire[4:0] y,
	input wire[19:0] type,
	output reg[7:0] L_1,
	output reg[7:0] L_2,
	output reg[7:0] L_3,
	output reg[7:0] L_4
    );
	always@(*) begin
		L_1 = (x + type[19:18]) + (y + type[17:16]) * 8'd10;
		L_2 = (x + type[15:14]) + (y + type[13:12]) * 8'd10;
		L_3 = (x + type[11:10]) + (y + type[9:8])   * 8'd10;
		L_4 = (x + type[7:6])   + (y + type[5:4])   * 8'd10;
	end

endmodule
