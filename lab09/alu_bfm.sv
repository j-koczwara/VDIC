import alu_pkg::*;
interface alu_bfm;


	bit signed        [31:0]  A;
	bit signed        [31:0]  B;

	bit                 clk;
	bit                 rst_n;
	bit                 crc_ok;
	operation_t         op_set;
	bit         [3:0]   data_len;
	bit sin;
	wire sout;
	bit                 done;


	bit         [3:0]   expected_flag;

	error_flag                error_flag_out;
	bit signed  [31:0]        C_data;
	bit         [3:0]         flag_out;
	bit         [2:0]         CRC37;
	bit         [1:0]         data_type;

	bit start;

	command_monitor command_monitor_h;
	result_monitor result_monitor_h;

	initial begin
		clk = 0;
		forever begin
			#10;
			clk = ~clk;
		end
	end


//------------------------------------------------------------------------------
// reset task
//------------------------------------------------------------------------------
	task reset_alu();
		rst_n = 1'b0;
		sin   = 1'b1;
		start = 1'b0;
		@(negedge clk);
		rst_n = 1'b1;
	endtask

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

	function [3:0] get_crc(bit [31:0] A, bit [31:0] B, operation_t OP, bit crc_ok);
		begin
			bit [3:0] crc_out;
			bit [3:0] crc_68;
			crc_68 = CRC68(A,B,OP);
			crc_out = 4'($random);
			if (crc_ok == 1'b1) begin
				return crc_68;
			end
			else begin
				if(crc_out == crc_68)
					return ~crc_out;
				else
					return crc_out;
			end
		end
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
// get error function
//------------------------------------------------------------------------------

	function error_flag get_error(bit [10:0] P);
		begin
			if(P[10:9]=== 2'b00)
				return NO_ERROR;
			else
				if(^P[8:1]===0)
					case(P[7:2])
						6'b001001: return ERR_OP;
						6'b100100: return ERR_DATA;
						6'b010010: return ERR_CRC;

						default:   return NO_ERROR;
					endcase
				else
					return NO_ERROR;
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

	task send_op(input bit [31:0] iA, input bit [31:0] iB,  input bit icrc_ok,  input bit [3:0] idata_len, input operation_t iop, output error_flag error_flag_out, output bit signed  [31:0]  C_data,
	output bit         [3:0]         flag_out,
	output bit         [2:0]         CRC37,
	output bit         [1:0]         data_type);

		bit         [98:0]  data_in;
		bit [63:0] BA;
		bit [3:0] crc;
		static bit         [10:0]  data_package=11'b00111111111;
		bit         [10:0]  result [4:0];
		A = iA;
		B = iB;
		BA = {B,A};
		op_set = iop;
		data_len = idata_len;
		crc_ok = icrc_ok;
		crc = get_crc(iA, iB, iop, icrc_ok);
		data_in = get_vector_to_send(BA, iop, crc, idata_len );
		expected_flag = get_expected_flag(iA, iB, iop);

		start= 1'b1;
		
		case(op_set==reset_op)
			1: begin
				reset_alu();
			end
			default:begin
				@(posedge clk);

				//data_in=iVector;
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
				start = 1'b0;

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
				data_type = {result[0][10], result[0][9]};
				error_flag_out = get_error(result[0]);
				if ( data_type === 2'b00 || data_type === 2'b10) begin
					C_data = get_C_data(result);
					flag_out = get_flag(result[4]);
					CRC37 = result[4][3:1];
				end
				else begin
					C_data = '0;
					flag_out = '0;
					CRC37 = '0;
				end
				@(negedge clk);
				done=1'b1;


			end
		endcase



	endtask : send_op


	always @(posedge clk) begin : op_monitor
		static bit in_command = 0;		
		if (start) begin : start_high
			@(posedge clk);
			if (!in_command) begin : new_command
				command_monitor_h.write_to_monitor(A,  B,  op_set,  crc_ok,  data_len,
					expected_flag);
				in_command = (op_set != notused2_op || op_set != notused3_op);
			end : new_command
		end : start_high

		else // start low
			in_command = 0;
	end : op_monitor

	always @(negedge rst_n) begin : rst_monitor

		if (command_monitor_h != null) //guard against VCS time 0 negedge
			command_monitor_h.write_to_monitor(A,  B,  reset_op,  1'b1,  8,
				expected_flag);
	end : rst_monitor



	initial begin : result_monitor_thread
		forever begin
			@(posedge clk) ;
			if (done) begin
				result_monitor_h.write_to_monitor( error_flag_out, C_data, flag_out, CRC37, data_type);
				
				done=1'b0;

			end
		end
	end : result_monitor_thread

endinterface : alu_bfm