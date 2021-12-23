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
class tester extends uvm_component;
	`uvm_component_utils (tester)

	uvm_put_port #(random_command) command_port;


	function new (string name, uvm_component parent);
		super.new(name, parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		command_port = new("command_port", this);
	endfunction : build_phase


	task run_phase(uvm_phase phase);

		random_command command;

		phase.raise_objection(this);

		command = new("command");
		command.op = reset_op;
		command_port.put(command);

		command = random_command::type_id::create("command");

		repeat (1000) begin : tester_main

			assert(command.randomize());
			command_port.put(command);


		end: tester_main


		#500;

		phase.drop_objection(this);

	endtask : run_phase


endclass : tester