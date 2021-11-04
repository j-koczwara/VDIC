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
 `undef DG
module top;

//------------------------------------------------------------------------------
// type and variable definitions
//------------------------------------------------------------------------------

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



	bit signed        [31:0]  A;
	bit signed        [31:0]  B;

	bit                 clk;
	bit                 rst_n;
	bit         [3:0]   crc;
	operation_t         op_set;
	bit         [3:0]   data_len;

	bit         [98:0]  data_in;
	bit         [63:0]  BA;
	bit         [10:0]  result [4:0];
	bit                 crc_ok;
	bit         [10:0]  data_package=11'b00111111111;
	bit         [3:0]   expected_flag;
	bit                 done;

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
// Coverage block
//------------------------------------------------------------------------------

// Covergroup checking the op codes and theri sequences
	covergroup op_cov;

		option.name = "cg_op_cov";

		coverpoint op_set {
			// #A1 test all operations
			bins A1_all_ops[] = {[and_op : reset_op ]};

			// #A2 two operations in row
			bins A2_twoops[]       = ([and_op:sub_op] [* 2]);

			// #A3 test all operations after reset
			bins A3_rst_opn[]      = (reset_op => [and_op : sub_op]);

			// #A4 test reset after all operations
			bins A4_opn_rst[]      = ([add_op:sub_op] => reset_op);


		}

	endgroup

// Covergroup checking for min and max arguments of the ALU
	covergroup zeros_or_ones_on_ops;

		option.name = "cg_zeros_or_ones_on_ops";

		all_ops : coverpoint op_set {
			ignore_bins null_ops = {reset_op, notused2_op, notused3_op};
		}

		a_leg: coverpoint A {
			bins zeros = {'h00000000};
			bins ones  = {-1};
		}

		b_leg: coverpoint B {
			bins zeros = {'h00000000};
			bins ones  = {-1};
		}

		B_op_00_FF: cross a_leg, b_leg, all_ops {

			// #B1 simulate all zero input for all the operations

			bins B1_add_00          = binsof (all_ops) intersect {add_op} &&
			(binsof (a_leg.zeros) || binsof (b_leg.zeros));

			bins B1_and_00          = binsof (all_ops) intersect {and_op} &&
			(binsof (a_leg.zeros) || binsof (b_leg.zeros));

			bins B1_or_00          = binsof (all_ops) intersect {or_op} &&
			(binsof (a_leg.zeros) || binsof (b_leg.zeros));

			bins B1_sub_00          = binsof (all_ops) intersect {sub_op} &&
			(binsof (a_leg.zeros) || binsof (b_leg.zeros));

			// #B2 simulate all one input for all the operations

			bins B2_add_FF          = binsof (all_ops) intersect {add_op} &&
			(binsof (a_leg.ones) || binsof (b_leg.ones));

			bins B2_and_FF          = binsof (all_ops) intersect {and_op} &&
			(binsof (a_leg.ones) || binsof (b_leg.ones));

			bins B2_or_FF          = binsof (all_ops) intersect {or_op} &&
			(binsof (a_leg.ones) || binsof (b_leg.ones));

			bins B2_sub_FF          = binsof (all_ops) intersect {sub_op} &&
			(binsof (a_leg.ones) || binsof (b_leg.ones));


			// #B3 simulate all one input A and B for all the operations

			bins B3_add_FF          = binsof (all_ops) intersect {add_op} &&
			(binsof (a_leg.ones) && binsof (b_leg.ones));

			bins B3_and_FF          = binsof (all_ops) intersect {and_op} &&
			(binsof (a_leg.ones) && binsof (b_leg.ones));

			bins B3_or_FF          = binsof (all_ops) intersect {or_op} &&
			(binsof (a_leg.ones) && binsof (b_leg.ones));

			bins B3_sub_FF          = binsof (all_ops) intersect {sub_op} &&
			(binsof (a_leg.ones) && binsof (b_leg.ones));

			// #B4 simulate all zero input A and B for all the operations

			bins B4_add_00          = binsof (all_ops) intersect {add_op} &&
			(binsof (a_leg.zeros) && binsof (b_leg.zeros));

			bins B4_and_00         = binsof (all_ops) intersect {and_op} &&
			(binsof (a_leg.zeros) && binsof (b_leg.zeros));

			bins B4_or_00         = binsof (all_ops) intersect {or_op} &&
			(binsof (a_leg.zeros) && binsof (b_leg.zeros));

			bins B4_sub_00         = binsof (all_ops) intersect {sub_op} &&
			(binsof (a_leg.zeros) && binsof (b_leg.zeros));

		}

	endgroup


// Covergroup checking for flags
	covergroup flags_cov;

		option.name = "cg_flags";

		all_ops : coverpoint op_set {
			ignore_bins null_ops = {reset_op, notused2_op, notused3_op};
		}

		flag_leg: coverpoint expected_flag {
			bins carry = {'b1000};
			bins overflow = {'b0100};
			bins zero  = {'b0010};
			bins negative = {'b0001};
			bins others  = {'b1100, 'b1010, 'b1001, 'b0110, 'b0101};
		}


		Flags: cross flag_leg, all_ops {

			//  simulate Overflow flag

			bins C1_sub_overflow            = binsof (all_ops) intersect {sub_op} &&
			(binsof (flag_leg.overflow));

			//  simulate carry flag

			bins C2_add_carry           = binsof (all_ops) intersect {add_op} &&
			(binsof (flag_leg.carry));

			bins C3_sub_carry            = binsof (all_ops) intersect {sub_op} &&
			(binsof (flag_leg.carry));

			// negative flag

			bins C4_add_negative           = binsof (all_ops) intersect {add_op} &&
			(binsof (flag_leg.negative));

			bins C5_sub_negative            = binsof (all_ops) intersect {sub_op} &&
			(binsof (flag_leg.negative));

			bins C6_and_negative           = binsof (all_ops) intersect {and_op} &&
			(binsof (flag_leg.negative));

			bins C7_or_negative            = binsof (all_ops) intersect {or_op} &&
			(binsof (flag_leg.negative));


			//  zero flag

			bins C8_add_zero           = binsof (all_ops) intersect {add_op} &&
			(binsof (flag_leg.zero));

			bins C9_sub_zero            = binsof (all_ops) intersect {sub_op} &&
			(binsof (flag_leg.zero));

			bins C10_and_zero           = binsof (all_ops) intersect {and_op} &&
			(binsof (flag_leg.zero));

			bins C11_or_zero            = binsof (all_ops) intersect {or_op} &&
			(binsof (flag_leg.zero));


			ignore_bins overflow_or = binsof (all_ops) intersect {or_op} &&
			binsof(flag_leg.overflow);
			ignore_bins overflow_and = binsof (all_ops) intersect {and_op} &&
			binsof(flag_leg.overflow);
			ignore_bins overflow_add = binsof (all_ops) intersect {add_op} &&
			binsof(flag_leg.overflow);
			ignore_bins carry_or = binsof (all_ops) intersect {or_op} &&
			binsof(flag_leg.carry);
			ignore_bins carry_and = binsof (all_ops) intersect {and_op} &&
			binsof(flag_leg.carry);
			ignore_bins others_or = binsof (all_ops) intersect {or_op} &&
			binsof(flag_leg.others);
			ignore_bins others_and = binsof (all_ops) intersect {and_op} &&
			binsof(flag_leg.others);
		}

	endgroup

// Covergroup checking for errors
	covergroup errors_cov;

		option.name = "cg_errors";

		data_len_leg: coverpoint data_len {
			bins less_D1  = {7};
			bins more_D2  = {9};
		}
		crc_leg: coverpoint crc_ok {
			bins crc_error_D3 = {0};
		}

		ops_leg : coverpoint op_set {
			bins error_ops_D4 = {notused2_op, notused3_op};
		}

		multiple_errors_D5: cross crc_leg, data_len_leg, ops_leg;

	endgroup

	errors_cov                  ec;
	op_cov                      oc;
	zeros_or_ones_on_ops        c_00_FF;
	flags_cov                   fc;

	initial begin : coverage
		oc      = new();
		c_00_FF = new();
		fc      = new();
		ec      = new();
		forever begin : sample_cov
			@(posedge clk);
			oc.sample();
			c_00_FF.sample();
			fc.sample();
			ec.sample();
		end

	end : coverage


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
		repeat (10000) begin : tester_main

			op_set        = get_op();
			A             = get_data();
			B             = get_data();
			{crc, crc_ok} = get_crc(A,B,op_set);
			data_len      = get_data_len();
			BA={B,A};
			expected_flag=get_expected_flag(A, B, op_set);



			case(op_set==reset_op)
				1: begin
					reset_alu();
				end
				default:begin
					data_in=get_vector_to_send(BA, op_set, crc, data_len);
					for (int i = 0; i < (11*(data_len%9)); i++) begin: serial_send
						@(negedge clk);
						sin = data_in[(11*(data_len%9+1))-1-i];
					end
					if( data_len>8 )
						for (int i = 0; i < 99; i++) begin: serial_send
							@(negedge clk);
							sin = data_package[10-(i%11)];
						end
					else
						for (int i = 0; i < 11; i++) begin: serial_send
							@(negedge clk);
							sin = data_in[10-i];
						end


					result='{default:0};
					@(negedge sout);
					for (int i=0; i<5; i++) begin: serial_receive
						for (int k=0; k<11; k++) begin: save_package
							@(negedge clk);
							result[i][10-k]= sout;
						end
						if(result[i][10]===0 && result[i][9]===1 )
							break;
					end
					
					done=1'b1;
					@(negedge clk);
				end
			endcase
			if($get_coverage() == 100) break;
		end: tester_main
		$display("PASSED");
		$finish;

	end : tester

//------------------------------------------------------------------------------
// Scoreboard
//------------------------------------------------------------------------------
	always @(negedge clk) begin : scoreboard
		error_flag                error_expected;
		bit signed        [31:0]  C;
		bit         [3:0]   flag_out;
		if(done) begin:verify_result
			done<=1'b0;
			if(crc_ok==1'b0 || data_len!=8 || op_set==notused2_op || op_set==notused3_op ) begin //error expected
				error_expected=get_expected_error(crc_ok, data_len, op_set);
				assert(result[0][10]===0 && result[0][9]===1 )begin //Error check

					assert(get_error(result[0])=== error_expected) begin
								`ifdef DG
						$display("Test passed for A=%0d B=%0d op_set=%0d, error=%6b", A, B, op_set,get_error(result[0]));
								`endif
					end
					else begin
								`ifdef DG
						$display("Test FAILED for A=%0d B=%0d op_set=%3b, error=%6b, expected=%6b ", A, B, op_set,error, error_expected);

								`endif
						$display("FAILED");

					end
				end
				else begin
							`ifdef DG
					$display("Test FAILED expected error, no error received A=%0d B=%0d op_set=%0d, error=%6b, expected=%6b, datalen=%0d, crc_ok=0%b", A, B, op_set,error, error_expected,data_len, crc_ok);
					$display("crc = %0b, datalen= %0b , op2= %0b , op3= %0b ",crc_ok==1'b0, data_len!=8, op_set==notused2_op,op_set==notused3_op );
								`endif
					$display("FAILED");

				end

			end
			else begin
				if (result[0][10]===0 && result[0][9]===0 )begin
					C=get_C_data(result);
					flag_out=get_flag(result[4]);

					assert(get_expected_data(A, B, op_set)==C)begin //Data check
							`ifdef DG
						$display("Data test  passed for A=%0d B=%0d C=%0d, expected=%0d", A, B, C,get_expected_data(A, B, op_set));
							`endif
					end
					else begin
							`ifdef DG
						$display("Data test FAILED for A=%0d B=%0d expected=%0d", A, B, C,get_expected_data(A, B, op_set));
							`endif
						$display("FAILED");
					end
					assert(expected_flag==flag_out)begin //Flag check
							`ifdef DG
						$display("Flag test  passed for A=%0d B=%0d op_set=%0d, Flag=%4b, expected=%4b", A, B,op_set, flag_out,expected_flag);
							`endif
					end
					else begin
							`ifdef DG
						$display(" Flag test FAILED for A=%0d B=%0d,  C=%0d ,op_set=%3b, Flag=%4b expected=%4b", A, B, C, op_set, flag_out,expected_flag);
							`endif
						$display("FAILED");
					end
					assert(CRC37(C, flag_out)==result[4][3:1])begin //CRC check
								`ifdef DG
						$display("CRC test  passed for A=%0d B=%0d op_set=%0d, Flag=%4b, expected=%4b", A, B,op_set, flag_out,expected_flag);
								`endif
					end
					else begin
							   `ifdef DG
						$display("CRC test FAILED for A=%0d B=%0d ,C=%0d, op_set=%3b, Flag=%4b expected=%4b", A, B, C, op_set, flag_out ,expected_flag);
							   `endif
						$display("FAILED");
					end
				end
				else begin
					$display("FAILED");
					$finish;
				end

			end


		end


	end: scoreboard
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
			80:     return 32'($random);
			10:     return '0;
			10:     return '1;
		endcase

	endfunction : get_data

//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// get reset function
//------------------------------------------------------------------------------
	function bit [3:0] get_data_len();
		randcase
			90:     return 8;
			5:      return 9;
			5:      return 7;
		endcase

	endfunction : get_data_len

//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// get op function
//------------------------------------------------------------------------------
	function operation_t get_op();
		operation_t         op;
		bit                 ok;
		ok=randomize(op) with {op dist {and_op:=3, sub_op:=3, or_op:=3, add_op:=3, notused2_op:=1, notused3_op:=1, reset_op:=1 };};
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
			bit [3:0] crc_out;
			bit [3:0] crc_68;
			crc_68 = CRC68(A,B,OP);
			crc_out = 4'($random);
			randcase
				90: return {crc_68, 1'b1};
				10: begin
					if(crc_out!=crc_68)
						return {crc_out, 1'b0};
					else
						return {crc_out, 1'b1};
				end

			endcase
		end
	endfunction

//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// get error function
//------------------------------------------------------------------------------zeros

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

	function error_flag get_expected_error(bit crc_ok, bit [3:0] data_len, operation_t OP);
		error_flag error;
		begin
			error = CHECK_ERROR;
			if (data_len!=8)
				error= ERR_DATA;
			else if (crc_ok==0)
				error= ERR_CRC;
			else if (OP==notused2_op || OP==notused3_op )
				error= ERR_OP;
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
		begin
			flag='0;
			case (OP)
				and_op: begin
					result=A&B;
					if(result==0)
						flag = 4'b0010;
					if(result[31]==1)
						flag = flag | 4'b0001;
				end

				add_op: begin
					result=B+A;
					if((B+A)<0)
						flag = 4'b0001;
					if ((B<0 && A<0) || (B>0 && A<0 && -A<B) || (A>0 && B<0 && -B<A))
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
					result=B-A;
					if((B-A)<0)
						flag = 4'b0001;
					if ((A>0 && B>=0 && A>B) ||( A<0 && B>=0) || ( B<0 && A<0 && -A<-B))
						flag = flag | 4'b1000;
					if((A[31] && !B[31] && result[31]) || (!A[31] && B[31] && !result[31])) //borrow
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
