module reservation_station (
    input clock, reset,

    /* Allocating */
    input allocate,
    input RS_PACKET input_packet,
    output logic done,

    /* Updating given PREG (from CDB) */
    input update,
    input PREG ready_reg,

    /* Issuing */
    input logic issue_enable,
    output logic ready,
    output RS_PACKET issued_packet,
    output logic [`MAX_FU_INDEX-1:0] issue_fu_index,

    /* Freeing */
    input [`NUM_FU_ALU-1:0] free_alu.
    input [`NUM_FU_MULT-1:0] free_mult,
    input [`NUM_FU_LOAD-1:0] free_load,
    input [`NUM_FU_STORE-1:0] free_store
    
    // input logic [`MAX FU INDEX-1:0] free fu index,
    // input FUNIT free funit
);

    always_ff @(posedge clock) begin
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