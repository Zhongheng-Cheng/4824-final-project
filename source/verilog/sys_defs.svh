/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  sys_defs.svh                                        //
//                                                                     //
//  Description :  This file has the macro-defines for macros used in  //
//                 the pipeline design.                                //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`ifndef __SYS_DEFS_SVH__
`define __SYS_DEFS_SVH__

// all files should `include "sys_defs.svh" to at least define the timescale
`timescale 1ns/100ps

///////////////////////////////////
// ---- Starting Parameters ---- //
///////////////////////////////////

// some starting parameters that you should set
// this is *your* processor, you decide these values (try analyzing which is best!)

// superscalar width
`define N 1

// // xxxxx
// `define SUPERSCALAR_WAYS	  3
// `define N_PHYS_REG	  	  	  64
// `define N_ARCH_REG	  	  	  32
// `define N_RS_ENTRIES		  16
// `define N_ROB_ENTRIES		  32
// `define N_LSQ_ENTRIES 		  8

// `define SUPERSCALAR_WAYS_BITS $clog2(`SUPERSCALAR_WAYS)
// `define N_PHYS_REG_BITS   	  $clog2(`N_PHYS_REG)
// `define N_ARCH_REG_BITS       $clog2(`N_ARCH_REG)
// `define N_RS_ENTRIES_BITS	  $clog2(`N_RS_ENTRIES)
// `define N_ROB_ENTRIES_BITS	  $clog2(`N_ROB_ENTRIES)
// `define N_LSQ_ENTRIES_BITS	  $clog2(`N_LSQ_ENTRIES)

// `define N_ALU_UNITS			  3
// `define N_MULT_UNITS		  2
// `define N_LS_UNITS			  2
// `define N_BR_UNITS			  1
// `define N_FU_UNITS			  `N_ALU_UNITS + `N_MULT_UNITS + `N_LS_UNITS + `N_BR_UNITS
// `define N_FU_UNITS_BITS		  $clog2(`N_FU_UNITS)

// sizes
`define ROB_SZ xx
`define RS_SZ xx
`define PHYS_REG_SZ (32 + `ROB_SZ)

// worry about these later
`define BRANCH_PRED_SZ xx
`define LSQ_SZ xx

typedef enum logic [1:0] {FU_ALU, FU_MULT, FU_LOAD, FU_STORE} FU_TYPE;

// `define FU_ALU 2'b00;
// `define FU_MULT 2'b01;
// `define FU_LOAD 2'b10;
// `define FU_STORE 2'b11;

// functional units (you should decide if you want more or fewer types of FUs)
`define NUM_FU 5
`define NUM_FU_ALU 2'b01
`define NUM_FU_MULT 2'b10
`define NUM_FU_LOAD 2'b01
`define NUM_FU_STORE 2'b01

// number of mult stages (2, 4, or 8)
`define MULT_STAGES 4

//WAYS of superscalar
`define SUPERSCALAR_WAY 2

`define PHY_REG_NUM 8

///////////////////////////////
// ---- Basic Constants ---- //
///////////////////////////////

// NOTE: the global CLOCK_PERIOD is defined in the Makefile

// useful boolean single-bit definitions
`define FALSE 1'h0
`define TRUE  1'h1

// data length
`define XLEN 32

// the zero register
// In RISC-V, any read of this register returns zero and any writes are thrown away
`define ZERO_REG 5'd0

// Basic NOP instruction. Allows pipline registers to clearly be reset with
// an instruction that does nothing instead of Zero which is really an ADDI x0, x0, 0
`define NOP 32'h00000013

//////////////////////////////////
// ---- Memory Definitions ---- //
//////////////////////////////////

// Cache mode removes the byte-level interface from memory, so it always returns
// a double word. The original processor won't work with this defined. Your new
// processor will have to account for this effect on mem.
// Notably, you can no longer write data without first reading.
`define CACHE_MODE

// you are not allowed to change this definition for your final processor
// the project 3 processor has a massive boost in performance just from having no mem latency
// see if you can beat it's CPI in project 4 even with a 100ns latency!
// `define MEM_LATENCY_IN_CYCLES  0
`define MEM_LATENCY_IN_CYCLES (100.0/`CLOCK_PERIOD+0.49999)
// the 0.49999 is to force ceiling(100/period). The default behavior for
// float to integer conversion is rounding to nearest

// How many memory requests can be waiting at once
`define NUM_MEM_TAGS 15

`define MEM_SIZE_IN_BYTES (64*1024)
`define MEM_64BIT_LINES   (`MEM_SIZE_IN_BYTES/8)

