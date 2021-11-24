class coverage;

	virtual alu_bfm bfm;

	bit signed        [31:0]  A;
	bit signed        [31:0]  B;
	operation_t         op_set;
	bit                 crc_ok;
	bit         [3:0]   data_len;
	bit         [3:0]   expected_flag;

	covergroup op_cov;

		option.name = "cg_op_cov";

		coverpoint op_set {
			// #A1 test all operations
			bins A1_all_ops[] = {[and_op : reset_op ]};

			// #A2 two operations in row
			bins A2_twoops[]       = ([and_op:sub_op] [* 2]);

			// #A3 test all operations after reset
			bins A3_rst_opn[]      = (reset_op => [and_op : sub_op]);

			// #A4 test reset after all operations
			bins A4_opn_rst[]      = ([add_op:sub_op] => reset_op);


		}

	endgroup

// Covergroup checking for min and max arguments of the ALU
	covergroup zeros_or_ones_on_ops;

		option.name = "cg_zeros_or_ones_on_ops";

		all_ops : coverpoint op_set {
			ignore_bins null_ops = {reset_op, notused2_op, notused3_op};
		}

		a_leg: coverpoint A {
			bins zeros = {'h00000000};
			bins ones  = {-1};
		}

		b_leg: coverpoint B {
			bins zeros = {'h00000000};
			bins ones  = {-1};
		}

		B_op_00_FF: cross a_leg, b_leg, all_ops {

			// #B1 simulate all zero input for all the operations

			bins B1_add_00          = binsof (all_ops) intersect {add_op} &&
			(binsof (a_leg.zeros) || binsof (b_leg.zeros));

			bins B1_and_00          = binsof (all_ops) intersect {and_op} &&
			(binsof (a_leg.zeros) || binsof (b_leg.zeros));

			bins B1_or_00          = binsof (all_ops) intersect {or_op} &&
			(binsof (a_leg.zeros) || binsof (b_leg.zeros));

			bins B1_sub_00          = binsof (all_ops) intersect {sub_op} &&
			(binsof (a_leg.zeros) || binsof (b_leg.zeros));

			// #B2 simulate all one input for all the operations

			bins B2_add_FF          = binsof (all_ops) intersect {add_op} &&
			(binsof (a_leg.ones) || binsof (b_leg.ones));

			bins B2_and_FF          = binsof (all_ops) intersect {and_op} &&
			(binsof (a_leg.ones) || binsof (b_leg.ones));

			bins B2_or_FF          = binsof (all_ops) intersect {or_op} &&
			(binsof (a_leg.ones) || binsof (b_leg.ones));

			bins B2_sub_FF          = binsof (all_ops) intersect {sub_op} &&
			(binsof (a_leg.ones) || binsof (b_leg.ones));


			// #B3 simulate all one input A and B for all the operations

			bins B3_add_FF          = binsof (all_ops) intersect {add_op} &&
			(binsof (a_leg.ones) && binsof (b_leg.ones));

			bins B3_and_FF          = binsof (all_ops) intersect {and_op} &&
			(binsof (a_leg.ones) && binsof (b_leg.ones));

			bins B3_or_FF          = binsof (all_ops) intersect {or_op} &&
			(binsof (a_leg.ones) && binsof (b_leg.ones));

			bins B3_sub_FF          = binsof (all_ops) intersect {sub_op} &&
			(binsof (a_leg.ones) && binsof (b_leg.ones));

			// #B4 simulate all zero input A and B for all the operations

			bins B4_add_00          = binsof (all_ops) intersect {add_op} &&
			(binsof (a_leg.zeros) && binsof (b_leg.zeros));

			bins B4_and_00         = binsof (all_ops) intersect {and_op} &&
			(binsof (a_leg.zeros) && binsof (b_leg.zeros));

			bins B4_or_00         = binsof (all_ops) intersect {or_op} &&
			(binsof (a_leg.zeros) && binsof (b_leg.zeros));

			bins B4_sub_00         = binsof (all_ops) intersect {sub_op} &&
			(binsof (a_leg.zeros) && binsof (b_leg.zeros));

		}

	endgroup


// Covergroup checking for flags
	covergroup flags_cov;

		option.name = "cg_flags";

		all_ops : coverpoint op_set {
			ignore_bins null_ops = {reset_op, notused2_op, notused3_op};
		}

		flag_leg: coverpoint expected_flag {
			bins carry = {'b1000};
			bins overflow = {'b0100};
			bins zero  = {'b0010};
			bins negative = {'b0001};
			bins others  = {'b1100, 'b1010, 'b1001, 'b0110, 'b0101};
		}


		Flags: cross flag_leg, all_ops {

			//  simulate Overflow flag

			bins C1_sub_overflow            = binsof (all_ops) intersect {sub_op} &&
			(binsof (flag_leg.overflow));

			//  simulate carry flag

			bins C2_add_carry           = binsof (all_ops) intersect {add_op} &&
			(binsof (flag_leg.carry));

			bins C3_sub_carry            = binsof (all_ops) intersect {sub_op} &&
			(binsof (flag_leg.carry));

			// negative flag

			bins C4_add_negative           = binsof (all_ops) intersect {add_op} &&
			(binsof (flag_leg.negative));

			bins C5_sub_negative            = binsof (all_ops) intersect {sub_op} &&
			(binsof (flag_leg.negative));

			bins C6_and_negative           = binsof (all_ops) intersect {and_op} &&
			(binsof (flag_leg.negative));

			bins C7_or_negative            = binsof (all_ops) intersect {or_op} &&
			(binsof (flag_leg.negative));


			//  zero flag

			bins C8_add_zero           = binsof (all_ops) intersect {add_op} &&
			(binsof (flag_leg.zero));

			bins C9_sub_zero            = binsof (all_ops) intersect {sub_op} &&
			(binsof (flag_leg.zero));

			bins C10_and_zero           = binsof (all_ops) intersect {and_op} &&
			(binsof (flag_leg.zero));

			bins C11_or_zero            = binsof (all_ops) intersect {or_op} &&
			(binsof (flag_leg.zero));


			ignore_bins overflow_or = binsof (all_ops) intersect {or_op} &&
			binsof(flag_leg.overflow);
			ignore_bins overflow_and = binsof (all_ops) intersect {and_op} &&
			binsof(flag_leg.overflow);
			ignore_bins overflow_add = binsof (all_ops) intersect {add_op} &&
			binsof(flag_leg.overflow);
			ignore_bins carry_or = binsof (all_ops) intersect {or_op} &&
			binsof(flag_leg.carry);
			ignore_bins carry_and = binsof (all_ops) intersect {and_op} &&
			binsof(flag_leg.carry);
			ignore_bins others_or = binsof (all_ops) intersect {or_op} &&
			binsof(flag_leg.others);
			ignore_bins others_and = binsof (all_ops) intersect {and_op} &&
			binsof(flag_leg.others);
		}

	endgroup

// Covergroup checking for errors
	covergroup errors_cov;

		option.name = "cg_errors";

		data_len_leg: coverpoint data_len {
			bins D1_less  = {7};
			bins D2_more  = {9};
		}
		crc_leg: coverpoint crc_ok {
			bins D3_crc_error = {0};
		}

		ops_leg : coverpoint op_set {
			bins D4_error_ops = {notused2_op, notused3_op};
		}

		D5_multiple_errors: cross crc_leg, data_len_leg, ops_leg;

	endgroup


	function new (virtual alu_bfm b);
		errors_cov                  = new();
		op_cov                      = new();
		zeros_or_ones_on_ops        = new();
		flags_cov                   = new();
		bfm                  = b;
	endfunction : new


	task execute();
		forever begin : sample_cov
			@(posedge bfm.clk);
			A      = bfm.A;
			B      = bfm.B;
			op_set = bfm.op_set;
			data_len=bfm.data_len;
			crc_ok=bfm.crc_ok;
			expected_flag=bfm.expected_flag;
			errors_cov.sample();
			op_cov.sample();
			zeros_or_ones_on_ops.sample();
			flags_cov.sample();
		end
	endtask

	

endclass
