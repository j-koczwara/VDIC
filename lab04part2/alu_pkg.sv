
package alu_pkg;
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
	
`include "coverage.svh"
`include "tester.svh"
`include "scoreboard.svh"
`include "testbench.svh"
endpackage : alu_pkg