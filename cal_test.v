`timescale 1ns / 1ps
module cal_test(
	input wire[1:0] mode,
	input wire game_clk,
	input wire game_clk_rst,
	input wire[4:0] type,
	input wire[3:0] x,
	input wire[4:0] y,
	input wire rotate,
	input wire left,
	input wire right,
	input wire down,
	output reg[4:0] test_type,
	output reg[3:0] test_x,
	output reg[4:0] test_y
    );
	always@(*)begin
		test_x = x;
		test_y = y;
		test_type = type;
		if(mode) begin
			if(game_clk) test_y = test_y + 5'd1;
			else if(rotate) test_type[1:0] = test_type[1:0] + 2'd1;
			else if(left) test_x = test_x - 4'd1;
			else if(right) test_x = test_x + 4'd1;
			else if(down) test_y = test_y + 5'd1;
		end
	end


endmodule
