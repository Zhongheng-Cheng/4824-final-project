
`timescale 1ns/100ps

module arch (
    input                                                        clock,
    input                                                        reset,
    input  RETIRE_PACKET [`SUPERSCALAR_WAYS-1:0]                 arch_retire_in,

    output logic         [`N_ARCH_REG-1:0][`N_PHYS_REG_BITS-1:0] arch_maptable
);
    logic [`N_ARCH_REG-1:0][`N_PHYS_REG_BITS-1:0] am_rst;
    logic [`N_ARCH_REG-1:0][`N_PHYS_REG_BITS-1:0] am_next;
    
    always_comb begin
        for (int i = 0; i < `N_ARCH_REG; i++)
            am_rst[i] = i;
    end  // always_comb  //  am_rst

    always_comb begin	
        am_next = arch_maptable;
       	for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
            if (arch_retire_in[i].complete)
                am_next[arch_retire_in[i].ar_idx] = arch_retire_in[i].t_idx;
        end  // for each tag from the retire stage
    end  // always_comb  // am_next

    always_ff @(posedge clock) begin
        if (reset)  arch_maptable <= `SD am_rst;
        else        arch_maptable <= `SD am_next;
    end  // always_ff @(posedge clock)
endmodule  // arch