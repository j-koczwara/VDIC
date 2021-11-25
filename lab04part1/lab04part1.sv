
virtual class shape;
	real width;
	real height;
	function new(real w, real h);
		width = w;
		height = h;
	endfunction : new

	pure virtual function real get_area();

	pure virtual function void print();

endclass : shape


class rectangle extends shape;

	function new (real width, real height);
		super.new(.w(width), .h(height));
	endfunction : new

	function real get_area();
		return width*height;
	endfunction : get_area

	function void print();
		$display("Rectangle w=%g, h=%g, area=%g", width, height, get_area());
	endfunction : print


endclass : rectangle

class square extends rectangle;
	function new(real side);
		super.new(.width(side), .height(side));
	endfunction

	function void print();
		$display("Square w=%g, area=%g", width, get_area());
	endfunction : print
endclass : square

class triangle extends shape;

	function new (real width, real height);
		super.new(.w(width), .h(height));
	endfunction : new

	function real get_area();
		return width*height/2;
	endfunction : get_area

	function void print();
		$display("Triangle w=%g, h=%g, area=%g", width, height, get_area());
	endfunction : print
endclass : triangle

class shape_reporter #(type T=shape);

	protected static T queuesshape_storage[$];

	static function void save_shape(T l);
		queuesshape_storage.push_back(l);
	endfunction : save_shape

	static function void report_shapes();
		real total_area = 0;
		foreach (queuesshape_storage[i]) begin
			queuesshape_storage[i].print();
			total_area = total_area + queuesshape_storage[i].get_area();
		end
		$display("Total area: %g", total_area);
	endfunction : report_shapes

endclass : shape_reporter

class shape_factory;

	static function shape make_shape(string shape, real width, real height);

		rectangle rectangle_h;
		square square_h;
		triangle triangle_h;

		case (shape)
			"rectangle" : begin
				rectangle_h = new(width, height);
				shape_reporter#(rectangle)::save_shape(rectangle_h);
				return rectangle_h;
			end

			"square" : begin
				square_h = new(width);
				shape_reporter#(square)::save_shape(square_h);
				return square_h;
			end

			"triangle" : begin
				triangle_h = new(width, height);
				shape_reporter#(triangle)::save_shape(triangle_h);
				return triangle_h;
			end

			default :
				$display (1, {"No such shape: %s", shape});

		endcase // case (shape)

	endfunction : make_shape

endclass : shape_factory




module top;


	initial begin
		int file;
		string fline[3];
		int code;
		
		file = $fopen("./lab04part1_shapes.txt", "r");
		while(! $feof(file)==1) begin
			code = $fscanf(file, "%s %s %s", fline[0], fline[1], fline[2]);
			if(code!=-1) begin
				void'(shape_factory::make_shape(fline[0], fline[1].atoreal(), fline[2].atoreal()));

			end

		end
		shape_reporter#(.T(rectangle))::report_shapes();
		shape_reporter#(.T(square))::report_shapes();
		shape_reporter#(.T(triangle))::report_shapes();
	end
endmodule : top

