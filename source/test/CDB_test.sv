`timescale 1ns / 1ps

module CDB_tb;


    `define NUM_FU 5
    `define SUPERSCALAR_WAY 2
    `define PHY_REG_NUM 8

  
    reg clk;
    reg reset;
    reg [`NUM_FU-1:0] FU_complete_i;
    reg [`NUM_FU-1:0][$clog2(`PHY_REG_NUM)-1:0] ready_reg_index;
    wire [`SUPERSCALAR_WAY-1:0] CDB_en_o;
    wire [`SUPERSCALAR_WAY-1:0][$clog2(`PHY_REG_NUM)-1:0] CDB_o;


    CDB uut (
        .clk(clk),
        .reset(reset),
        .FU_complete_i(FU_complete_i),
        .ready_reg_index(ready_reg_index),
        .CDB_en_o(CDB_en_o),
        .CDB_o(CDB_o)
    );

  
    always #10 clk = ~clk;

   
    initial begin
       
        clk = 0;
        reset = 1;
        FU_complete_i = 0;
        ready_reg_index = 0;

    
        #20;
        reset = 0;

       
        #20;
        FU_complete_i = 5'b00001; 
        ready_reg_index[0] = 3'b010; 
        check_outputs(1'b1, 3'b010);

     
        #20;
        FU_complete_i = 5'b00011; 
        ready_reg_index[0] = 3'b101; 
        ready_reg_index[1] = 3'b001; 
        check_outputs(2'b11, {3'b001, 3'b101}); 

        
        #100;
        $finish;
    end

    task check_outputs;
        input [1:0] expected_en;
        input [5:0] expected_output; 
        begin
            #1; 
            if (CDB_en_o !== expected_en || CDB_o !== expected_output) begin
                $display("Error at time %t: expected CDB_en_o=%b, CDB_o=%b, but got CDB_en_o=%b, CDB_o=%b",
                         $time, expected_en, expected_output, CDB_en_o, CDB_o);
            end else begin
                $display("Test passed at time %t: CDB_en_o=%b, CDB_o=%b",
                         $time, CDB_en_o, CDB_o);
            end
        end
    endtask

    initial begin
        $monitor("At time %t, reset = %b, FU_complete_i = %b, CDB_en_o = %b, CDB_o = %b", $time, reset, FU_complete_i, CDB_en_o, CDB_o);
    end

endmodule
