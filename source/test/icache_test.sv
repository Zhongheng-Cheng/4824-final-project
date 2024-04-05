`timescale 1ns / 1ps

module icache_tb;

    // Testbench uses a 100MHz clock
    parameter CLOCK_PERIOD = 10;

    reg clock;
    reg reset;

    // Memory to processor interface
    reg [3:0]  Imem2proc_response;
    reg [63:0] Imem2proc_data;
    reg [3:0]  Imem2proc_tag;

    // Processor to cache interface
    reg [31:0] proc2Icache_addr;

    // Cache to memory interface
    wire [1:0]       proc2Imem_command;
    wire [31:0]      proc2Imem_addr;

    // Cache to processor interface
    wire [63:0] Icache_data_out;
    wire        Icache_valid_out;

    // Instance of the icache module
    icache UUT (
        .clock(clock),
        .reset(reset),
        .Imem2proc_response(Imem2proc_response),
        .Imem2proc_data(Imem2proc_data),
        .Imem2proc_tag(Imem2proc_tag),
        .proc2Icache_addr(proc2Icache_addr),
        .proc2Imem_command(proc2Imem_command),
        .proc2Imem_addr(proc2Imem_addr),
        .Icache_data_out(Icache_data_out),
        .Icache_valid_out(Icache_valid_out)
    );

    // Clock generation
    always #(CLOCK_PERIOD/2) clock = ~clock;

    // Monitor signals and check conditions
    initial begin
        // Initialize inputs
        clock = 0;
        reset = 1;
        Imem2proc_response = 0;
        Imem2proc_data = 0;
        Imem2proc_tag = 0;
        proc2Icache_addr = 0;

        // Reset system
        #20;
        reset = 0;
        $display("[%0t] System reset.", $time);

        // Example test 1: Request a memory address that causes a cache miss
        #20;
        proc2Icache_addr = 32'h0000_0400; // Set address to request
        Imem2proc_response = 4'h1;        // Simulate memory response tag
        Imem2proc_data = 64'hdead_beef_cafe_babe; // Simulate memory data
        Imem2proc_tag = 4'h1;             // Simulate tag matching the request
        $display("[%0t] Cache miss test: Requested address %h", $time, proc2Icache_addr);
        
        // Wait for the response to be processed and data to be loaded into cache
        #100;

        // Clear memory interface to avoid re-triggering
        Imem2proc_response = 0;
        Imem2proc_data = 0;
        Imem2proc_tag = 0;

        // Check if cache line updated
        if (Icache_valid_out && Icache_data_out == 64'hdead_beef_cafe_babe) begin
            $display("[%0t] Cache update success for address %h.", $time, proc2Icache_addr);
        end else begin
            $display("[%0t] ERROR: Cache update failed for address %h.", $time, proc2Icache_addr);
        end

        // Example test 2: Request the same memory address again to simulate a cache hit
        #20;
        proc2Icache_addr = 32'h0000_0400; // Request the same address again
        $display("[%0t] Cache hit test: Requested address %h", $time, proc2Icache_addr);

        // Wait for the cache to respond
        #20;

        // Check for cache hit
        if (Icache_valid_out) begin
            $display("[%0t] Cache hit confirmed for address %h.", $time, proc2Icache_addr);
        end else begin
            $display("[%0t] ERROR: Cache hit failed for address %h.", $time, proc2Icache_addr);
        end

        $display("Pass!!!");

        $finish;
    end

endmodule