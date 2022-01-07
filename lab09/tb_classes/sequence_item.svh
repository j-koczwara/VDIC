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
 */
class sequence_item extends uvm_sequence_item;
	//`uvm_object_utils(sequence_item)

//------------------------------------------------------------------------------
// transaction variables
//------------------------------------------------------------------------------

	rand bit signed [31:0]  A;
	rand bit signed [31:0]  B;
	rand operation_t op;
	rand bit         crc_ok;
	rand bit         [3:0]   data_len;
	bit         [3:0]   expected_flag;

	error_flag                alu_error_flag;
	bit signed  [31:0]        C_data;
	bit         [3:0]         flag_out;
	bit         [2:0]         CRC37;
	bit         [1:0]         data_type;


//------------------------------------------------------------------------------
// constraints
//------------------------------------------------------------------------------

	constraint data {
		A dist {32'h00000000:=1, [32'h00000001 : 32'hFFFFFFFE]:/1,-1:=1};
		B dist {32'h00000000:=1, [32'h00000001 : 32'hFFFFFFFE]:/1,-1:=1};
		data_len dist {7:=1, 8:=8, 9:=1};
		crc_ok dist   {0:=1, 1:=9};
	}

//------------------------------------------------------------------------------
// transaction functions: do_copy, clone_me, do_compare, convert2string
//------------------------------------------------------------------------------

	`uvm_object_utils_begin(sequence_item)
	`uvm_field_int(A, UVM_ALL_ON | UVM_DEC)
	`uvm_field_int(B, UVM_ALL_ON | UVM_DEC)
	`uvm_field_enum(operation_t, op, UVM_ALL_ON)
	`uvm_field_int(crc_ok, UVM_ALL_ON | UVM_UNSIGNED)
	`uvm_field_int(data_len, UVM_ALL_ON | UVM_DEC)
	`uvm_field_int(expected_flag, UVM_ALL_ON)
	`uvm_field_enum(error_flag, alu_error_flag, UVM_ALL_ON)
	`uvm_field_int(C_data, UVM_ALL_ON | UVM_DEC)
	`uvm_field_int(flag_out, UVM_ALL_ON)
	`uvm_field_int(CRC37, UVM_ALL_ON)
	`uvm_field_int(data_type, UVM_ALL_ON)
`uvm_object_utils_end



	function string convert2string();
		string s;
		s = $sformatf("A: %h  B: %h op: %s, data_len: %d, crc_ok: %b", A, B, op.name(), data_len, crc_ok );
		return s;
	endfunction : convert2string

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

	function new (string name = "");
		super.new(name);
	endfunction : new

endclass : sequence_item