/*------------------------------------Debug use------------------------------------*/
`define DEBUG 1
// `define VDEBUG 0
`define CHECK(val_1, val_2) assert(val_1 == val_2) else begin $display("Assertion Error: The input value is %h, instead of %h", val_1, val_2); error=1; end
`define NEXT_CYCLE @(negedge clk)

/*------------------------------------Module Parameters------------------------------------*/
`define PREG_NUMBER `ARCHREG_NUMBER + `ROB_SIZE // number of physical registers = architecture registers + ROB size
`define ARCHREG_NUMBER 32 // depends on ISA
`define ROB_SIZE 32 // design choice
`define RS_LENGTH 4 // design choice
`define FREELIST_SIZE `ROB_SIZE // size of free list = ROB size
`define FU_NUMBER 5
`define BRANCH_BUFFER_SIZE 32
`define FETCH_BUFFER_SIZE 16

`define SUPERSCALE_WIDTH 2
`define CDB_SIZE `SUPERSCALE_WIDTH
`define TABLE_SIZE `ARCHREG_NUMBER
`define TABLE_READ `SUPERSCALE_WIDTH*2
`define TABLE_WRITE `SUPERSCALE_WIDTH
`define LSQ_SIZE 32
`define BTB_SIZE 4



typedef union packed {
    logic [7:0][7:0]  byte_level;
    logic [3:0][15:0] half_level;
    logic [1:0][31:0] word_level;
} EXAMPLE_CACHE_BLOCK;

typedef enum logic [1:0] {
    BYTE   = 2'h0,
    HALF   = 2'h1,
    WORD   = 2'h2,
    DOUBLE = 2'h3
} MEM_SIZE;

// Memory bus commands
typedef enum logic [1:0] {
    BUS_NONE   = 2'h0,
    BUS_LOAD   = 2'h1,
    BUS_STORE  = 2'h2
} BUS_COMMAND;

///////////////////////////////
// ---- Exception Codes ---- //
///////////////////////////////

/**
 * Exception codes for when something goes wrong in the processor.
 * Note that we use HALTED_ON_WFI to signify the end of computation.
 * It's original meaning is to 'Wait For an Interrupt', but we generally
 * ignore interrupts in 470
 *
 * This mostly follows the RISC-V Privileged spec
 * except a few add-ons for our infrastructure
 * The majority of them won't be used, but it's good to know what they are
 */

typedef enum logic [3:0] {
    INST_ADDR_MISALIGN  = 4'h0,
    INST_ACCESS_FAULT   = 4'h1,
    ILLEGAL_INST        = 4'h2,
    BREAKPOINT          = 4'h3,
    LOAD_ADDR_MISALIGN  = 4'h4,
    LOAD_ACCESS_FAULT   = 4'h5,
    STORE_ADDR_MISALIGN = 4'h6,
    STORE_ACCESS_FAULT  = 4'h7,
    ECALL_U_MODE        = 4'h8,
    ECALL_S_MODE        = 4'h9,
    NO_ERROR            = 4'ha, // a reserved code that we use to signal no errors
    ECALL_M_MODE        = 4'hb,
    INST_PAGE_FAULT     = 4'hc,
    LOAD_PAGE_FAULT     = 4'hd,
    HALTED_ON_WFI       = 4'he, // 'Wait For Interrupt'. In 470, signifies the end of computation
    STORE_PAGE_FAULT    = 4'hf
} EXCEPTION_CODE;

///////////////////////////////////
// ---- Instruction Typedef ---- //
///////////////////////////////////

