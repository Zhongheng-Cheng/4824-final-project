`timescale 1ns/100ps

//define priority selector for fu
module fu_ps(
    input [5:0] done_fu,
    output logic [2:0] done_sel
);
    always_comb begin
        casez (done_fu)
            6'b1????? : done_sel = 3'd5;
            6'b01???? : done_sel = 3'd4;
            6'b001??? : done_sel = 3'd3;
            6'b0001?? : done_sel = 3'd2;
            6'b00001? : done_sel = 3'd1;
            6'b000001 : done_sel = 3'd0;
            default: done_sel = 3'd0;
        endcase
    end
endmodule

//process the update of the ps
module fu_process(
    input clock,
    input reset,
    input [5:0] new_done_fu,
    output logic stall,
    output logic [2:0] buffer_sel
);

    logic [5:0] current_done_fu;
    logic [5:0] next_done_fu;
    logic [5:0] temp_done;

    fu_ps fu_ps1(
        .done_fu(next_done_fu),
        .done_sel(buffer_sel)
    );

    always_ff @ (posedge clock or posedge reset) begin
        if(reset) begin
           // stall <= 1'b0;
            current_done_fu <= 6'b0;
            //next_done_fu <= 6'b0;
        end else begin
            current_done_fu <= temp_done;
        end
    end

    always_comb begin
        if ((new_done_fu & current_done_fu) != 6'b0) begin
            stall = 1'b1;
        end else begin 
            stall = 1'b0;
            next_done_fu = (current_done_fu|new_done_fu); //merge the old done with new done
           // if (|next_done_fu)
	    temp_done = next_done_fu;
            temp_done[buffer_sel] = 1'b0;
        end
    end
endmodule

module fu (
	input 											   	clock,
	input 											   	reset,
	input  ISSUE_FU_PACKET 	  	                        fu_issue_in,

	output FU_COMPLETE_PACKET 	                        fu_complete_out,
	output FU_RS_PACKET 							   	fu_rs_out,
	output FU_PRF_PACKET 	  	[6:0] 				   	fu_prf_out,
    output logic                                        stall,
    logic [2:0]                                         done_fu_sel
);

    logic br_done, mult1_done, mult2_done, alu1_done, alu2_done, alu3_done;
    logic [5:0] done_fu, done_tmp;
    assign done_fu = {br_done, mult1_done, mult2_done, alu1_done, alu2_done, alu3_done};
    //logic [2:0] done_fu_sel;

    logic [2:0] count0, count1, count2, count3, count4, count5, count6, count7;

    //FU_COMPLETE_PACKET [2:0] fu_complete_out_unorder;
    logic [7:0] want_to_complete;  // LS_1 = 0, LS_2 = 1, ALU_1 = 2, ALU_2 = 3, ALU_3 = 4, MULT_1 = 5, MULT_2 = 6,

    ISSUE_FU_PACKET fu_issue_in_alu1,  fu_issue_in_alu2,  fu_issue_in_alu3;
	ISSUE_FU_PACKET fu_issue_in_mult1, fu_issue_in_mult2;
	ISSUE_FU_PACKET fu_issue_in_br;

    FU_COMPLETE_PACKET fu_complete_out_ls1,   fu_complete_out_ls2;
    FU_COMPLETE_PACKET fu_complete_out_alu1,  fu_complete_out_alu2,  fu_complete_out_alu3;
	FU_COMPLETE_PACKET fu_complete_out_mult1, fu_complete_out_mult2;
	FU_COMPLETE_PACKET fu_complete_out_br;
    FU_COMPLETE_PACKET fu_complete_out_alu1_tmp,  fu_complete_out_alu2_tmp,  fu_complete_out_alu3_tmp;
	FU_COMPLETE_PACKET fu_complete_out_mult1_tmp, fu_complete_out_mult2_tmp;
	FU_COMPLETE_PACKET fu_complete_out_br_tmp;
    FU_COMPLETE_PACKET fu_complete_out_buffer [5:0];
    FU_COMPLETE_PACKET fu_complete_out_unorder [5:0];  //mult1,mult2,alu1,alu2,alu3,br

    FU_COMPLETE_PACKET alu1_reg_packet,  alu2_reg_packet,  alu3_reg_packet;
	FU_COMPLETE_PACKET mult1_reg_packet, mult2_reg_packet;

    logic alu1_reg_has_value_pre,  alu2_reg_has_value_pre,  alu3_reg_has_value_pre;
	logic mult1_reg_has_value_pre, mult2_reg_has_value_pre;

    FU_COMPLETE_PACKET fu_complete_out_alu1_reg, fu_complete_out_alu2_reg, fu_complete_out_alu3_reg;
	FU_COMPLETE_PACKET fu_complete_out_mult1_reg, fu_complete_out_mult2_reg, fu_complete_out_br_reg;

	logic want_to_complete_alu1_reg, want_to_complete_alu2_reg, want_to_complete_alu3_reg;
	logic want_to_complete_br_reg,mult_1_finish_reg,mult_2_finish_reg;

    logic mult1_has_value, mult2_has_value, alu1_has_value, alu2_has_value, alu3_has_value, br_has_value;

    logic [`XLEN-1:0] mult1_a, mult1_b, mult2_a, mult2_b;
	logic [`XLEN-1:0] mult1_result, mult2_result;
	logic [4:0] 	  mult1_finish, mult2_finish;
	logic 			  mult1_start, mult2_start;
    logic [5:0]       buffer_empty ;
    logic [5:0]       buffer_empty_mid ;

    logic alu1_reg_has_value,  alu2_reg_has_value,  alu3_reg_has_value;
	logic mult1_reg_has_value, mult2_reg_has_value;

    fu_process fu_process1(
        .clock(clock),
        .reset(reset),
        .new_done_fu(done_fu),
        .stall(stall),
        .buffer_sel(done_fu_sel)
    );

//starting packet transfer
    always_comb begin
		fu_issue_in_alu1  = '0;
		fu_issue_in_alu2  = '0;
		fu_issue_in_alu3  = '0;
		fu_issue_in_mult1 = '0;
		fu_issue_in_mult2 = '0;
		fu_issue_in_br    = '0;

		mult1_a 	= '0;
		mult1_b 	= '0;
		mult2_a 	= '0;
		mult2_b 	= '0;
		mult1_start = '0;
		mult2_start = '0;

        case (fu_issue_in.fu_select)
            ALU_1:   fu_issue_in_alu1 = fu_issue_in;
            ALU_2:   fu_issue_in_alu2 = fu_issue_in;
            ALU_3:   fu_issue_in_alu3 = fu_issue_in;
            MULT_1:  begin
                mult1_a			  = fu_issue_in.rs1_value;
                mult1_b			  = fu_issue_in.rs2_value;
                mult1_start		  = `TRUE;
                fu_issue_in_mult1 = fu_issue_in;
            end
            MULT_2:  begin
                mult2_a			  = fu_issue_in.rs1_value;
                mult2_b			  = fu_issue_in.rs2_value;
                mult2_start 	  = `TRUE;
                fu_issue_in_mult2 = fu_issue_in;
            end
            BRANCH:  fu_issue_in_br = fu_issue_in;
        endcase  
	end  

    fu_alu alu1 (
		.fu_issue_in(fu_issue_in_alu1),
		.want_to_complete(want_to_complete[2]),
		.fu_packet_out(fu_complete_out_alu1)
	);

	fu_alu alu2 (
		.fu_issue_in(fu_issue_in_alu2),
		.want_to_complete(want_to_complete[3]),
		.fu_packet_out(fu_complete_out_alu2)
	);

	fu_alu alu3 (
		.fu_issue_in(fu_issue_in_alu3),
		.want_to_complete(want_to_complete[4]),
		.fu_packet_out(fu_complete_out_alu3)
	);

	mult mult1 (
		.clock(clock), 
		.reset(reset),
		.mcand(mult1_a),
		.mplier(mult1_b),
		.sign(2'd0),
		.start(mult1_start),
		.mult_func(fu_issue_in_mult1.mult_func),
		.fu_issue_in(fu_issue_in_mult1),
		.done(mult1_finish),
		.fu_complete_out(fu_complete_out_mult1)
	);

	mult mult2 (
		.clock(clock), 
		.reset(reset),
		.mcand(mult2_a),
		.mplier(mult2_b),
		.sign(2'd0),
		.start(mult2_start),
		.mult_func(fu_issue_in_mult2.mult_func),
		.fu_issue_in(fu_issue_in_mult2),
		.done(mult2_finish),
		.fu_complete_out(fu_complete_out_mult2)
	);

	fu_alu br (
		.fu_issue_in(fu_issue_in_br),
		.want_to_complete(want_to_complete[7]),
		.fu_packet_out(fu_complete_out_br)
	);

    assign ls1_done   = `FALSE;
	assign ls2_done   = `FALSE;
	assign alu1_done  = want_to_complete_alu1_reg;//want_to_complete_alu1_reg;
	assign alu2_done  = want_to_complete_alu2_reg;//want_to_complete_alu2_reg;
	assign alu3_done  = want_to_complete_alu3_reg;//want_to_complete_alu3_reg;
	assign mult1_done = mult1_finish[4];
	assign mult2_done = mult2_finish[4];
	assign br_done    = want_to_complete_br_reg;//want_to_complete_br_reg;

    assign fu_complete_out_mult1_tmp = fu_complete_out_mult1;
    assign fu_complete_out_mult2_tmp = fu_complete_out_mult2;
    assign fu_complete_out_alu1_tmp = fu_complete_out_alu1;
    assign fu_complete_out_alu2_tmp = fu_complete_out_alu2;
    assign fu_complete_out_alu3_tmp = fu_complete_out_alu3;
    assign fu_complete_out_br_tmp = fu_complete_out_br;


    always_comb begin
		fu_prf_out = '0;

		if (alu1_done) begin
			fu_prf_out[2].idx   = fu_complete_out_buffer[2].pr_idx;
			fu_prf_out[2].value = fu_complete_out_buffer[2].dest_value;
        end 

		if (alu2_done) begin
			fu_prf_out[3].idx   = fu_complete_out_buffer[3].pr_idx;
			fu_prf_out[3].value = fu_complete_out_buffer[3].dest_value;
		end 

		if (alu3_done) begin
			fu_prf_out[4].idx = fu_complete_out_buffer[4].pr_idx;
			fu_prf_out[4].value = fu_complete_out_buffer[4].dest_value;
		end 

		if (mult1_done) begin
			fu_prf_out[5].idx = fu_complete_out_buffer[0].pr_idx;
			fu_prf_out[5].value = fu_complete_out_buffer[0].dest_value;
		end 

		if (mult2_done) begin
			fu_prf_out[6].idx = fu_complete_out_buffer[1].pr_idx;
			fu_prf_out[6].value = fu_complete_out_buffer[1].dest_value;
		end
	end

    always_ff@(posedge clock or posedge reset) begin
        if(reset) begin
           
            mult1_reg_has_value_pre	  <= `SD `FALSE;
			mult2_reg_has_value_pre	  <= `SD `FALSE;
			alu1_reg_has_value_pre	  <= `SD `FALSE;
			alu2_reg_has_value_pre	  <= `SD `FALSE;
			alu3_reg_has_value_pre	  <= `SD `FALSE;
            fu_complete_out_buffer[0] <= '0;
            fu_complete_out_buffer[1] <= '0;
            fu_complete_out_buffer[2] <= '0;
            fu_complete_out_buffer[3] <= '0;
            fu_complete_out_buffer[4] <= '0;
            fu_complete_out_buffer[5] <= '0;
            mult_1_finish_reg <= `SD `FALSE;
            mult_2_finish_reg <= `SD `FALSE;
            want_to_complete_br_reg	  <= `SD `FALSE;
			want_to_complete_alu1_reg <= `SD `FALSE;
			want_to_complete_alu2_reg <= `SD `FALSE;
			want_to_complete_alu3_reg <= `SD `FALSE;
    
        end else begin
            
            mult1_reg_has_value_pre	  <= `SD mult1_reg_has_value;
			mult2_reg_has_value_pre	  <= `SD mult2_reg_has_value;
			alu1_reg_has_value_pre	  <= `SD alu1_reg_has_value;
			alu2_reg_has_value_pre	  <= `SD alu2_reg_has_value;
			alu3_reg_has_value_pre	  <= `SD alu3_reg_has_value;

            fu_complete_out_buffer[0] <= (!buffer_empty[4]) ? fu_complete_out_mult1_tmp : fu_complete_out_buffer[0];
            fu_complete_out_buffer[1] <= (!buffer_empty[3]) ? fu_complete_out_mult2_tmp : fu_complete_out_buffer[1];
            fu_complete_out_buffer[2] <= (!buffer_empty[2]) ? fu_complete_out_alu1_tmp : fu_complete_out_buffer[2];
            fu_complete_out_buffer[3] <= (!buffer_empty[1]) ? fu_complete_out_alu2_tmp : fu_complete_out_buffer[3];
            fu_complete_out_buffer[4] <= (!buffer_empty[0]) ? fu_complete_out_alu3_tmp : fu_complete_out_buffer[4];          
            fu_complete_out_buffer[5] <= (!buffer_empty[5]) ? fu_complete_out_br_tmp : fu_complete_out_buffer[5]; 
            buffer_empty <= done_fu;
            mult_1_finish_reg <= mult1_finish[4];
            mult_2_finish_reg <= mult2_finish[4];
            want_to_complete_br_reg	  <= `SD want_to_complete[7];
			want_to_complete_alu1_reg <= `SD want_to_complete[2];
			want_to_complete_alu2_reg <= `SD want_to_complete[3];
			want_to_complete_alu3_reg <= `SD want_to_complete[4];
        end
    end

/*  always_comb begin
        fu_complete_out_unorder[0] = (!buffer_empty[4]) ?  fu_complete_out_mult1_tmp : fu_complete_out_buffer[0];
        fu_complete_out_unorder[1] = (!buffer_empty[3]) ?  fu_complete_out_mult2_tmp : fu_complete_out_buffer[1];
        fu_complete_out_unorder[2] = (!buffer_empty[2]) ?  fu_complete_out_alu1_tmp : fu_complete_out_buffer[2];
        fu_complete_out_unorder[3] = (!buffer_empty[1]) ?  fu_complete_out_alu2_tmp : fu_complete_out_buffer[3];
        fu_complete_out_unorder[4] = (!buffer_empty[0]) ?  fu_complete_out_alu3_tmp : fu_complete_out_buffer[4];
        fu_complete_out_unorder[5] = (!buffer_empty[5]) ?  fu_complete_out_alu1_tmp : fu_complete_out_buffer[5];
    end */

	always_comb begin
		fu_rs_out = '0;

		if (mult1_done)
			fu_rs_out.mult_1 = `TRUE;

		if (mult2_done)//mult2_finish[4] |mult2_finish[4:0]))
			fu_rs_out.mult_2 = `TRUE;

		if ((alu1_done))
			fu_rs_out.alu_1 = `TRUE;

		if (alu2_done)
			fu_rs_out.alu_2 = `TRUE;

		if (done_tmp[2])
			fu_rs_out.alu_3 = `TRUE;
	end

    always_comb begin
        //buffer_empty = buffer_empty_mid;
        done_tmp = buffer_empty;
      //  buffer_empty = done_fu;
        casez(done_fu_sel) 
            3'd4 : begin
                fu_complete_out = fu_complete_out_buffer[0];
                //fu_rs_out.mult_1 = `TRUE;
                done_tmp[4] = 0;
            end
            3'd3 : begin
                fu_complete_out = fu_complete_out_buffer[1];
                //fu_rs_out.mult_2 = `TRUE;
                done_tmp[3] = 0;
            end
            3'd2 : begin
                fu_complete_out = fu_complete_out_buffer[2];
                //fu_rs_out.alu_1 = `TRUE;  
                done_tmp[2] = 0;
            end
            3'd1 : begin
                fu_complete_out = fu_complete_out_buffer[3];
                //fu_rs_out.alu_2 = `TRUE; 
                done_tmp[1] = 0;
            end
            3'd0 : begin
                fu_complete_out = fu_complete_out_buffer[4]; 
                //fu_rs_out.alu_3 = `TRUE; 
                done_tmp[0] = 0;
            end 
            3'd5 : begin
                fu_complete_out = fu_complete_out_buffer[5];
                done_tmp[5] = 0; 
            end
            default : begin
                fu_complete_out = '0;
                done_tmp = '0;
                //buffer_empty = '0;
                
            end
        endcase
    end
    
endmodule








