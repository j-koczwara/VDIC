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

	//`uvm_component_utils(base_tester)
	uvm_put_port #(command_s) command_port;


	function new (string name, uvm_component parent);
		super.new(name, parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		command_port = new("command_port", this);
	endfunction : build_phase



	protected pure virtual function operation_t get_op();

	protected pure virtual function [31:0] get_data();
	protected pure virtual function bit [3:0] get_data_len();
	protected pure virtual function [4:0] get_crc(bit [31:0] A, bit [31:0] B, operation_t OP);

	task run_phase(uvm_phase phase);
	
		bit         [3:0]   idata_len;
		bit        [10:0]  result [4:0];
		command_s command;
		phase.raise_objection(this);
		command.op = reset_op;
		command_port.put(command);

		repeat (10000) begin : tester_main

			command.op            = get_op();
			command.A             = get_data();
			command.B             = get_data();
			{command.crc, command.crc_ok} = get_crc(command.A ,command.B,command.op);
			command.data_len      = get_data_len();
			command_port.put(command);

		end: tester_main


		#500;

		phase.drop_objection(this);

	endtask : run_phase


endclass : base_tester
