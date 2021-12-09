interface alu_bfm;
	import alu_pkg::*;

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
	bit         [10:0]  result [4:0];
	bit         [10:0]  data_package=11'b00111111111;
	bit         [3:0]   expected_flag;

	error_flag                error_flag_out;
	bit signed  [31:0]        C_data;
	bit         [3:0]         flag_out;
	bit         [2:0]         CRC37;
	bit         [1:0]         data_type;

	bit start;

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

	task send_op(bit [31:0] iA, bit [31:0] iB, bit [3:0] crc, bit icrc_ok,  input bit [3:0] idata_len, input operation_t iop);

		bit         [98:0]  data_in;
		bit [63:0] BA;

		A=iA;
		B=iB;
		BA={B,A};
		op_set = iop;
		data_len = idata_len;
		crc_ok =icrc_ok;
		data_in = get_vector_to_send(BA, iop, crc, idata_len );
		expected_flag = get_expected_flag(iA, iB, iop);
		
		start= 1'b1;
		@(posedge clk);

		case(op_set==reset_op)
			1: begin
				reset_alu();
			end
			default:begin
				@(posedge clk);
				start = 1'b0;
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
				error_flag_out = get_error(result[0]);
				C_data = get_C_data(result);
				flag_out = get_flag(result[4]);
				CRC37 = result[4][3:1];
				data_type = {result[0][10], result[0][9]};
				done=1'b1;
				@(negedge clk);
			end
		endcase



	endtask : send_op

	command_monitor command_monitor_h;




	always @(posedge clk) begin : op_monitor
		static bit in_command = 0;
		command_s command;
		if (start) begin : start_high
			if (!in_command) begin : new_command
				command.A  <= A;
				command.B  <= B;
				command.op <= op_set;
				command.crc_ok <= crc_ok;
				command.data_len <= data_len;
				command.done <= done;
				command.expected_flag <= expected_flag;

				command_monitor_h.write_to_monitor(command);
				in_command = (command.op != notused2_op || command.op != notused3_op);
			end : new_command
		end : start_high

		else // start low
			in_command = 0;
	end : op_monitor

	always @(negedge rst_n) begin : rst_monitor
		command_s command;
		command.op <= reset_op;
		if (command_monitor_h != null) //guard against VCS time 0 negedge
			command_monitor_h.write_to_monitor(command);
	end : rst_monitor

	result_monitor result_monitor_h;

	initial begin : result_monitor_thread
		result_s rslt;
		forever begin
			@(posedge clk) ;
			if (done) begin
				rslt.C_data=C_data;
				rslt.CRC37 = CRC37;
				rslt.error_flag = error_flag_out;
				rslt.flag_out = flag_out;
				rslt.data_type = data_type;
				result_monitor_h.write_to_monitor(rslt);
				done = 1'b0;
			end
		end
	end : result_monitor_thread

endinterface : alu_bfm