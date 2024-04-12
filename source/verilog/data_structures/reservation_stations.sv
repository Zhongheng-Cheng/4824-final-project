
module reservation_station (
    input clock, reset,
    /* Allocating */
    input RS_PACKET packet_in,
    output logic allocate_done,

    /* Updating given PREG (from CDB) */
    input cdb_ready,
    input REG cdb_tag,        //TODO: change name, change REG num

    /* Issuing */
    input logic issue_enable,
    output logic ready_issue,
    output RS_PACKET issued_packet,
    output logic [4:0] issue_index,

    /* Freeing */
    input [4:0] free
);

    RS_PACKET entries[5];
    RS_PACKET next_entries [5];
    logic entry_busy [4:0];
    logic entry_busy_next [4:0];
    logic allocate, allocate_index;
    logic [4:0] issue_index_next;
    logic ready_to_issue;

    always_comb begin
        allocate = 0;
        case (packet_in.fu)
            FU_ALU: begin
                if (!entry_busy[0]) begin
                    allocate = 1;
                    allocate_index = 0;
                end
            end
            FU_LOAD: begin
                if (!entry_busy[1]) begin
                    allocate = 1;
                    allocate_index = 1;
                end
            end
            FU_STORE: begin
                if (!entry_busy[2]) begin
                    allocate = 1;
                    allocate_index = 2;
                end
            end
            FU_MULT: begin
                if (!entry_busy[3]) begin
                    allocate = 1;
                    allocate_index = 3;
                end
                if (!entry_busy[4]) begin
                    allocate = 1;
                    allocate_index = 4;
                end
            end
        endcase
    end

    always_comb begin 
        entry_busy_next = entry_busy; 
        for(int i=0; i<5; i++)begin
            if(free[i]) begin
                entry_busy_next[i] = 0;
            end
        end
    end

    always_comb begin
        //issue_index_next = 5'b0;
        ready_issue = 1'b1;
        for (int i = 0; i < 5; i++) begin
            if (entries[i].tag1.ready && entries[i].tag2.ready) 
                issue_index_next[i] = 1'b1;
            else begin
                issue_index_next[i] = 1'b0;
            end
            if (entries[i].tag1.ready != 1'b1 || entries[i].tag2.ready != 1'b1 || reset ) begin
                ready_issue = 1'b0;
            end

        end
    end

  
    
    always_ff @(posedge clock) begin
		if(reset) begin
            entries <= {0,0,0,0,0};
            entries[0].fu <= FU_ALU;
            entries[1].fu <= FU_LOAD;
            entries[2].fu <= FU_STORE;
            entries[3].fu <= FU_MULT;
            entries[4].fu <= FU_MULT;

           entry_busy <= '{5{1'b0}}; 

            issue_index <= '{5{1'b0}};
		end

		else begin
            issue_index <= issue_index_next;
            entry_busy <= entry_busy_next;

			if (allocate) begin
                entries[allocate_index] <= packet_in;
                allocate_done <=1;
            end

            if (ready_issue && issue_enable) begin
                issued_packet <= entries[issue_index_next];
            end

            if(cdb_ready)begin
                for(int i=0; i<5; i++)begin
                    if(entries[i].tag1.num == cdb_tag.num) entries[i].tag1.ready <= 1'b1;
                    if(entries[i].tag2.num == cdb_tag.num) entries[i].tag2.ready <= 1'b1;
                end
            end


            
		end	
	end

endmodule
=======
`ifndef __RS_SV__
`define __RS_SV__
`include "verilog/ISA.svh"


// `timescale 1ns/100ps

