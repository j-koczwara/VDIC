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
class random_command extends uvm_transaction;
	`uvm_object_utils(random_command)

//------------------------------------------------------------------------------
// transaction variables
//------------------------------------------------------------------------------

	rand bit [31:0]  A;
	rand bit [31:0]  B;
	rand operation_t op;
	rand bit         crc_ok;
	rand bit         [3:0]   data_len; 
	bit         [3:0]   expected_flag;
	//bit                 done;

//------------------------------------------------------------------------------
// constraints
//------------------------------------------------------------------------------

	constraint data {
		A dist {0:=1, [32'h00 : 32'hFFFFFFFE]:=1, 32'hFFFFFFFF:=1};
		B dist {0:=1, [32'h00 : 32'hFFFFFFFE]:=1, 32'hFFFFFFFF:=1};
		data_len dist {7:=1, 8:=8, 9:=1};
		crc_ok dist   {0:=1, 1:=9};
	}

//------------------------------------------------------------------------------
// transaction functions: do_copy, clone_me, do_compare, convert2string
//------------------------------------------------------------------------------

	function void do_copy(uvm_object rhs);
		random_command copied_transaction_h;

		if(rhs == null)
			`uvm_fatal(" RANDOM COMMAND TRANSACTION", "Tried to copy from a null pointer")

		super.do_copy(rhs); // copy all parent class data

		if(!$cast(copied_transaction_h,rhs))
			`uvm_fatal(" RANDOM COMMAND TRANSACTION", "Tried to copy wrong type.")

		A  = copied_transaction_h.A;
		B  = copied_transaction_h.B;
		op = copied_transaction_h.op;
		crc_ok = copied_transaction_h.crc_ok;
		data_len = copied_transaction_h.data_len;
		expected_flag = copied_transaction_h.expected_flag;
		//done = copied_transaction_h.done;

	endfunction : do_copy


	function random_command clone_me();

		random_command clone;
		uvm_object tmp;

		tmp = this.clone();
		$cast(clone, tmp);
		return clone;

	endfunction : clone_me


	function bit do_compare(uvm_object rhs, uvm_comparer comparer);

		random_command compared_transaction_h;
		bit same;

		if (rhs==null) `uvm_fatal("RANDOM TRANSACTION",
				"Tried to do comparison to a null pointer");

		if (!$cast(compared_transaction_h,rhs))
			same = 0;
		else
			same = super.do_compare(rhs, comparer) &&
			(compared_transaction_h.A == A) &&
			(compared_transaction_h.B == B) &&
			(compared_transaction_h.op == op) &&
			(compared_transaction_h.crc_ok == crc_ok)&&
			(compared_transaction_h.data_len == data_len)&&
			(compared_transaction_h.expected_flag == expected_flag);
//			(compared_transaction_h.done == done);

		return same;

	endfunction : do_compare


	function string convert2string();
		string s;
		s = $sformatf("A: %2h  B: %2h op: %s", A, B, op.name());
		return s;
	endfunction : convert2string

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

	function new (string name = "");
		super.new(name);
	endfunction : new

endclass : random_command


