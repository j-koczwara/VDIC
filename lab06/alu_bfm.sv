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
		@(negedge clk);
		rst_n = 1'b1;
	endtask

//------------------------------------------------------------------------------
	task send_op(input bit [98:0] iVector, input bit [3:0] idata_len, input operation_t iop);
		bit         [98:0]  data_in;
		
		op_set = iop;
   		data_in = iVector;
		data_len = idata_len;
		
		
		case(op_set==reset_op)
			1: begin
				reset_alu();
			end
			default:begin
				data_in=iVector;
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



endtask : send_op

endinterface : alu_bfm