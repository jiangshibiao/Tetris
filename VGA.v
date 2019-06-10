module VGA (
	input wire                      vga_clk,
	 input wire 						  Div,
    input wire [4:0]               L_type,
    input wire [7:0]               L_1,
    input wire [7:0]               L_2,
    input wire [7:0]               L_3,
    input wire [7:0]               L_4,
    input wire [239:0] 				  L,
	 input wire [7:0]					  L_special,
	 input wire 						  L_debuff,
	 input wire 						  L_Gameover,
	 
	 input wire [4:0]               R_type,
    input wire [7:0]               R_1,
    input wire [7:0]               R_2,
    input wire [7:0]               R_3,
    input wire [7:0]               R_4,
    input wire [239:0] 				  R,
	 input wire [7:0]					  R_special,
	 input wire 						  R_debuff,
	 input wire 						  R_Gameover,
	 
    output reg [11:0]              rgb,
    output wire                    hsync,
    output wire                    vsync
    );
	wire [11:0] rgbw,rgbw_l,rgbw_r;
	reg [7:0] L_u,L_v,R_u,R_v;
   reg [9:0] h_count;
   always @ (posedge vga_clk) begin
       if (h_count == 10'd799) h_count <= 10'h0;
       else h_count <= h_count + 10'h1;
   end
   // v_count: VGA vertical counter (0-524)
   reg [9:0] v_count; // VGA vertical   counter (0-524): lines
   always @ (posedge vga_clk) begin
       if (h_count == 10'd799) begin
           if (v_count == 10'd524) v_count <= 10'h0;
			  else v_count <= v_count + 10'h1;
       end
   end
    // signals, will be latched for outputs
	 
    wire  [9:0] row    =  v_count - 10'd35;     // pixel ram row addr 
    wire  [9:0] col    =  h_count - 10'd143;    // pixel ram col addr 
    assign hsync = (h_count > 10'd95);    //  96 -> 799
    assign vsync = (v_count > 10'd1);     //   2 -> 524
    wire   read  = (h_count > 10'd142) && // 143 -> 782
                   (h_count < 10'd783) && //        640 pixels
                   (v_count > 10'd34)  && //  35 -> 514
                   (v_count < 10'd515);   //        480 line
	
	 wire [9:0] q = (col / 5'd20) - ((col < 280) ? 10'd4 : 10'd18);
	 wire [9:0] p = (row / 5'd20) + 10'd2;
	 wire [9:0] cur_blk_index = p * 4'd10 + q;
    // vga signals
	 always @ (posedge Div) 
	 begin 
		if(L_debuff)
			begin 
				if(L_u == 9) L_u <= 0; else L_u <= L_u +1;
				if(L_v == 9) L_v <= 0; else L_v <= L_v +1;
			end 
		else 
			begin  
				L_u <= 0; 
				L_v <= 5; 
			end 
		if(R_debuff)
			begin 
				if(R_u == 9) R_u <= 0; else R_u <= R_u +1;
				if(R_v == 9) R_v <= 0; else R_v <= R_v +1;
			end 
		else 
			begin  
				R_u <= 0; 
				R_v <= 5; 
			end 
	 end
	 wire [9:0] L_u_pixel = 80 +  L_u * 20 , L_v_pixel = 80 +  L_v * 20;
	 wire [9:0] R_u_pixel = 360 + R_u * 20 , R_v_pixel = 360 + R_v * 20;
	 
	 wire [18:0] addr = (row)*640 + col ;
	// wire rgbw;
	 wire [14:0] addr_l_over = (row-80)*200+col-80;
	 wire [14:0] addr_r_over = (row-80)*200+col-360;
	 wire L_p = ((L_u<L_v)&&(col >= L_u_pixel && col < L_v_pixel)|| (L_u > L_v) && ( col>=L_u_pixel  || col< L_v_pixel ));
	 wire R_p = ((R_u<R_v)&&(col >= R_u_pixel && col < R_v_pixel)|| (R_u > R_v) && ( col>=R_u_pixel  || col< R_v_pixel ));
	background(vga_clk, 0, addr ,0, rgbw);
	over(vga_clk,0,addr_l_over,0,rgbw_l);
	over(vga_clk,0,addr_r_over,0,rgbw_r);
    always @ (posedge vga_clk) begin
				rgb = rgbw;
				if (read && row >= 40 && row < 440) begin
					if (col >= 80 && col < 280) 
					begin 
						if(L_Gameover) 
							if(row>= 80 && row<180 ) rgb = rgbw_l ;
						if(!L_Gameover && L_debuff && L_p)
							rgb = 12'hFFF;
						else 					
						begin
							if(!L_Gameover)
							if (cur_blk_index == L_special) rgb = 12'h0FF; 
							else if (cur_blk_index == L_1 || cur_blk_index == L_2 || cur_blk_index == L_3 || cur_blk_index == L_4) rgb = 12'h0F0;
									else rgb = L[cur_blk_index] ? 12'hF00 : 12'h00F ; 
						end
					end
					else if(col >= 360 && col < 560) begin
							if(R_Gameover)
								if(row>=80 && row<180) rgb=rgbw_r ;
						if(!R_Gameover && R_debuff && R_p)
							rgb = 12'hFFF;
						else 					
						begin
							if(!R_Gameover)
							if (cur_blk_index == R_special) rgb = 12'h0FF; 
							else if (cur_blk_index == R_1 || cur_blk_index == R_4 || cur_blk_index == R_2 || cur_blk_index == R_3) rgb = 12'h0F0;
									else rgb = R[cur_blk_index] ? 12'hF00 : 12'h00F  ; end
						end
				end
    end
endmodule 