// from the RISC-V ISA spec
typedef union packed {
    logic [31:0] inst;
    struct packed {
        logic [6:0] funct7;
        logic [4:0] rs2; // source register 2
        logic [4:0] rs1; // source register 1
        logic [2:0] funct3;
        logic [4:0] rd; // destination register
        logic [6:0] opcode;
    } r; // register-to-register instructions
    struct packed {
        logic [11:0] imm; // immediate value for calculating address
        logic [4:0]  rs1; // source register 1 (used as address base)
        logic [2:0]  funct3;
        logic [4:0]  rd;  // destination register
        logic [6:0]  opcode;
    } i; // immediate or load instructions
    struct packed {
        logic [6:0] off; // offset[11:5] for calculating address
        logic [4:0] rs2; // source register 2
        logic [4:0] rs1; // source register 1 (used as address base)
        logic [2:0] funct3;
        logic [4:0] set; // offset[4:0] for calculating address
        logic [6:0] opcode;
    } s; // store instructions
    struct packed {
        logic       of;  // offset[12]
        logic [5:0] s;   // offset[10:5]
        logic [4:0] rs2; // source register 2
        logic [4:0] rs1; // source register 1
        logic [2:0] funct3;
        logic [3:0] et;  // offset[4:1]
        logic       f;   // offset[11]
        logic [6:0] opcode;
    } b; // branch instructions
    struct packed {
        logic [19:0] imm; // immediate value
        logic [4:0]  rd; // destination register
        logic [6:0]  opcode;
    } u; // upper-immediate instructions
    struct packed {
        logic       of; // offset[20]
        logic [9:0] et; // offset[10:1]
        logic       s;  // offset[11]
        logic [7:0] f;  // offset[19:12]
        logic [4:0] rd; // destination register
        logic [6:0] opcode;
    } j;  // jump instructions

// extensions for other instruction types
`ifdef ATOMIC_EXT
    struct packed {
        logic [4:0] funct5;
        logic       aq;
        logic       rl;
        logic [4:0] rs2;
        logic [4:0] rs1;
        logic [2:0] funct3;
        logic [4:0] rd;
        logic [6:0] opcode;
    } a; // atomic instructions
`endif
`ifdef SYSTEM_EXT
    struct packed {
        logic [11:0] csr;
        logic [4:0]  rs1;
        logic [2:0]  funct3;
        logic [4:0]  rd;
        logic [6:0]  opcode;
    } sys; // system call instructions
`endif

} INST; // instruction typedef, this should cover all types of instructions

////////////////////////////////////////
// ---- Datapath Control Signals ---- //
////////////////////////////////////////

// ALU opA input mux selects
typedef enum logic [1:0] {
    OPA_IS_RS1  = 2'h0,
    OPA_IS_NPC  = 2'h1,
    OPA_IS_PC   = 2'h2,
    OPA_IS_ZERO = 2'h3
} ALU_OPA_SELECT;

// ALU opB input mux selects
typedef enum logic [3:0] {
    OPB_IS_RS2    = 4'h0,
    OPB_IS_I_IMM  = 4'h1,
    OPB_IS_S_IMM  = 4'h2,
    OPB_IS_B_IMM  = 4'h3,
    OPB_IS_U_IMM  = 4'h4,
    OPB_IS_J_IMM  = 4'h5
} ALU_OPB_SELECT;

// ALU function code input
// probably want to leave these alone
typedef enum logic [4:0] {
    ALU_ADD     = 5'h00,
    ALU_SUB     = 5'h01,
    ALU_SLT     = 5'h02,
    ALU_SLTU    = 5'h03,
    ALU_AND     = 5'h04,
    ALU_OR      = 5'h05,
    ALU_XOR     = 5'h06,
    ALU_SLL     = 5'h07,
    ALU_SRL     = 5'h08,
    ALU_SRA     = 5'h09,
    ALU_MUL     = 5'h0a, // Mult FU
    ALU_MULH    = 5'h0b, // Mult FU
    ALU_MULHSU  = 5'h0c, // Mult FU
    ALU_MULHU   = 5'h0d, // Mult FU
    ALU_DIV     = 5'h0e, // unused
    ALU_DIVU    = 5'h0f, // unused
    ALU_REM     = 5'h10, // unused
    ALU_REMU    = 5'h11  // unused
} ALU_FUNC;


//////////////////////////////////////////////
// ----   OoO Data Structure Packets   ---- //
//////////////////////////////////////////////
typedef struct packed {
	logic tag_1_ready;
	logic tag_2_ready;
	RS_FU_PACKET fu_packet;
	logic RS_valid;
} RS_ENTRY;

typedef struct packed {
	logic [6:0] opcode;
	ALU_OPA_SELECT opa_select;
	ALU_OPB_SELECT opb_select;
	ALU_FUNC alu_opcode;
	logic rd_mem;
	logic wr_mem;
	logic cond_branch;
	logic uncond_branch;
	logic csr_op;
	logic halt;     
	logic illegal;
	DEST_REG_SEL dest_reg_sel;
	logic [31:0] extra_slot_a;
	logic [31:0] extra_slot_b;
	logic [2:0] blu_opcode;
	logic [31:0] PC;
	logic [31:0] NPC;
	logic [4:0] rs1; // fix
    logic [4:0] rs2;
	logic [2:0] mem_funct;
	logic [6:0] funct7;
} DECODE_NOREG_PACKET;

