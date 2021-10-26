/*
 Copyright 2013 Ray Salemi

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

 History:
 2021-10-05 RSz, AGH UST - test modified to send all the data on negedge clk
 and check the data on the correct clock edge (covergroup on posedge
 and scoreboard on negedge). Scoreboard and coverage removed.
 */
module top;

//------------------------------------------------------------------------------
// type and variable definitions
//------------------------------------------------------------------------------

	typedef enum bit[2:0] {
		and_op      		     = 3'b000,
		or_op                    = 3'b001,
		add_op                   = 3'b100,
		sub_op                   = 3'b101,
		notused2_op			 	 = 3'b010,
		notused3_op				 = 3'b011,
		notused7_op				 = 3'b111

	} operation_t;
	bit         [31:0]  A;
	bit         [31:0]  B;
	bit                 clk;
	bit                 reset, rst_n;
	bit         [3:0]   crc;
	operation_t         op_set;
	bit			[3:0]	data_len;
	bit			[98:0]  data_in;
	string              test_result = "PASSED";
	bit 		[63:0] BA;

//------------------------------------------------------------------------------
// DUT instantiation
//------------------------------------------------------------------------------
	bit sin;
	wire sout;
	
	mtm_Alu u_mtm_Alu (
		.clk  (clk), //posedge active clock
		.rst_n(rst_n), //synchronous reset active low
		.sin  (sin), //serial data input
		.sout (sout) //serial data output
	);
//------------------------------------------------------------------------------
// Clock generator
//------------------------------------------------------------------------------

	initial begin : clk_gen
		clk = 0;
		forever begin : clk_frv
			#10;
			clk = ~clk;
		end
	end

//------------------------------------------------------------------------------
// Tester
//------------------------------------------------------------------------------



//------------------------
// Tester main

	initial begin : tester
		reset_alu();
		#1us
		repeat (100) begin : tester_main
			@(negedge clk);
			@(negedge clk);
			@(negedge clk);
			@(negedge clk);
			op_set = get_op();
			A      = get_data();
			B      = get_data();
			crc    = get_crc(A,B,op_set);
			reset  = get_rst();
			data_len =get_data_len();
			
			/*op_set = or_op;
			A      = '1;
			B      = '1;
			crc    = get_crc(A,B,op_set);
			reset  = 0;*/
			BA={B,A};
			case(reset)
				1: begin
					reset_alu();
				end
				0:begin
					data_in=get_vector_to_send(BA, op_set, crc, data_len);
					for (int i = 0; i < (11*(data_len+1)); i++) begin: serial_send
						@(negedge clk);
						sin = data_in[(11*(data_len+1))-1-i];	
						
					end
					wait(!sout);
					#1.5us;					
					
				end
			endcase		
			
			
		end: tester_main
		$finish;
	end : tester
//------------------------------------------------------------------------------
// reset task
//------------------------------------------------------------------------------
	task reset_alu();
		rst_n = 1'b0;
		sin   = 1'b1;
		@(negedge clk);
		rst_n = 1'b1;
	endtask

