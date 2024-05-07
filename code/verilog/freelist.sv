
`timescale 1ns/100ps

module freelist (
    input                                                   clock, 
    input                                                   reset,
	input  DISPATCH_FREELIST_PACKET                         freelist_dispatch_in,
	input  RETIRE_FREELIST_PACKET   [`SUPERSCALAR_WAYS-1:0] freelist_retire_in,
    input                                                   br_recover_enable,
    input  MAPTABLE_PACKET                                  recovery_maptable,

	output FREELIST_DISPATCH_PACKET                         freelist_dispatch_out


);
	logic [`N_PHYS_REG-1:0]                        freelist, next_freelist;
    logic [`N_PHYS_REG-1:0]                        free_index;
    logic [`SUPERSCALAR_WAYS-1:0]                  req;
    logic [`SUPERSCALAR_WAYS-1:0][`N_PHYS_REG-1:0] gnt_free_index;
    logic [`SUPERSCALAR_WAYS-1:0][`N_PHYS_REG-1:0] sel_req;



    always_comb begin
        if (br_recover_enable) begin
            for (int i = 0; i < `N_PHYS_REG; i++)
                free_index[i] = `TRUE;
            for (int i = 0; i < `N_ARCH_REG; i++)
                free_index[recovery_maptable.map[i]] = `FALSE;
        end  // if (br_recover_enable)
        else begin
            free_index = freelist;
            for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
                if (freelist_retire_in[i].valid)
                    free_index[freelist_retire_in[i].told_idx] = `TRUE;
            end  // for each retired instruction
        end  // if (~br_recover_enable)
    end  // always_comb  // free_index

    always_comb begin
        sel_req[0] = free_index;
        for (int i = 1; i < `SUPERSCALAR_WAYS; i++)
            sel_req[i] = (sel_req[i - 1] & ~gnt_free_index[i - 1]);
    end  // always_comb  // sel_req

    genvar p; generate
        for (p = 0; p < `SUPERSCALAR_WAYS; p++) begin : sel
            ps_freelist ps_0 (
                .req(sel_req[p]),
                .en(`TRUE),
                .gnt(gnt_free_index[p]), 
                .req_up(req[p])
            );
        end  // for each sel ps submodule
    endgenerate  // generate sel ps submodules

    always_comb begin
        next_freelist         = free_index;
        freelist_dispatch_out = '0;

        for (int i = 0; i < `N_PHYS_REG ; i++) begin
            for (int j = 0; j < `SUPERSCALAR_WAYS; j++) begin
                if (gnt_free_index[j][i] & freelist_dispatch_in.new_pr_en[j]) begin
                    next_freelist[i]               = `FALSE;
                    freelist_dispatch_out.t_idx[j] = i;
                    freelist_dispatch_out.valid[j] = `TRUE;
                end  // if the pr is requested and granted
            end  // for each dispatched instruction
        end  // for each physical register
    end  // always_comb  // freelist_dispatch_out

    always_ff @(posedge clock) begin
        if (reset) begin
            freelist[`N_PHYS_REG-1:`N_ARCH_REG] <= `SD { (`N_PHYS_REG-`N_ARCH_REG){`TRUE} };
            freelist[`N_ARCH_REG-1:0]           <= `SD { `N_ARCH_REG{`FALSE} };
        end  // if (reset)
        else freelist <= `SD next_freelist;
    end  // always_ff @(posedge clock)
endmodule  // freelist