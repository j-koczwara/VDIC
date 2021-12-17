
class scoreboard extends uvm_subscriber #(result_transaction);
	`uvm_component_utils(scoreboard)

//------------------------------------------------------------------------------
// local typedefs
//------------------------------------------------------------------------------

	typedef enum bit {
		TEST_PASSED,
		TEST_FAILED
	} test_result;

	protected test_result tr = TEST_PASSED; // the result of the current test

	virtual alu_bfm bfm;
	uvm_tlm_analysis_fifo #(random_command) cmd_f;

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
			error = NO_ERROR;
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
// print the PASSED/FAILED in color
//------------------------------------------------------------------------------
	protected function void print_test_result (test_result r);
		if(tr == TEST_PASSED) begin
			set_print_color(COLOR_BOLD_BLACK_ON_GREEN);
			$write ("-----------------------------------\n");
			$write ("----------- Test PASSED -----------\n");
			$write ("-----------------------------------");
			set_print_color(COLOR_DEFAULT);
			$write ("\n");
		end
		else begin
			set_print_color(COLOR_BOLD_BLACK_ON_RED);
			$write ("-----------------------------------\n");
			$write ("----------- Test FAILED -----------\n");
			$write ("-----------------------------------");
			set_print_color(COLOR_DEFAULT);
			$write ("\n");
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


	protected function result_transaction predict_result(random_command cmd);
		result_transaction predicted; //TODO
		predicted = new ("predicted");
		predicted.error_flag = get_expected_error(cmd.crc_ok, cmd.data_len, cmd.op);
		if(cmd.crc_ok==1'b0 || cmd.data_len!=8 || cmd.op==notused2_op || cmd.op==notused3_op ) begin
			predicted.data_type = 2'b01;
			predicted.C_data = get_expected_data(cmd.A, cmd.B, cmd.op);
			predicted.flag_out = cmd.expected_flag;
			predicted.CRC37 = CRC37(predicted.C_data, cmd.expected_flag);
		end
		else begin
			predicted.data_type = 2'b00;
			predicted.C_data = '0;
			predicted.flag_out = '0;
			predicted.CRC37 = '0;
		end
	endfunction
//------------------------------------------------------------------------------
// Scoreboard
//------------------------------------------------------------------------------
	function void write(result_transaction t );
		string data_str;
		random_command cmd;
		result_transaction predicted;
		$display("sc");
		do
			if (!cmd_f.try_get(cmd))
				$fatal(1, "Missing command in self checker");
		while ((cmd.op == notused2_op) || (cmd.op == reset_op)|| (cmd.op == notused3_op));
		predicted = predict_result(cmd);

		data_str  = { cmd.convert2string(),
			" ==>  Actual " , t.convert2string(),
			"/Predicted ",predicted.convert2string()};

		if (!predicted.compare(t)) begin
			`uvm_error("SELF CHECKER", {"FAIL: ",data_str})
			tr = TEST_FAILED;
		end
		else
			`uvm_info ("SELF CHECKER", {"PASS: ", data_str}, UVM_HIGH)

	endfunction

//------------------------------------------------------------------------------
// report phase
//------------------------------------------------------------------------------

	function void report_phase(uvm_phase phase);
		super.report_phase(phase);
		print_test_result(tr);
	endfunction : report_phase

endclass

