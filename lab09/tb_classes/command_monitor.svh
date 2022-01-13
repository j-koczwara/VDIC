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
class command_monitor extends uvm_component;
    `uvm_component_utils(command_monitor)

    uvm_analysis_port #(sequence_item) ap;
	virtual alu_bfm bfm;

//------------------------------------------------------------------------------
// build_phase
//------------------------------------------------------------------------------

    function void build_phase(uvm_phase phase);        

        if(!uvm_config_db #(virtual alu_bfm)::get(null, "*","bfm", bfm))
            $fatal(1, "Failed to get BFM");

        bfm.command_monitor_h = this;

        ap                    = new("ap",this);

    endfunction : build_phase
    
 //------------------------------------------------------------------------------
// connect phase
//------------------------------------------------------------------------------

    function void connect_phase(uvm_phase phase);
        bfm.command_monitor_h = this;
    endfunction : connect_phase
    

    function void write_to_monitor(bit [31:0] A, bit [31:0] B, operation_t op, bit   crc_ok, bit [3:0]   data_len,
		bit  [3:0]   expected_flag);
	    sequence_item cmd;
	    cmd = new("cmd");
	    cmd.A  = A;
        cmd.B  = B;
        cmd.op = op;
	    cmd.crc_ok =crc_ok;

	    cmd.data_len = data_len;
	    cmd.expected_flag = expected_flag;
	 //   cmd.done = done;
	   
        ap.write(cmd);
	    
    endfunction : write_to_monitor

    function new (string name, uvm_component parent);
        super.new(name,parent);
    endfunction

endclass : command_monitor

