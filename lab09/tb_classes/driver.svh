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
class driver extends uvm_driver#(sequence_item);
	`uvm_component_utils(driver)

	protected virtual alu_bfm bfm;
	
//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
	function new (string name, uvm_component parent);
		super.new(name, parent);
	endfunction : new
	
//------------------------------------------------------------------------------
// build phase
//------------------------------------------------------------------------------

	function void build_phase(uvm_phase phase);
		if(!uvm_config_db #(virtual alu_bfm)::get(null, "*","bfm", bfm))
			`uvm_fatal("DRIVER", "Failed to get BFM")
	endfunction : build_phase

//------------------------------------------------------------------------------
// run phase
//------------------------------------------------------------------------------

	task run_phase(uvm_phase phase);
		sequence_item command;
		void'(begin_tr(command));

		forever begin : command_loop
			error_flag                error_flag;
			bit signed  [31:0]        C_data;
			bit         [3:0]         flag_out;
			bit         [2:0]         CRC37;
			bit         [1:0]         data_type;
			
			seq_item_port.get_next_item(command);
			bfm.send_op(command.A, command.B,  command.crc_ok, command.data_len,  command.op, 
				error_flag, C_data, flag_out, CRC37, data_type);
			command.alu_error_flag =error_flag;
			command.C_data = C_data;
			command.flag_out = flag_out;
			command.CRC37 = CRC37;
			command.data_type = data_type;
			seq_item_port.item_done();
		end : command_loop
	endtask : run_phase



endclass : driver

