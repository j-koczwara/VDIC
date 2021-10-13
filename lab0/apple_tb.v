module apple_tb ();
wire a;
wire b;
wire clk;
wire q;

apple u_apple (
	.a  (a),
	.b  (b),
	.clk(clk),
	.q  (q)
	); 
endmodule
