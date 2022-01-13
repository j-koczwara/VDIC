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
class result_monitor extends uvm_component;
	`uvm_component_utils(result_monitor)

	uvm_analysis_port #(result_transaction) ap;
	virtual alu_bfm bfm;

	function new (string name, uvm_component parent);
		super.new(name, parent);
	endfunction : new
	
	function void build_phase(uvm_phase phase);
		if(!uvm_config_db #(virtual alu_bfm)::get(null, "*","bfm", bfm))
			`uvm_fatal("RESULT MONITOR", "Failed to get BFM")
		//bfm.result_monitor_h = this;
		ap                   = new("ap",this);
	endfunction : build_phase
	
//------------------------------------------------------------------------------
// connect phase
//------------------------------------------------------------------------------

   function void connect_phase(uvm_phase phase);
      bfm.result_monitor_h = this;
   endfunction : connect_phase
   

	function void write_to_monitor(error_flag   error_flag,
			bit signed  [31:0]        C_data,
			bit         [3:0]         flag_out,
			bit         [2:0]         CRC37,
			bit         [1:0]         data_type
		
		);


		result_transaction result_t;
		result_t        = new("result_t");
		result_t.error_flag = error_flag;
		result_t.C_data = C_data;
		result_t.flag_out = flag_out;
		result_t.CRC37 = CRC37;
		result_t.data_type = data_type;
		ap.write(result_t);
	endfunction : write_to_monitor




endclass : result_monitor






