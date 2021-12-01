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
//`ifdef QUESTA
//virtual class base_tester extends uvm_component;
//`else
//`ifdef INCA
// irun requires abstract class when using virtual functions
// note: irun warns about the virtual class instantiation, this will be an
// error in future releases.
virtual class base_tester extends uvm_component;
//`else
//class base_tester extends uvm_component;
//`endif
//`endif

	`uvm_component_utils(base_tester)

	virtual alu_bfm bfm;

	function new (string name, uvm_component parent);
		super.new(name, parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		if(!uvm_config_db #(virtual alu_bfm)::get(null, "*","bfm", bfm))
			$fatal(1,"Failed to get BFM");
	endfunction : build_phase

	pure virtual function operation_t get_op();

	pure virtual function [31:0] get_data();
	pure virtual function bit [3:0] get_data_len();
	pure virtual function bit [98:0] get_vector_to_send(bit [63:0] BA, operation_t OP, bit [3:0] crc, bit [4:0] data_len );
	pure virtual function [4:0] get_crc(bit [31:0] A, bit [31:0] B, operation_t OP);
	
	task run_phase(uvm_phase phase);
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

		phase.raise_objection(this);

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
		

//      #500;

		phase.drop_objection(this);

	endtask : run_phase


endclass : base_tester
