
package alu_pkg;
	import uvm_pkg::*;
`include "uvm_macros.svh"
	typedef enum bit[2:0] {
		and_op                   = 3'b000,
		or_op                    = 3'b001,
		add_op                   = 3'b100,
		sub_op                   = 3'b101,
		notused2_op              = 3'b010,
		notused3_op              = 3'b011,
		reset_op                 = 3'b111

	} operation_t;

	typedef enum bit[5:0] {
		ERR_DATA                 = 6'b100100,
		ERR_CRC                  = 6'b010010,
		ERR_OP                   = 6'b001001,
		CHECK_ERROR              = 6'b111111

	} error_flag;

	typedef struct packed {
		bit signed        [31:0]  A;
		bit signed        [31:0]  B;
		operation_t         op;
		bit                 crc_ok;
		bit         [3:0]   crc;
		bit         [3:0]   data_len;
		bit         [3:0]   expected_flag;
		bit 				done;

	} command_s;

	typedef struct packed {
		error_flag                error_flag;
		bit signed  [31:0]        C_data;
		bit         [3:0]         flag_out;
		bit         [2:0]         CRC37;
		bit         [1:0]         data_type;
		
	} result_s;

`include "coverage.svh"
`include "base_tester.svh"
`include "random_tester.svh"
`include "scoreboard.svh"
`include "driver.svh"
`include "command_monitor.svh"
`include "result_monitor.svh"
`include "env.svh"
`include "random_test.svh"
`include "minmax_arg_tester.svh"
`include "minmax_arg_test.svh"
endpackage : alu_pkg