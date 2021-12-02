module top;
	import uvm_pkg::*;
	`include "uvm_macros.svh"

	import alu_pkg::*;


	mtm_Alu u_mtm_Alu (
		.clk  (bfm.clk), //posedge active clock
		.rst_n(bfm.rst_n), //synchronous reset active low
		.sin  (bfm.sin), //serial data input
		.sout (bfm.sout) //serial data output
	);
	alu_bfm    bfm();


	initial begin
		uvm_config_db #(virtual alu_bfm)::set(null, "*", "bfm", bfm);
		run_test();
	end

endmodule : top
