`define NUM_FU 5
`define SUPERSCALAR_WAY 2
`define PHY_REG_NUM 8

module CDB(
    input clk,
    input reset,

    input logic [`NUM_FU-1: 0] FU_complete_i,
    input logic [`NUM_FU-1: 0] [$clog2(`PHY_REG_NUM)-1: 0] ready_reg_index,


    output logic  [`SUPERSCALAR_WAY-1:0] CDB_en_o,
    output logic  [`SUPERSCALAR_WAY-1:0] [$clog2(`PHY_REG_NUM)-1: 0] CDB_o

);
    integer i;
    integer j;

    logic  [`SUPERSCALAR_WAY-1:0] next_CDB_en;
    logic [`SUPERSCALAR_WAY-1:0] [$clog2(`PHY_REG_NUM)-1: 0] next_CDB;

    always_comb begin

        next_CDB_en = 0;
        next_CDB = 0;
        j = 0;
        for(i = 0; i < `NUM_FU & j < 2'h2; i++) begin 
            if(FU_complete_i[i]) begin
                next_CDB_en[j] = 1'b1;
                next_CDB[j] = ready_reg_index[i];
                j = j + 1'b1;
            end
        end
    end

    always_ff @(posedge clk) begin
        if(reset) begin
            CDB_en_o <= 0;
            CDB_o <= 0;

        end else begin
            CDB_en_o <= next_CDB_en;
            CDB_o <= next_CDB;
        end
    end

endmodule