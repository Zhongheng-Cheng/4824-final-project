module reservation_station (
    input clock, reset,

    /* Allocating */
    input RS_PACKET input_packet,
    output logic done,

    /* Updating given PREG (from CDB) */
    input update,
    input logic [8:0] ready_reg,

    /* Issuing */
    input logic issue_enable,
    output logic ready_issue,
    output RS_PACKET issued_packet,
    output logic [`MAX_FU_INDEX-1:0] issue_fu_index,

    /* Freeing */
    input [4:0] free;
    // input [`NUM_FU_ALU-1:0] free_alu.
    // input [`NUM_FU_MULT-1:0] free_mult,
    // input [`NUM_FU_LOAD-1:0] free_load,
    // input [`NUM_FU_STORE-1:0] free_store
    
    // input logic [`MAX FU INDEX-1:0] free fu index,
    // input FUNIT free funit
);

    RS_PACKET entries, next_entries [4:0];
    logic entry_busy [4:0];
    logic allocate, allocate_index;

    always_comb begin
        allocate = 0;
        case (input_packet.fu)
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
        for(int i=0; i<5; i++)begin
            if(free[i]) begin
                entry_busy[i] = 0;
            end
        end
    end

    logic [4:0] both_reg_ready;
    always_comb begin
        for (int i = 0; i < 5; i++) begin
            if (entries[i].src1_reg.reg_ready && entries[i].src2_reg.reg_ready) 
                both_reg_ready[i] = 1;
        end
    end

    always_ff @(posedge clock) begin
		if(reset) begin
            entries <= 0;
            entries[0].fu <= FU_ALU;
            entries[1].fu <= FU_LOAD;
            entries[2].fu <= FU_STORE;
            entries[3].fu <= FU_MULT;
            entries[4].fu <= FU_MULT;
            entry_busy <= 0;
            both_reg_ready <= 0;
		end
		else begin
			if (allocate) begin
                entries[allocate_index] <= input_packet;
            end
            if (issue_enable && entries)
            
		end	
	end

endmodule