/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Module Name :  sq.sv                                               //
//                                                                     //
//  Description :                                                      // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module sq (
    input clock, 
    input reset,

    input [`SUPERSCALAR_WAYS-1:0] dispatch_store,
    output logic [`SUPERSCALAR_WAYS-1:0] dispatch_stall,
    output logic [`SUPERSCALAR_WAYS-1:0][`N_LSQ_ENTRIES_BITS-1:0] dispatch_idx,

    output logic [`N_LSQ_ENTRIES-1:0] load_tail_ready,

    input [`SUPERSCALAR_WAYS-1:0] alu_valid,
    input SQ_ENTRY_PACKET [`SUPERSCALAR_WAYS-1:0] alu_store,
    input [`SUPERSCALAR_WAYS-1:0][`N_LSQ_ENTRIES_BITS-1:0] alu_idx,

    input LOAD_SQ_PACKET [1:0] load_lookup,
    output SQ_LOAD_PACKET [1:0] load_forward,

    input [`SUPERSCALAR_WAYS-1:0] retire_store,
    output SQ_ENTRY_PACKET [`SUPERSCALAR_WAYS-1:0] cache_wb,
    output SQ_ENTRY_PACKET [`SUPERSCALAR_WAYS-1:0] sq_head  

    `ifdef TEST_MODE
    , output SQ_ENTRY_PACKET [0:`N_LSQ_ENTRIES-1] sq_reg_display
    , output logic [`N_LSQ_ENTRIES_BITS-1:0] head_display, tail_display
    `endif
);

// Registers and signals
logic [1:0] num_dispatch_store, num_retire_store;
SQ_ENTRY_PACKET [0:`N_LSQ_ENTRIES-1] sq_reg, sq_reg_next;
logic [`N_LSQ_ENTRIES_BITS-1:0] head, tail, nxt_head, nxt_tail;
logic [`N_LSQ_ENTRIES_BITS-1:0] filled_entries_num, empty_entries_num, nxt_filled_entries_num;

// Calculating numbers of operations
assign num_dispatch_store = |dispatch_store;
assign num_retire_store = |retire_store;
assign empty_entries_num = `N_LSQ_ENTRIES - filled_entries_num;

always_ff @(posedge clock) begin
    if (reset) begin
        head <= 0;
        tail <= 0;
        filled_entries_num <= 0;
        sq_reg <= {`N_LSQ_ENTRIES{SQ_ENTRY_PACKET'{default:0}}};
    end else begin
        head <= nxt_head;
        tail <= nxt_tail;
        filled_entries_num <= nxt_filled_entries_num;
        sq_reg <= sq_reg_next;
    end
end

always_comb begin
    nxt_head = head + num_retire_store;
    nxt_tail = tail + num_dispatch_store;
    nxt_filled_entries_num = filled_entries_num + num_dispatch_store - num_retire_store;

    // Dispatch stall logic
    dispatch_stall = empty_entries_num < `SUPERSCALAR_WAYS ? '1 : '0;

    // Assign dispatch indices
    foreach (dispatch_store[i]) begin
        dispatch_idx[i] = tail + i;
    end

    // ALU store updates
    foreach (alu_valid[i]) begin
        if (alu_valid[i]) sq_reg_next[alu_idx[i]] = alu_store[i];
    end

    // Retire and cache write-back
    foreach (retire_store[i]) begin
        cache_wb[i] = sq_reg[head + i];
        sq_reg_next[head + i] = '0;
    end
    sq_head = cache_wb;

    // Forwarding logic for load units
    for (int i = 0; i < 2; i++) begin
        load_forward[i].data = '0;
        load_forward[i].usebytes = '0;
        for (int j = 0; j < `N_LSQ_ENTRIES; j++) begin
            if (sq_reg[j].addr == load_lookup[i].addr && sq_reg[j].ready) begin
                load_forward[i].data |= sq_reg[j].data;
                load_forward[i].usebytes |= sq_reg[j].usebytes;
            end
        end
    end
end

`ifdef TEST_MODE
assign sq_reg_display = sq_reg;
assign head_display = head;
assign tail_display = tail;
`endif

endmodule
