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
class result_transaction extends uvm_transaction;

//------------------------------------------------------------------------------
// transaction variables
//------------------------------------------------------------------------------

	error_flag                error_flag;
	bit signed  [31:0]        C_data;
	bit         [3:0]         flag_out;
	bit         [2:0]         CRC37;
	bit         [1:0]         data_type;

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

	function new(string name = "");
		super.new(name);
	endfunction : new

//------------------------------------------------------------------------------
// transaction methods - do_copy, convert2string, do_compare
//------------------------------------------------------------------------------

	function void do_copy(uvm_object rhs);
		result_transaction copied_transaction_h;
		assert(rhs != null) else
			`uvm_fatal("RESULT TRANSACTION","Tried to copy null transaction");
		super.do_copy(rhs);
		assert($cast(copied_transaction_h,rhs)) else
			`uvm_fatal("RESULT TRANSACTION","Failed cast in do_copy");
		error_flag = copied_transaction_h.error_flag;
		C_data = copied_transaction_h.C_data;
		flag_out = copied_transaction_h.flag_out;
		CRC37 = copied_transaction_h.CRC37;
		data_type = copied_transaction_h.data_type;
	endfunction : do_copy

	function string convert2string();
		string s;
		s = $sformatf("C_data: %h, error_flag: %h, flag_out: %h, CRC37: %h, data_type: %b ",C_data, error_flag, flag_out, CRC37, data_type ); 
		return s;
	endfunction : convert2string

	function bit do_compare(uvm_object rhs, uvm_comparer comparer);
		result_transaction RHS;
		bit same;
		assert(rhs != null) else
			`uvm_fatal("RESULT TRANSACTION","Tried to compare null transaction");

		same = super.do_compare(rhs, comparer);

		$cast(RHS, rhs);
		same = (error_flag == RHS.error_flag) && same &&(C_data == RHS.C_data ) && (flag_out == RHS.flag_out ) && (CRC37 == RHS.CRC37 ) && (data_type == RHS.data_type );
		return same;
	endfunction : do_compare



endclass : result_transaction
