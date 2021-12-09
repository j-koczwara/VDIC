
class scoreboard extends uvm_subscriber #(result_s);
	`uvm_component_utils(scoreboard)


	virtual alu_bfm bfm;
	uvm_tlm_analysis_fifo #(command_s) cmd_f;

	function new (string name, uvm_component parent);
		super.new(name, parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		cmd_f = new ("cmd_f", this);
	endfunction : build_phase





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
	function void write(result_s t );
		command_s cmd;
		error_flag                error_expected;
		bit signed        [31:0]  C;
		bit         [3:0]   flag_out;
		bit         [3:0]   expected_flag;
		cmd.op = notused2_op;
		
		expected_flag = cmd.expected_flag;
		
		if(cmd.done) begin:verify_result
			cmd.done<=1'b0;

			if(cmd.crc_ok==1'b0 || cmd.data_len!=8 || cmd.op==notused2_op || cmd.op==notused3_op ) begin //error expected
				error_expected=get_expected_error(cmd.crc_ok, cmd.data_len, cmd.op);
				assert(t.data_type === 2'b01 )begin //Error check
					//$display("Test failed for data_type = %2b", t.data_type );
					assert(t.error_flag === error_expected) begin
								
					end
					else begin								
						$display("FAILED");
					end
				end
				else begin							
					$display("FAILED");
				end

			end
			else begin
				if (t.data_type == 2'b00 )begin
					C=t.C_data;
					flag_out=t.flag_out;

					assert(get_expected_data(cmd.A, cmd.B, cmd.op)==C)begin //Data check
							
					end
					else begin							
						$display("FAILED");
					end
					assert(expected_flag==flag_out)begin //Flag check
							
					end
					else begin							
						$display("FAILED");
					end
					assert(CRC37(C, flag_out)==t.CRC37)begin //CRC check
								
					end
					else begin
							 
						$display("FAILED");
					end
				end
				else begin
					$display("FAILED");
					$finish;
				end

			end


		end: verify_result


	endfunction


endclass