//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// get data function
//------------------------------------------------------------------------------
	function [31:0] get_data();
		randcase
			80:		return 32'($random);
			10: 	return '0;
			10: 	return '1;	 
		endcase	

	endfunction : get_data
	
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// get reset function
//------------------------------------------------------------------------------
	function bit get_rst();
		randcase
			90:		return '0;
			10: 	return '1;
		endcase	

	endfunction : get_rst
	
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// get reset function
//------------------------------------------------------------------------------
	function bit [3:0] get_data_len();
		randcase
			90:		return 8;
			5: 		return  $random%3+9; //more
			5:		return  $random%3+5; //less
		endcase	

	endfunction : get_data_len
	
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// get op function
//------------------------------------------------------------------------------
	function operation_t get_op();
		operation_t         op;	
		bit					ok;
		ok=randomize(op) with {op dist {and_op:=3, sub_op:=3, or_op:=3, add_op:=3, notused2_op:=1, notused3_op:=1, notused7_op:=1 };};
		return op;

	endfunction : get_op
	
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// get vector to send 
//------------------------------------------------------------------------------
	function bit [98:0] get_vector_to_send(bit [63:0] BA, operation_t OP, bit [3:0] crc, bit [4:0] data_len );
		bit [98:0] vector_out;
		
		for(int i = 0; i<data_len; i++)begin
			vector_out[98-(i*11)-:11]={2'b00, BA[63-(i*8)-:8], 1'b1};	
			
		end
		vector_out[10:0]={ 2'b01, 1'b0, OP, crc, 1'b1};
		
		return vector_out;
		
	endfunction : get_vector_to_send
	
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// get CRC function
//------------------------------------------------------------------------------

function [3:0] get_crc(bit [31:0] A, bit [31:0] B, operation_t OP);

    reg [67:0] d;
    reg [3:0]  c;
    reg [3:0]  newcrc;
  	begin
	    d = {B, A, 1'b1, OP};
	    c = '0;
	  	
	    newcrc[0] = d[66] ^ d[64] ^ d[63] ^ d[60] ^ d[56] ^ d[55] ^ d[54] ^ d[53] ^ d[51] ^ d[49] ^ d[48] ^ d[45] ^ d[41] ^ d[40] ^ d[39] ^ d[38] ^ d[36] ^ d[34] ^ d[33] ^ d[30] ^ d[26] ^ d[25] ^ d[24] ^ d[23] ^ d[21] ^ d[19] ^ d[18] ^ d[15] ^ d[11] ^ d[10] ^ d[9] ^ d[8] ^ d[6] ^ d[4] ^ d[3] ^ d[0] ^ c[0] ^ c[2];
	    newcrc[1] = d[67] ^ d[66] ^ d[65] ^ d[63] ^ d[61] ^ d[60] ^ d[57] ^ d[53] ^ d[52] ^ d[51] ^ d[50] ^ d[48] ^ d[46] ^ d[45] ^ d[42] ^ d[38] ^ d[37] ^ d[36] ^ d[35] ^ d[33] ^ d[31] ^ d[30] ^ d[27] ^ d[23] ^ d[22] ^ d[21] ^ d[20] ^ d[18] ^ d[16] ^ d[15] ^ d[12] ^ d[8] ^ d[7] ^ d[6] ^ d[5] ^ d[3] ^ d[1] ^ d[0] ^ c[1] ^ c[2] ^ c[3];
	    newcrc[2] = d[67] ^ d[66] ^ d[64] ^ d[62] ^ d[61] ^ d[58] ^ d[54] ^ d[53] ^ d[52] ^ d[51] ^ d[49] ^ d[47] ^ d[46] ^ d[43] ^ d[39] ^ d[38] ^ d[37] ^ d[36] ^ d[34] ^ d[32] ^ d[31] ^ d[28] ^ d[24] ^ d[23] ^ d[22] ^ d[21] ^ d[19] ^ d[17] ^ d[16] ^ d[13] ^ d[9] ^ d[8] ^ d[7] ^ d[6] ^ d[4] ^ d[2] ^ d[1] ^ c[0] ^ c[2] ^ c[3];
	    newcrc[3] = d[67] ^ d[65] ^ d[63] ^ d[62] ^ d[59] ^ d[55] ^ d[54] ^ d[53] ^ d[52] ^ d[50] ^ d[48] ^ d[47] ^ d[44] ^ d[40] ^ d[39] ^ d[38] ^ d[37] ^ d[35] ^ d[33] ^ d[32] ^ d[29] ^ d[25] ^ d[24] ^ d[23] ^ d[22] ^ d[20] ^ d[18] ^ d[17] ^ d[14] ^ d[10] ^ d[9] ^ d[8] ^ d[7] ^ d[5] ^ d[3] ^ d[2] ^ c[1] ^ c[3];
    	
    	randcase
	    	90: return newcrc;
	    	10: return 4'($random);
    	endcase
  	end
  endfunction
endmodule : top
