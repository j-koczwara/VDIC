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
	
	typedef enum bit[5:0] {
		ERR_DATA      		     = 6'b100100,
		ERR_CRC                  = 6'b010010,
		ERR_OP                   = 6'b001001,
		CHECK_ERROR              = 6'b111111
		
	} error_flag;
	
	typedef error_flag [2:0] error_flag_array;
	error_flag_array		  error_expexted;
	error_flag                error;
	bit signed        [31:0]  A;
	bit signed        [31:0]  B;
	bit signed        [31:0]  C;
	bit                 clk;
	bit                 reset, rst_n;
	bit         [3:0]   crc;
	operation_t         op_set;
	bit			[3:0]	data_len;
	bit			[3:0]	flag_out;
	bit			[98:0]  data_in;
	bit 		[63:0]  BA;
	bit			[10:0]  result [4:0];
	bit					crc_ok;

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
		repeat (1000) begin : tester_main
			op_set = get_op();
			A      = get_data();
			B      = get_data();
			{crc, crc_ok}    = get_crc(A,B,op_set);
			reset  = get_rst();
			data_len =get_data_len();
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
				
				
					result='{default:0};
					@(negedge sout);					
					for (int i=0; i<5; i++) begin: serial_recive
						for (int k=0; k<11; k++) begin: save_package
							@(negedge clk);
							result[i][10-k]= sout;	
						end
						if(result[i][10]===0 && result[i][9]===1 )
							break;	
					end	
					#1us
					
					if(result[0][10]===0 && result[0][9]===1 )begin //Error test 
					
						error_expexted=get_expected_error(crc_ok, data_len, op_set);
						error=get_error(result[0]);
					
						assert((error=== error_expexted[0])|| (error=== error_expexted[1])||(error=== error_expexted[2])) begin
	                        `ifdef DEBUG
	                        $display("Test passed for A=%0d B=%0d op_set=%0d, error=%6b", A, B, op_set,error);
	                        `endif
	                    end
	                    else begin
	                        $display("Test FAILED for A=%0d B=%0d op_set=%0d, error=%6b, expected=%6b expected=%6b expected=%6b", A, B, op_set,error, error_expexted[0],error_expexted[1],error_expexted[2] );
	                         $display("FAILED");
		                    
	                    end
	                end    
					else if (result[0][10]===0 && result[0][9]===0 )begin	
						 C=get_C_data(result);
						 flag_out=get_flag(result[4]);
	                     assert(get_expected_data(A, B, op_set)==C)begin //Data test
		                 	`ifdef DEBUG
	                     		$display("Data test  passed for A=%0d B=%0d C=%0d, expected=%0d", A, B, C,get_expected_data(A, B, op_set));
	                     	`endif
	                     end
	                     else begin
		                    `ifdef DEBUG
	                        	$display("Data test FAILED for A=%0d B=%0d expected=%0d", A, B, C,get_expected_data(A, B, op_set));
		                    `endif	
	                        $display("FAILED");
	                     end
	                      assert(get_expected_flag(A, B, op_set)==flag_out)begin //Flag test
		                 	`ifdef DEBUG
	                     		$display("Flag test  passed for A=%0d B=%0d op_set=%0d, Flag=%4b, expected=%4b", A, B,op_set, flag_out,get_expected_flag(A, B, op_set));
	                     	`endif
	                     end
	                      else begin
		                    `ifdef DEBUG
	                        	$display(" Flag test FAILED for A=%0d B=%0d ,op_set=%3b, Flag=%4b expected=%4b", A, B,op_set, flag_out,get_expected_flag(A, B, op_set));
		                    `endif		                  
	                        $display("FAILED");
	                     end
	                       assert(CRC37(C, flag_out)==result[4][3:1])begin //CRC test
			                 	`ifdef DEBUG
		                     		$display("CRC test  passed for A=%0d B=%0d op_set=%0d, Flag=%4b, expected=%4b", A, B,op_set, flag_out,get_expected_flag(A, B, op_set));
		                     	`endif
	                     end
	                       else begin
		                       `ifdef DEBUG
	                        		$display("CRC test FAILED for A=%0d B=%0d ,op_set=%3b, Flag=%4b expected=%4b", A, B,op_set, flag_out ,get_expected_flag(A, B, op_set));
		                       `endif
	                         		$display("FAILED");
	                     end
	                     
					end
					
				end
				
				
			endcase		
			
			
		end: tester_main
		$display("PASSED");
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
// CRC37 function
//------------------------------------------------------------------------------
function [2:0] CRC37(bit [31:0] C, bit [3:0] flags);

		reg [36:0] d;
		reg [2:0] c;
		reg [2:0] newcrc;
		begin
			d = {C, 1'b0, flags};
			c = 0;

			newcrc[0] = d[35] ^ d[32] ^ d[31] ^ d[30] ^ d[28] ^ d[25] ^ d[24] ^ d[23] ^ d[21] ^ d[18] ^ d[17] ^ d[16] ^ d[14] ^ d[11] ^ d[10] ^ d[9] ^ d[7] ^ d[4] ^ d[3] ^ d[2] ^ d[0] ^ c[1];
			newcrc[1] = d[36] ^ d[35] ^ d[33] ^ d[30] ^ d[29] ^ d[28] ^ d[26] ^ d[23] ^ d[22] ^ d[21] ^ d[19] ^ d[16] ^ d[15] ^ d[14] ^ d[12] ^ d[9] ^ d[8] ^ d[7] ^ d[5] ^ d[2] ^ d[1] ^ d[0] ^ c[1] ^ c[2];
			newcrc[2] = d[36] ^ d[34] ^ d[31] ^ d[30] ^ d[29] ^ d[27] ^ d[24] ^ d[23] ^ d[22] ^ d[20] ^ d[17] ^ d[16] ^ d[15] ^ d[13] ^ d[10] ^ d[9] ^ d[8] ^ d[6] ^ d[3] ^ d[2] ^ d[1] ^ c[0] ^ c[2];
			return  newcrc;
		end
endfunction 
	
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// CRC68 function
//------------------------------------------------------------------------------

function [3:0] CRC68(bit [31:0] A, bit [31:0] B, operation_t OP);

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
    	
 		return newcrc;
  	end
endfunction
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// get crc function
//------------------------------------------------------------------------------

function [4:0] get_crc(bit [31:0] A, bit [31:0] B, operation_t OP);   
  	begin
	   
    	randcase
	    	90: return {CRC68(A,B,OP), 1'b1}; 
	    	10: return {4'($random), 1'b0};   //{crc, crc_ok}
    	endcase
  	end
endfunction

//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// get error function
//------------------------------------------------------------------------------

function error_flag get_error(bit [10:0] P);   
  	begin
	   if(^P[8:1]===0)
		   case(P[7:2])
			   6'b001001: return ERR_OP;
			   6'b100100: return ERR_DATA;
			   6'b010010: return ERR_CRC;
			   	   
			   default:   return CHECK_ERROR;
		   endcase   
	   else
		   return CHECK_ERROR;
  	end 	
  	
  endfunction

//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// get expected error function
//------------------------------------------------------------------------------

function error_flag_array get_expected_error(bit crc_ok, bit [3:0] data_len, operation_t OP);
	error_flag_array error;
  	begin
	   error = '{default:0};
	   if (data_len!=8)
		   error[0]= ERR_DATA;
	   if (crc_ok!=1)
		   error[1]= ERR_CRC;
	   if (OP==notused2_op || OP==notused3_op || OP==notused7_op)
		   error[2]= ERR_OP;
	   return error;   
	   
		   
  	end 	
  	
  endfunction



//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// get C data function
//------------------------------------------------------------------------------

function bit signed [31:0] get_C_data(bit [10:0] result [4:0]);   
	bit signed [31:0] C;
  	begin
	  	C='0;
	  	for (int i=0;i<4;i++)
		  	C[31-(8*i)-: 8] = result[i][8:1];
	   
	   return C;
		   
  	end 	
  	
endfunction

//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// get flag function
//------------------------------------------------------------------------------

function [3:0] get_flag(bit [10:0] ctl);   
	return ctl[7:4];   	
  	
endfunction

//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// get expected flag function
//------------------------------------------------------------------------------

function [3:0] get_expected_flag(bit signed [31:0] A, bit signed [31:0] B, operation_t OP);   
	bit [3:0] flag;
	bit signed [31:0] result;
	bit [32:0] result_33b;
	bit unsigned [31:0] A_unsigned;
	bit unsigned [31:0] B_unsigned;
	begin
		flag='0;
		A_unsigned=A;
		B_unsigned=B;		
		case (OP)
			and_op: begin
				result=A&B;
				if(A=='0 || B=='0)
					flag = 4'b0010;				
				if(result[31]==1)
					flag = flag | 4'b0001;
			end			
				
			add_op: begin
				result_33b=B_unsigned+A_unsigned;
				result=B+A;
				if((B+A)<0)
					flag = 4'b0001;
				if(result_33b[32]==1)
					flag = flag | 4'b1000;
				if((!A[31] && !B[31] && result[31]) || (A[31] && B[31] && !result[31]))
					flag = flag | 4'b0100;
				if((B+A)==0)
					flag = flag | 4'b0010;
				
				end
			or_op : begin
				if(A=='0 && B=='0)
					flag = 4'b0010;			
				result=A|B;
				if(result[31]==1)
					flag = flag | 4'b0001;
				end
			sub_op: begin
				result_33b=B_unsigned-A_unsigned;
				result=B-A;
				if((B-A)<0)
					flag = 4'b0001;
				if(result_33b[32])
					flag = flag | 4'b1000;
				if((A[31] && !B[31] && result[31]) || (!A[31] && B[31] && !result[31]))
					flag = flag | 4'b0100;
				if((B-A)==0)
					flag = flag | 4'b0010;
				end
	
		endcase 
		return flag;
	end
	
	
  	
endfunction
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// get expected data function
//------------------------------------------------------------------------------

function bit signed [31:0] get_expected_data(bit signed [31:0] A, bit signed [31:0] B, operation_t OP);   
	bit signed [31:0] data;
	begin
		case (OP)
			and_op: data = A&B;
			add_op: data = A+B;
			or_op : data = A|B;
			sub_op: data = B-A;	
		endcase 
		return data;
	end
	
  	
endfunction


endmodule : top
