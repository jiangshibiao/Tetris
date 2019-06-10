`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:12:56 02/09/2014 
// Design Name: 
// Module Name:    Input 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Input(PS2C,PS2D,clk25,state);

input PS2C;
input PS2D;
input clk25;
output reg [7:0]state;

wire [15:0]xkey;

initial state<=0;

keyboard(clk25,1'b0,PS2C,PS2D,xkey);

always begin
	if((xkey[7:4]==4'hf)&&(xkey[3:0]==4'h0))
	begin 
		if( ((xkey[15:12]==4'h1)&&(xkey[11:8]==4'hd)) || ((xkey[15:12]==4'h1)&&(xkey[11:8]==4'hc)) ||
			 ((xkey[15:12]==4'h2)&&(xkey[11:8]==4'h3)) || ((xkey[15:12]==4'h1)&&(xkey[11:8]==4'hb)))																//第一位是f0，即松键
		state[3:0]<=4'b0000;
		else 
		if( ((xkey[15:12]==4'h7)&&(xkey[11:8]==4'h5)) || ((xkey[15:12]==4'h6)&&(xkey[11:8]==4'hB)) ||
			 ((xkey[15:12]==4'h7)&&(xkey[11:8]==4'h4)) || ((xkey[15:12]==4'h7)&&(xkey[11:8]==4'h2)))																//第一位是f0，即松键
		state[7:4]<=4'b0000;
	end 
	else if((xkey[15:12]==4'h1)&&(xkey[11:8]==4'hd))	//W
		state[3:0]<=4'b0001;
	else if((xkey[15:12]==4'h1)&&(xkey[11:8]==4'hc))	//A
		state[3:0]<=4'b0010;
	else if((xkey[15:12]==4'h2)&&(xkey[11:8]==4'h3))	//D
		state[3:0]<=4'b0100;
	else if((xkey[15:12]==4'h1)&&(xkey[11:8]==4'hb))	//S
		state[3:0]<=4'b1000;
	else if((xkey[15:12]==4'h7)&&(xkey[11:8]==4'h5))	//8
		state[7:4]<=4'b0001;
	else if((xkey[15:12]==4'h6)&&(xkey[11:8]==4'hB))	//4
		state[7:4]<=4'b0010;
	else if((xkey[15:12]==4'h7)&&(xkey[11:8]==4'h4))	//6
		state[7:4]<=4'b0100;
	else if((xkey[15:12]==4'h7)&&(xkey[11:8]==4'h2))	//5
		state[7:4]<=4'b1000;
	else	                              					//无效输入
		state<=8'b00000000;
end
endmodule