typedef enum logic [1:0] {
	MORE_LEFT = 2'h0,
	ONE_LEFT  = 2'h1,
	FULL      = 2'h2,
	ILLEGAL = 2'h3
} STRUCTURE_FULL;

typedef struct packed {
	logic [$clog2(`PREG_NUMBER)-1: 0] source_tag_1;
	logic [$clog2(`PREG_NUMBER)-1: 0] source_tag_2;
	logic [$clog2(`PREG_NUMBER)-1: 0] dest_tag;
	DECODE_NOREG_PACKET decode_noreg_packet;
} RS_FU_PACKET;

////////////////////////////////
// ---- Datapath Packets ---- //
////////////////////////////////

/**
 * Packets are used to move many variables between modules with
 * just one datatype, but can be cumbersome in some circumstances.
 *
 * Define new ones in project 4 at your own discretion
 */

/**
 * IF_ID Packet:
 * Data exchanged from the IF to the ID stage
 */
typedef struct packed {
    INST              inst;
    logic [`XLEN-1:0] PC;
    logic [`XLEN-1:0] NPC; // PC + 4
    logic             valid;
} IF_ID_PACKET;

/**
 * ID_EX Packet:
 * Data exchanged from the ID to the EX stage
 */
typedef struct packed {
    INST              inst;
    logic [`XLEN-1:0] PC;
    logic [`XLEN-1:0] NPC; // PC + 4

    logic [`XLEN-1:0] rs1_value; // reg A value
    logic [`XLEN-1:0] rs2_value; // reg B value

    ALU_OPA_SELECT opa_select; // ALU opa mux select (ALU_OPA_xxx *)
    ALU_OPB_SELECT opb_select; // ALU opb mux select (ALU_OPB_xxx *)

    logic [4:0] dest_reg_idx;  // destination (writeback) register index
    ALU_FUNC    alu_func;      // ALU function select (ALU_xxx *)
    logic       rd_mem;        // Does inst read memory?
    logic       wr_mem;        // Does inst write memory?
    logic       cond_branch;   // Is inst a conditional branch?
    logic       uncond_branch; // Is inst an unconditional branch?
    logic       halt;          // Is this a halt?
    logic       illegal;       // Is this instruction illegal?
    logic       csr_op;        // Is this a CSR operation? (we use this to get return code)

    logic       valid;
} ID_EX_PACKET;

/**
 * EX_MEM Packet:
 * Data exchanged from the EX to the MEM stage
 */
typedef struct packed {
    logic [`XLEN-1:0] alu_result;
    logic [`XLEN-1:0] NPC;

    logic             take_branch; // Is this a taken branch?
    // Pass-through from decode stage
    logic [`XLEN-1:0] rs2_value;
    logic             rd_mem;
    logic             wr_mem;
    logic [4:0]       dest_reg_idx;
    logic             halt;
    logic             illegal;
    logic             csr_op;
    logic             rd_unsigned; // Whether proc2Dmem_data is signed or unsigned
    MEM_SIZE          mem_size;
    logic             valid;
} EX_MEM_PACKET;

/**
 * MEM_WB Packet:
 * Data exchanged from the MEM to the WB stage
 *
 * Does not include data sent from the MEM stage to memory
 */
typedef struct packed {
    logic [`XLEN-1:0] result;
    logic [`XLEN-1:0] NPC;
    logic [4:0]       dest_reg_idx; // writeback destination (ZERO_REG if no writeback)
    logic             take_branch;
    logic             halt;    // not used by wb stage
    logic             illegal; // not used by wb stage
    logic             valid;
} MEM_WB_PACKET;

/**
 * No WB output packet as it would be more cumbersome than useful
 */



////////////////////////////////////
// ---- R10K Data Structures ---- //
////////////////////////////////////

// Reservation Stations related packets

// typedef struct packed {
//     logic [`N_PHYS_REG_BITS-1:0] t_idx;
// } CDB_PACKET;

// typedef struct packed{
//     logic alu_1;
//     logic alu_2;
//     logic alu_3;
//     logic mult_1;
//     logic mult_2;
//     logic branch_1;
// } FU_RS_PACKET;

typedef struct packed {
    logic [7:0] num;
    logic ready;
} REG;

typedef struct packed {
    FU_TYPE fu;
    INST inst;
    REG dest_tag;
    REG tag1;
    REG tag2;
} RS_PACKET;

`endif // __SYS_DEFS_SVH__
