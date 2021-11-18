module tester(alu_bfm bfm);
	import alu_pkg::*;

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


//------------------------
// Tester main

	initial begin : tester
		bit [98:0] iVector;
		bit signed    [31:0]  iA;
		bit signed        [31:0]  iB;
		operation_t op_set;
		bit         [3:0]   crc;
		bit                 crc_ok;
		//bit         [98:0]  data_in;
		bit         [63:0]  BA;
		bit         [3:0]   idata_len;
		bit        [10:0]  result [4:0];

		bfm.reset_alu();
		repeat (10000) begin : tester_main

			op_set        = get_op();
			iA             = get_data();
			iB             = get_data();
			{crc, crc_ok} = get_crc(iA,iB,op_set);
			idata_len      = get_data_len();
			BA={iB,iA};
			iVector = get_vector_to_send(BA, op_set, crc, idata_len );
			bfm.A      = iA;
			bfm.B      = iB;
			bfm.crc_ok = crc_ok;
			bfm.send_op(iVector, idata_len,  op_set);
			
			
			if($get_coverage() == 100) break;
		end: tester_main
		$display("PASSED");
		$finish;

	end : tester
endmodule