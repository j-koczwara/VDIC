 `undef DEBUG
class scoreboard;
	virtual alu_bfm bfm;

	function new (virtual alu_bfm b);
		bfm = b;
	endfunction : new
//------------------------------------------------------------------------------
// get error function
//------------------------------------------------------------------------------

	protected function error_flag get_error(bit [10:0] P);
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

	protected function error_flag get_expected_error(bit crc_ok, bit [3:0] data_len, operation_t OP);
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

	protected function bit signed [31:0] get_C_data(bit [10:0] result [4:0]);
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

	protected function [3:0] get_flag(bit [10:0] ctl);
		return ctl[7:4];

	endfunction

//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// CRC37 function
//------------------------------------------------------------------------------
	protected function [2:0] CRC37(bit [31:0] C, bit [3:0] flags);

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
// get expected flag function
//------------------------------------------------------------------------------

	protected function [3:0] get_expected_flag(bit signed [31:0] A, bit signed [31:0] B, operation_t OP);
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

	protected function bit signed [31:0] get_expected_data(bit signed [31:0] A, bit signed [31:0] B, operation_t OP);
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

//------------------------------------------------------------------------------
// Scoreboard
//------------------------------------------------------------------------------
	task execute();
		error_flag                error_expected;
		bit signed        [31:0]  C;
		bit         [3:0]   flag_out;
		bit         [3:0]   expected_flag;
		forever begin : self_checker
			@(negedge bfm.clk);
			while (!bfm.done) @(negedge bfm.clk);
			expected_flag = get_expected_flag(bfm.A, bfm.B, bfm.op_set);
			bfm.expected_flag =expected_flag;

			if(bfm.done) begin:verify_result
				bfm.done<=1'b0;
				if(bfm.crc_ok==1'b0 || bfm.data_len!=8 || bfm.op_set==notused2_op || bfm.op_set==notused3_op ) begin //error expected
					error_expected=get_expected_error(bfm.crc_ok, bfm.data_len, bfm.op_set);
					assert(bfm.result[0][10]===0 && bfm.result[0][9]===1 )begin //Error check

						assert(get_error(bfm.result[0])=== error_expected) begin
								`ifdef DEBUG
							$display("Test passed for bfm.A=%0d bfm.B=%0d bfm.op_set=%0d, error=%6b", bfm.A, bfm.B, bfm.op_set,get_error(bfm.result[0]));
								`endif
						end
						else begin
								`ifdef DEBUG
							$display("Test FAILED for bfm.A=%0d bfm.B=%0d bfm.op_set=%3b,  expected=%6b ", bfm.A, bfm.B, bfm.op_set, error_expected);

								`endif
							$display("FAILED");

						end
					end
					else begin
							`ifdef DEBUG
						$display("Test FAILED expected error, no error received bfm.A=%0d bfm.B=%0d bfm.op_set=%0d,  expected=%6b, datalen=%0d, bfm.crc_ok=0%b, error =%6b", bfm.A, bfm.B, bfm.op_set, error_expected, bfm.data_len, bfm.crc_ok, bfm.result[0]);
						$display("crc = %0b, datalen= %0b , op2= %0b , op3= %0b ",bfm.crc_ok==1'b0, bfm.data_len!=8, bfm.op_set==notused2_op,bfm.op_set==notused3_op );
								`endif
						$display("FAILED");

					end

				end
				else begin
					if (bfm.result[0][10]===0 && bfm.result[0][9]===0 )begin
						C=get_C_data(bfm.result);
						flag_out=get_flag(bfm.result[4]);

						assert(get_expected_data(bfm.A, bfm.B, bfm.op_set)==C)begin //Data check
							`ifdef DEBUG
							$display("Data test  passed for bfm.A=%0d bfm.B=%0d C=%0d, expected=%0d", bfm.A, bfm.B, C,get_expected_data(bfm.A, bfm.B, bfm.op_set));
							`endif
						end
						else begin
							`ifdef DEBUG
							$display("Data test FAILED for bfm.A=%0d bfm.B=%0d expected=%0d", bfm.A, bfm.B, C,get_expected_data(bfm.A, bfm.B, bfm.op_set));
							`endif
							$display("FAILED");
						end
						assert(expected_flag==flag_out)begin //Flag check
							`ifdef DEBUG
							$display("Flag test  passed for bfm.A=%0d bfm.B=%0d bfm.op_set=%0d, Flag=%4b, expected=%4b", bfm.A, bfm.B,bfm.op_set, flag_out,expected_flag);
							`endif
						end
						else begin
							`ifdef DEBUG
							$display(" Flag test FAILED for bfm.A=%0d bfm.B=%0d,  C=%0d ,bfm.op_set=%3b, Flag=%4b expected=%4b", bfm.A, bfm.B, C, bfm.op_set, flag_out,expected_flag);
							`endif
							$display("FAILED");
						end
						assert(CRC37(C, flag_out)==bfm.result[4][3:1])begin //CRC check
								`ifdef DEBUG
							$display("CRC test  passed for bfm.A=%0d bfm.B=%0d bfm.op_set=%0d, Flag=%4b, expected=%4b", bfm.A, bfm.B,bfm.op_set, flag_out,expected_flag);
								`endif
						end
						else begin
							   `ifdef DEBUG
							$display("CRC test FAILED for bfm.A=%0d bfm.B=%0d ,C=%0d, bfm.op_set=%3b, Flag=%4b expected=%4b", bfm.A, bfm.B, C, bfm.op_set, flag_out ,expected_flag);
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


		end: self_checker
	endtask

endclass

