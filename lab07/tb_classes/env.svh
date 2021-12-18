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
class env extends uvm_env;
	`uvm_component_utils(env)

	/* xrun 18.1 warns about object definition from abstract class, will be
	 * upgraded to error in future releases.
	 * This is temporary solution -> sequencer/driver will not have this problem
	 */
 tester tester_h;
    coverage coverage_h;
    scoreboard scoreboard_h;
    driver driver_h;
    command_monitor command_monitor_h;
    result_monitor result_monitor_h;
    uvm_tlm_fifo #(random_command) command_f;


	function new (string name, uvm_component parent);
		super.new(name,parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		command_f         = new("command_f", this);
		tester_h          = tester::type_id::create("tester_h",this);
		driver_h          = driver::type_id::create("drive_h",this);
		coverage_h        = coverage::type_id::create ("coverage_h",this);
		scoreboard_h      = scoreboard::type_id::create("scoreboard_h",this);
		command_monitor_h = command_monitor::type_id::create("command_monitor_h",this);
		result_monitor_h  = result_monitor::type_id::create("result_monitor_h",this);
	endfunction : build_phase

	function void connect_phase(uvm_phase phase);
		/*driver_h.command_port.connect(command_f.get_export);
		tester_h.command_port.connect(command_f.put_export);
		result_monitor_h.ap.connect(scoreboard_h.analysis_export);
		command_monitor_h.ap.connect(scoreboard_h.cmd_f.analysis_export);
		command_monitor_h.ap.connect(coverage_h.analysis_export);*/
	
		//TODO
		driver_h.command_port.connect(command_f.get_export);
        tester_h.command_port.connect(command_f.put_export);
        command_f.put_ap.connect(coverage_h.analysis_export);
        command_monitor_h.ap.connect(scoreboard_h.cmd_f.analysis_export);
        result_monitor_h.ap.connect(scoreboard_h.analysis_export);
	endfunction : connect_phase

	function void end_of_elaboration_phase(uvm_phase phase);
		super.end_of_elaboration_phase(phase);
		// display created tester type
		$write("\033\[1;30m\033\[103m"); // bold black on yellow
		$write("*** Created tester type: %s", tester_h.get_type_name());
		$write("\033\[0m\n");            // back to default color
	endfunction : end_of_elaboration_phase

endclass

