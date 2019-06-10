`timescale 1ns / 1ps
module tetris(
	input wire sys_clk,
	input wire PS2C,
	input wire PS2D,
	input wire sw,
	output wire SEGLED_CLK,
	output wire SEGLED_DO,
	output wire SEGLED_PEN,
	output wire SEGLED_CLR,
	output wire [11:0] rgb,
	output wire hsync,
	output wire vsync
   );
	
	reg clk_count, clk;
	initial begin clk_count = 0; clk = 0; end
	always@(posedge sys_clk) begin clk_count <= ~clk_count; if(clk_count) clk <= ~clk; end
	//slow the system clock
	
	reg L_game_clk, R_game_clk;
	reg L_game_clk_rst, R_game_clk_rst;
	reg[31:0] L_counter, R_counter;
	always@(posedge clk)begin if(L_game_clk_rst) begin L_counter <= 0; L_game_clk <= 0; end
		else begin if(L_counter == 25000000) begin L_counter <= 0; L_game_clk <= 1; end
						else begin L_counter <= L_counter + 1; L_game_clk <= 0; end
		end
	end
	always@(posedge clk)begin if(R_game_clk_rst) begin R_counter <= 0; R_game_clk <= 0; end
		else begin if(R_counter == 25000000) begin R_counter <= 0; R_game_clk <= 1; end
						else begin R_counter <= R_counter + 1; R_game_clk <= 0; end
		end
	end
	//calculate the game clock
	
	reg[4:0] rand;
	initial begin rand = 0; end
	always@(posedge clk) begin if(rand == 27) rand <= 0; else rand <= rand + 5'd1; end
	//rand number
	
	
	wire [3:0]L_btn;
	wire [3:0]R_btn;
	Input Key(PS2C, PS2D, clk, {R_btn, L_btn});
	
	
	wire L_rotate, L_left, L_right, L_down;
	wire R_rotate, R_left, R_right, R_down;
	debouncer m1(L_btn[0], clk, L_rotate);
	debouncer m2(L_btn[1], clk, L_left);
	debouncer m3(L_btn[2], clk, L_right);
	debouncer m4(L_btn[3], clk, L_down);
	debouncer m5(R_btn[0], clk, R_rotate);
	debouncer m6(R_btn[1], clk, R_left);
	debouncer m7(R_btn[2], clk, R_right);
	debouncer m8(R_btn[3], clk, R_down);
	//debouncer the input
	
	wire sw_rst_en;
	debouncer m9(sw, clk, sw_rst_en);
	
	reg[19:0] TYPE[31:0];
	initial begin
		TYPE[0] = 20'h048CC;   TYPE[1] = 20'h01233;   TYPE[2] = 20'h048CC;  TYPE[3] =  20'h01233;
		TYPE[4] = 20'h04589;   TYPE[5] = 20'h14566;   TYPE[6] = 20'h14599;  TYPE[7] =  20'h01256;
		TYPE[8] = 20'h01455;   TYPE[9] = 20'h01455;  TYPE[10] = 20'h01455;  TYPE[11] = 20'h01455;
		TYPE[12] = 20'h01599; TYPE[13] = 20'h01246;  TYPE[14] = 20'h04899;  TYPE[15] = 20'h24566;
		TYPE[16] = 20'h15899; TYPE[17] = 20'h01266;  TYPE[18] = 20'h01489;  TYPE[19] = 20'h04566;
		TYPE[20] = 20'h04599; TYPE[21] = 20'h12456;  TYPE[22] = 20'h04599;  TYPE[23] = 20'h12456;
		TYPE[24] = 20'h14589; TYPE[25] = 20'h01566;  TYPE[26] = 20'h14589;  TYPE[27] = 20'h01566;
		TYPE[28] = 20'h00000; TYPE[29] = 20'h00000;  TYPE[30] = 20'h00000;  TYPE[31] = 20'h00000;
	end
	reg[239:0] L, R;
	reg[4:0] L_type, R_type, L_y, R_y;
	reg[3:0] L_x, R_x;
	wire[7:0] L_1, L_2, L_3, L_4, R_1, R_2, R_3, R_4;
	calc_pos m10(L_x, L_y, TYPE[L_type], L_1, L_2, L_3, L_4);
	calc_pos m11(R_x, R_y, TYPE[R_type], R_1, R_2, R_3, R_4);
	//calculate now position
	
	reg[1:0] L_mode, R_mode;
	
	
	//game mode
	
	reg L_isbuff ,R_isbuff;
	reg[7:0] L_buff_loc, R_buff_loc;

	wire[4:0] L_test_type, R_test_type, L_test_y, R_test_y;
	wire[3:0] L_test_x, R_test_x;
	cal_test m12(L_mode, L_game_clk, L_game_clk_rst, L_type, L_x, L_y, L_rotate, L_left, L_right, L_down, L_test_type, L_test_x, L_test_y);
	cal_test m13(R_mode, R_game_clk, R_game_clk_rst, R_type, R_x, R_y, R_rotate, R_left, R_right, R_down, R_test_type, R_test_x, R_test_y);
	wire[7:0] L_test_1, L_test_2, L_test_3, L_test_4, R_test_1, R_test_2, R_test_3, R_test_4;
	calc_pos m14(L_test_x, L_test_y, TYPE[L_test_type], L_test_1, L_test_2, L_test_3, L_test_4);
	calc_pos m15(R_test_x, R_test_y, TYPE[R_test_type], R_test_1, R_test_2, R_test_3, R_test_4);
	wire L_test_collision = L[L_test_1] | L[L_test_2] | L[L_test_3] | L[L_test_4];
	wire R_test_collision = R[R_test_1] | R[R_test_2] | R[R_test_3] | R[R_test_4];
	//calculate test position
	
	reg[4:0] L_remove_y, R_remove_y;
	initial begin L_remove_y = 0; R_remove_y = 0; L_isbuff <= 0; R_isbuff <= 0; L_buff_loc <= 0; R_buff_loc <= 0; end
	wire L_remove = &L[L_remove_y * 10 +: 10], R_remove = &R[R_remove_y * 10 +: 10];
	always@(posedge clk) begin
		if(L_mode == 1) begin
			if(L_remove_y == 23) L_remove_y <= 0;
			else L_remove_y <= L_remove_y + 5'd1;
		end
		if(R_mode == 1) begin
			if(R_remove_y == 23) R_remove_y <= 0;
			else R_remove_y <= R_remove_y + 5'd1;
		end
	end
	// find the full row
	
	initial begin L_mode = 0; L = 0; L_type = 0; L_x = 0; L_y = 0; L_score1 <= 0; L_score2 <= 0;
						R_mode = 0; R = 0; R_type = 0; R_x = 0; R_y = 0; R_score1 <= 0; R_score2 <= 0;
    end
	wire L_Gameover = |L[39:0]; 
	wire R_Gameover = |R[39:0]; 
	 
	task L_get_block;
		begin
			if (L_isbuff) L_type <= rand;
			else begin
				L_type <= 31;
				L_isbuff <= 1;
			end
			L_x <= 4;
			L_y <= 0;
			L_game_clk_rst <= 1;
		end
	endtask
	
	task R_get_block;
		begin
			if (R_isbuff) R_type <= rand;
			else begin
				R_type <= 31;
				R_isbuff <= 1;
			end
			R_x <= 4;
			R_y <= 0;
			R_game_clk_rst <= 1;
		end
	endtask
	 
	reg[7:0] L_row, R_row;
	reg L_debuff, R_debuff;
	reg [31:0] L_start, R_start;
	
		
	//wire[7:0] L_bound1 = L_row * 4'd10, L_bound2 = (L_row + 1) * 4'd10;
	//wire[7:0] R_bound1 = R_row * 4'd10, R_bound2 = (R_row + 1) * 4'd10;
	
	
	wire [7:0] L_special = L_type >= 28 && L_type < 32 ? L_1 : L_buff_loc;
	wire [7:0] R_special = R_type >= 28 && R_type < 32 ? R_1 : R_buff_loc;
	
	VGA VGA_(clk, Div[23], L_type, L_1, L_2, L_3, L_4, L, L_special, L_debuff, L_Gameover,
				R_type, R_1, R_2, R_3, R_4, R, R_special, R_debuff, R_Gameover , rgb, hsync, vsync);
	
	initial begin L_debuff <= 0; L_start <= 0; R_debuff <= 0; R_start <= 0;end
	
	
	reg[3:0] L_score1, L_score2, R_score1, R_score2;
	
	wire [3:0] sout;
	wire [31:0] Div;
	clkdiv Time(sys_clk, 1'b0, Div[31:0]);
	Seg7Device PrintNumber(.clkIO(Div[3]), .clkScan(Div[15:14]), .clkBlink(Div[25]),
									.data({4'hA,4'h0,L_score2,L_score1,4'hB,4'h0,R_score2,R_score1}), .point(8'h0), .LES(8'h0), .sout(sout));
									/*9'b000000000, L_score, 9'b000000000, R_score*/
	assign SEGLED_CLK = sout[3];
	assign SEGLED_DO = sout[2];
	assign SEGLED_PEN = sout[1];
	assign SEGLED_CLR = sout[0];
	//display--------------------------------------------------------------------------------------------------------------------
	
	always@(posedge clk)begin
		if (L_start > 0)
			begin
				if (L_start == 28'b1_00000_00000_00000_00000_00000_00)
					begin
						L_debuff <= 0;
						L_start <= 0;
					end
				else L_start <= L_start + 1;
			end
		if (R_start > 0)
			begin
				if (R_start == 28'b1_00000_00000_00000_00000_00000_00)
					begin
						R_debuff <= 0;
						R_start <= 0;
					end
				else R_start <= R_start + 1;
			end
		L_game_clk_rst <= 0;
		R_game_clk_rst <= 0;
		if(sw_rst_en) begin
			L_mode <= 1;
			L <= 0;
			L_score1 <= 0;
			L_score2 <= 0;
			L_isbuff <= 0;
			L_buff_loc <= 0;
			L_debuff <= 0;
			L_start <= 0;
			L_get_block();
			R_mode <= 1;
			R <= 0;
			R_score1 <= 0;
			R_score2 <= 0;
			R_isbuff <= 0;
			R_buff_loc <= 0;
			R_debuff <= 0;
			R_start <= 0;
			R_get_block();
		end
		else begin
		if(!L_Gameover)
		begin
			if(L_mode == 1) begin
				if(L_game_clk) begin
						if(L_y + TYPE[L_type][1:0] < 23 && !L_test_collision) L_y <= L_y + 5'd1;
						else begin
							if(L_type >= 28 && L_type < 32) L_buff_loc <= L_1;
							L[L_1] <= 1;
							L[L_2] <= 1;
							L[L_3] <= 1;
							L[L_4] <= 1;
							L_get_block();
						end
				end
				else if(L_left) begin
						if(L_x > 0 && !L_test_collision) L_x <= L_x - 4'd1;
				end
				else if(L_right) begin
						if(L_x + TYPE[L_type][3:2] < 9 && !L_test_collision) L_x <= L_x + 4'd1;
				end
				else if(L_rotate) begin
						if(L_x + TYPE[L_test_type][3:2] < 10 && L_y + TYPE[L_test_type][1:0] < 24 && !L_test_collision) L_type[1:0] <= L_type[1:0] + 2'd1;
				end	
				else if(L_down) begin
						if(L_y + TYPE[L_type][1:0] < 23 && !L_test_collision) L_y <= L_y + 5'd1;
						else begin
							if(L_type >= 28 && L_type < 32) L_buff_loc <= L_1;
							L[L_1] <= 1;
							L[L_2] <= 1;
							L[L_3] <= 1;
							L[L_4] <= 1;
							L_get_block();
						end
				end
				else if(L_remove) begin
					L_row = L_remove_y;
					if(L_isbuff && L_remove_y * 4'd10 <= L_buff_loc && (L_remove_y + 1) * 4'd10 > L_buff_loc)
						begin 
							L_isbuff <= 0;
							L_buff_loc <= 0;
							R_debuff <= 1;
							R_start <= 1;
						end
					if (L_score1 == 9)
						begin
							L_score2 <= L_score2 + 1;
							L_score1 <= 0;
						end
					else L_score1 <= L_score1 + 1;
					
					L_mode <= 2;
				end
			end
			else if(L_mode == 2) begin
				if(L_row == 0) begin
					L[0 +: 10] <= 0;
					L_mode <= 1;
				end
				else begin
					L[L_row * 10 +: 10] <= L[(L_row - 1) * 10 +: 10];
					if(L_isbuff && (L_row - 1) * 10 <= L_buff_loc && L_row * 10 > L_buff_loc) L_buff_loc <= L_buff_loc + 10;
					L_row = L_row - 5'd1;
				end
			end
		end
		if(!R_Gameover)
		begin
			if(R_mode == 1) begin
				if(R_game_clk) begin
						if(R_y + TYPE[R_type][1:0] < 23 && !R_test_collision) R_y <= R_y + 5'd1;
						else begin
							if(R_type >= 28 && R_type < 32) R_buff_loc <= R_1;
							R[R_1] <= 1;
							R[R_2] <= 1;
							R[R_3] <= 1;
							R[R_4] <= 1;
							R_get_block();
						end
				end
				else if(R_left) begin
						if(R_x > 0 && !R_test_collision) R_x <= R_x - 4'd1;
				end
				else if(R_right) begin
						if(R_x + TYPE[R_type][3:2] < 9 && !R_test_collision) R_x <= R_x + 4'd1;
				end
				else if(R_rotate) begin
						if(R_x + TYPE[R_test_type][3:2] < 10 && R_y + TYPE[R_test_type][1:0] < 24 && !R_test_collision) R_type[1:0] <= R_type[1:0] + 2'd1;
				end	
				else if(R_down) begin
						if(R_y + TYPE[R_type][1:0] < 23 && !R_test_collision) R_y <= R_y + 5'd1;
						else begin
							if(R_type >= 28 && R_type < 32) R_buff_loc <= R_1;
							R[R_1] <= 1;
							R[R_2] <= 1;
							R[R_3] <= 1;
							R[R_4] <= 1;
							R_get_block();
						end
				end
				else if(R_remove) begin
					R_row = R_remove_y;
					if(R_isbuff && R_remove_y * 4'd10 <= R_buff_loc && (R_remove_y + 1) * 4'd10 > R_buff_loc)
						begin 
							R_isbuff <= 0;
							R_buff_loc <= 0;
							L_debuff <= 1;
							L_start <= 1;
						end
					if (R_score1 == 9)
						begin
							R_score2 <= R_score2 + 1;
							R_score1 <= 0;
						end
					else R_score1 <= R_score1 + 1;
					R_mode <= 2;
				end
			end
			else if(R_mode == 2) begin
				if(R_row == 0) begin
					R[0 +: 10] <= 0;
					R_mode <= 1;
				end
				else begin
					R[R_row * 10 +: 10] <= R[(R_row - 1) * 10 +: 10];
					if(R_isbuff && (R_row - 1) * 10 <= R_buff_loc && R_row * 10 > R_buff_loc) R_buff_loc <= R_buff_loc + 10;
					R_row = R_row - 5'd1;
				end
			end
		end
	end
end
endmodule
