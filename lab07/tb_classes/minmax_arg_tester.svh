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
class minmax_arg_tester extends random_tester;

    `uvm_component_utils(minmax_arg_tester)

    
    protected function [31:0] get_data();
		randcase
			50:     return '0;
			50:     return '1;
		endcase

	endfunction : get_data

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

endclass : minmax_arg_tester
