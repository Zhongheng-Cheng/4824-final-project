`include "verilog/sys_defs.svh"

module testbench();

    always begin
        #(`CLOCK_PERIOD/2.0);
        clock = ~clock;
    end

    // input
    logic clock;
    logic reset;
    RS_PACKET packet_in;
    logic cdb_ready;
    REG cdb_tag;
    logic issue_enable;
    logic [4:0] free;

    // output
    logic allocate_done;
    logic issue_ready;
    RS_PACKET issued_packet;
    logic [4:0] issue_index;

    reservation_station rs1(
        
        // input
        .clock(clock),
        .reset(reset),
        .packet_in(packet_in),
        .cdb_ready(cdb_ready),
        .cdb_tag(cdb_tag),
        .issue_enable(issue_enable),
        .free(free),

        // output
        .allocate_done(allocate_done),
        .ready_issue(issue_ready),
        .issued_packet(issued_packet),
        .issue_index(issue_index)
 
    );

    task exit_on_error;
        begin
            $display("@@@Failed at time %d", $time);
            $finish;
        end
    endtask

    initial begin

        clock = 0;
        reset = 1;
        @(negedge clock)

        reset = 0;

        packet_in.fu                = LOAD;
        packet_in.inst              = 54;
        packet_in.dest_tag.reg_num  = 5;
        packet_in.dest_tag.ready    = 0;
        packet_in.tag1.reg_num      = 0;
        packet_in.tag1.ready        = 1;
        packet_in.tag2.reg_num      = 4;
        packet_in.tag2.ready        = 1;
        cdb_ready                   = 0;
        cdb_tag.reg_num             = 0;
        cdb_tag.ready               = 0;
        issue_enable                = 1;
        free                        = 5'b00000;
        
        @(negedge clock)
        assert(alloc_done) else exit_on_error;
        assert(!issue_ready) else exit_on_error;


        packet_in.fu                = MULT;
        packet_in.inst              = 64;
        packet_in.dest_tag.reg_num  = 6;
        packet_in.dest_tag.ready    = 0;
        packet_in.tag1.reg_num      = 1;
        packet_in.tag1.ready        = 1;
        packet_in.tag2.reg_num      = 5;
        packet_in.tag2.ready        = 0;
        cdb_ready                   = 0;
        cdb_tag.reg_num             = 0;
        cdb_tag.ready               = 0;
        issue_enable                = 1;
        free                        = 5'b00000;

        @(negedge clock)
        assert(alloc_done) else exit_on_error;
        assert(issue_ready) else exit_on_error;
        assert(issued_packet.fu == LOAD) else exit_on_error;
        assert(issued_packet.inst == 54) else exit_on_error;
        assert(issued_packet.dest_tag.reg_num == 5) else exit_on_error;
        assert(issued_packet.tag1.reg_num == 0) else exit_on_error;
        assert(issued_packet.tag2.reg_num == 4) else exit_on_error;
        assert(issue_index == 0) else exit_on_error;
        

        packet_in.fu                = STORE;
        packet_in.inst              = 74;
        packet_in.dest_tag.reg_num  = 0;
        packet_in.dest_tag.ready    = 1;
        packet_in.tag1.reg_num      = 6;
        packet_in.tag1.ready        = 0;
        packet_in.tag2.reg_num      = 4;
        packet_in.tag2.ready        = 1;
        cdb_ready                   = 0;
        cdb_tag.reg_num             = 0;
        cdb_tag.ready               = 0;
        issue_enable                = 1;
        free                        = 5'b01000;
        
        @(negedge clock)
        assert(alloc_done) else exit_on_error;
        assert(!issue_ready) else exit_on_error;

    
        packet_in.fu                = ALU;
        packet_in.inst              = 34;
        packet_in.dest_tag.reg_num  = 7;
        packet_in.dest_tag.ready    = 0;
        packet_in.tag1.reg_num      = 4;
        packet_in.tag1.ready        = 1;
        packet_in.tag2.reg_num      = 0;
        packet_in.tag2.ready        = 1;
        cdb_ready                   = 1;
        cdb_tag.reg_num             = 5;
        cdb_tag.ready               = 1;
        issue_enable                = 1;
        free                        = 5'b00000;

        @(negedge clock)
        assert(alloc_done) else exit_on_error;
        assert(!issue_ready) else exit_on_error;


        packet_in.fu                = LOAD;
        packet_in.inst              = 96;
        packet_in.dest_tag.reg_num  = 8;
        packet_in.dest_tag.ready    = 0;
        packet_in.tag1.reg_num      = 0;
        packet_in.tag1.ready        = 1;
        packet_in.tag2.reg_num      = 7;
        packet_in.tag2.ready        = 0;
        cdb_ready                   = 0;
        cdb_tag.reg_num             = 5;
        cdb_tag.ready               = 1;
        issue_enable                = 1;
        free                        = 5'b00010;

        @(negedge clock)
        assert(alloc_done) else exit_on_error;
        assert(issue_ready) else exit_on_error;
        assert(issued_packet.fu == ALU) else exit_on_error;
        assert(issued_packet.inst == 34) else exit_on_error;
        assert(issued_packet.dest_tag.reg_num == 7) else exit_on_error;
        assert(issued_packet.tag1.reg_num == 4) else exit_on_error;
        assert(issued_packet.tag2.reg_num == 0) else exit_on_error;
        assert(issue_index == 0) else exit_on_error;
        
        $display("@@@Passed");
        $finish;
    end 
endmodule