module rs(
	`ifdef DEBUG
	output RS_ENTRY [`RS_LENGTH-1 : 0] entries_debug,
	`endif

	input logic                                             clk,
	input logic                                             reset,

	input logic [1:0]                                       dispatch_en_i,
    input logic [$clog2(`PREG_NUMBER) - 1 : 0]              dest_tag_i,     // Dispatch: from Freelist
    input logic [$clog2(`PREG_NUMBER) - 1 : 0]              source_tag_1_i, // Dispatch: from Maptable
    input logic                                             ready_1_i,      // Dispatch: from Maptable
    input logic [$clog2(`PREG_NUMBER) - 1 : 0]              source_tag_2_i, // Dispatch: from Maptable
    input logic                                             ready_2_i,      // Dispatch: from Maptbale
	input DECODE_NOREG_PACKET                               RS_decode_noreg_packet,

	input logic [1:0]                                       branch_recover_i, //enable for branch
    input logic [$clog2(`PREG_NUMBER)-1 : 0]                CDB_i,//WB: from CDB
	input logic [1:0]                                       CDB_en_i,

    input logic [`FU_NUMBER-1:0]                            fu_ready_i, //issue: from ALU

	output STRUCTURE_FULL                                   RS_full_o,  // To control
	output logic [`RS_LENGTH-1 : 0]                         execute_en_o, // Issue: To FU
	output RS_FU_PACKET 							        FU_packet_o,   // Issue: To FU
	output logic [`FU_NUMBER-1:0]                           FU_select_en_o,
	output logic [`FU_NUMBER-1:0]                           FU_select_RS_port_o
);
	integer i;
    integer j;
	integer k;
	integer issue_break;

	RS_ENTRY [`RS_LENGTH-1 : 0] entries;
	RS_ENTRY [`RS_LENGTH-1 : 0] next_entries;
	
	`ifdef DEBUG
	assign entries_debug = next_entries;
	`endif

	//issue
	logic [`RS_LENGTH-1 : 0]                 next_execute_en_o;
	RS_FU_PACKET 							 next_fu_packet_o;
	logic [`FU_NUMBER-1:0]                   next_FU_select_en;
	logic [`FU_NUMBER-1:0]                   next_FU_select_RS_port;
	logic [`FU_NUMBER-1:0]                   FU_map;
	logic [`FU_NUMBER-1:0]                   FU_available;
	logic [`FU_NUMBER-1:0]                   fu_useful;
	//counter
	integer count;

	//check valid_tag for reg1 and reg2 
	always_comb begin
		
		next_fu_packet_o = 0;
		next_execute_en_o = 0;
		next_entries = entries;
		next_FU_select_en = 0;
		next_FU_select_RS_port = 0;
		FU_map = 0;

		if (branch_recover_i[0]) begin
    		for (int idx = 0; idx < `RS_LENGTH; idx++) begin
        		next_entries[idx] = '{default:0};  
    		end

		end else begin
			// Complete: check CDB 
			if(CDB_en_i[i]) begin
				for(j = 0; j < `RS_LENGTH; j++) begin
					if(next_entries[j].RS_valid) begin
						if(next_entries[j].fu_packet.source_tag_1 == CDB_i[i]) begin
							next_entries[j].tag_1_ready = 1'b1; 				
						end
						if(next_entries[j].fu_packet.source_tag_2 == CDB_i[i]) begin
							next_entries[j].tag_2_ready = 1'b1; 				
						end 
					end
				end	
			end	
		
			// Issue: issue logic
			FU_available = 5'b11111;
			issue_break = 0;
			FU_available = fu_ready_i;
			j = 0;	
			for(k = 0; k < `RS_LENGTH && issue_break < 2; k++) begin
				if(next_entries[k].RS_valid) begin
					// check if issue
					case(next_entries[k].fu_packet.decode_noreg_packet.opcode)	
						`RV32_LOAD, `RV32_STORE: 				   FU_map = `FU_NUMBER'b01000;
						`RV32_BRANCH, `RV32_JALR_OP, `RV32_JAL_OP: FU_map = `FU_NUMBER'b00100;
						default:                                   FU_map = `FU_NUMBER'b00011;
					endcase
					fu_useful = FU_map & FU_available;
					if(next_entries[k].tag_1_ready && next_entries[k].tag_2_ready && fu_useful > 0) begin						
						next_entries[k].RS_valid       = 1'b0;                      // clear entry					
						next_execute_en_o[issue_break] = 1'b1;                      // enable issue
						next_fu_packet_o[issue_break]  = next_entries[k].fu_packet;
						issue_break = issue_break + 1;
						for(i = 0; i < `FU_NUMBER; i++) begin
							if(fu_useful[i]) begin
								next_FU_select_en[i]      = 1'b1;
								next_FU_select_RS_port[i] = j;    // from which rs port 
								FU_available[i] = 1'b0;
								j = j + 1'b1;
								break;
							end
						end
					end	
				end						
			end

			count = 0; 
			for(k = 0; k < `RS_LENGTH; k++) begin
				if(!next_entries[k].RS_valid) begin
					count = count + 1;
				end
			end
			RS_full_o = count == 0 ? FULL : count == 1 ? ONE_LEFT : MORE_LEFT;
			// Dispatch
			j = 0;
			if(dispatch_en_i[0]) begin 
				for(k = 0; k < `RS_LENGTH && j < 1 + dispatch_en_i[1]; k++) begin
					if(!next_entries[k].RS_valid) begin
						next_entries[k].RS_valid = 1'b1;
						next_entries[k].tag_1_ready = ready_1_i[j];
						next_entries[k].tag_2_ready = ready_2_i[j];
						next_entries[k].fu_packet.source_tag_1 = source_tag_1_i[j];
						next_entries[k].fu_packet.source_tag_2 = source_tag_2_i[j];
						next_entries[k].fu_packet.dest_tag     = dest_tag_i[j];
						next_entries[k].fu_packet.decode_noreg_packet = RS_decode_noreg_packet[j];//fix
						j = j + 1;
					end
				end
			end
		end
	end


	//seq logic
	always_ff @( posedge clk ) begin
		if(reset) begin
			entries             <= {0, 0, 0, 0};
			execute_en_o        <= 0;
			FU_packet_o         <= {0, 0};
			FU_select_en_o      <= 0;
			FU_select_RS_port_o <= 0;
		end
		else begin
			entries             <= next_entries;
			execute_en_o        <= next_execute_en_o;
			FU_packet_o         <= next_fu_packet_o;
			FU_select_en_o      <= next_FU_select_en;
			FU_select_RS_port_o <= next_FU_select_RS_port;
		end	
	end
endmodule

`endif //__RS_SV__


