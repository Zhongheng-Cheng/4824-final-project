module reservation_station (
    input clock, reset,

    /* Allocating */
    input RS_PACKET packet_in,
    output logic allocate_done,

    /* Updating given PREG (from CDB) */
    input cdb_ready,
    input REG cdb_tag,

    /* Issuing */
    input logic issue_enable,
    output logic ready_issue,
    output RS_PACKET issued_packet,
    output logic [4:0] issue_index,

    /* Freeing */
    input [4:0] free
);

    RS_PACKET entries, next_entries [4:0];
    logic entry_busy,entry_busy_next [4:0];
    logic allocate, allocate_index;
    logic [4:0] issue_index_next;

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
        issue_index_next = 5'b0;

        for (int i = 0; i < 5; i++) begin
            if (entries[i].tag1.reg_ready && entries[i].tag2.reg_ready) 
                issue_index_next[i] = 1;
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

            issue_index <= 0;

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
                    if(entries.tag1.num == cdb_tag.num) entries.tag1.ready <= 1;
                    if(entries.tag2.num == cdb_tag.num) entries.tag2.ready <= 1;
                end
            end
            
		end	
	end

endmodule