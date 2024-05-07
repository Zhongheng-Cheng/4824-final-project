
`timescale 1ns/100ps

module complete (
    input  FU_COMPLETE_PACKET  [`SUPERSCALAR_WAYS-1:0] complete_fu_in,
    output COMPLETE_ROB_PACKET [`SUPERSCALAR_WAYS-1:0] complete_rob_out,  // [4:0] rob_idx, complete, valid
    output CDB_PACKET                                  cdb_out            // we have 3 CDB entries
);
    always_comb begin
        for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
            cdb_out.t_idx[i] = (complete_fu_in[i].valid & ~complete_fu_in[i].take_branch) ? 
                               complete_fu_in[i].pr_idx : '0;
        end
    end  // always_comb  // cdb_out

    // Set complete_rob_out
    always_comb begin
        complete_rob_out = '0;
        for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
            if (complete_fu_in[i].valid) begin
                complete_rob_out[i].complete             = `TRUE;
                complete_rob_out[i].rob_idx              = complete_fu_in[i].rob_idx;
                complete_rob_out[i].dest_value           = complete_fu_in[i].dest_value;
                complete_rob_out[i].precise_state_enable = complete_fu_in[i].take_branch;
                complete_rob_out[i].target_pc            = complete_fu_in[i].target_pc;
                complete_rob_out[i].wr_mem               = complete_fu_in[i].wr_mem;
                complete_rob_out[i].rd_mem               = complete_fu_in[i].rd_mem;
                complete_rob_out[i].opb                  = complete_fu_in[i].opb;
                complete_rob_out[i].pr_idx               = complete_fu_in[i].pr_idx;
                complete_rob_out[i].read_data            = complete_fu_in[i].read_data;

            end  // if (complete_fu_in[i].valid)
        end  // for each complete_rob_out
    end  // always_comb  // ROB
endmodule  // complete