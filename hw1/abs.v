module refabs(b, a);
	parameter BITS = 16;
	input signed [BITS - 1:0] a;
	output signed [BITS - 1:0] b;
	
	assign b = ((a < 0) ? -a : a);

endmodule

module mux(out1, in2, in1, select);
	input select, in1, in2;
	output out1;
	
	assign out1 = (~select & in1) | (select & in2);
	
endmodule

/* module test_mux;
	reg select, in1, in2;
	reg signed [3:0] a;
	wire c;
	
	reg [2: 0] failed = 0;
	
	mux onebit_mux(c, in2, in1, select);

	initial begin
	  a = 0;
	  repeat (8) begin
	
		select = a[0];
		in1 = a[1];
		in2 = a[2];
		
		#1 // time for values to propagate
	
		$display("%b %b %b %b", select, in1, in2, c);
		case (select)
			0: if(in1 ^ c) failed = failed + 1;
			1: if(in2 ^ c) failed = failed + 1;
		endcase
			
		#1 a = a + 1;
	  end
	  $display("All cases tested; %d correct, %d failed", 8 - failed, failed);
			
	end
	
endmodule */

module n_mux_one_select(out1, in2, in1, select);
	parameter BITS = 16;
	input select;
	input signed [BITS - 1:0] in1, in2;
	output signed [BITS - 1:0] out1;
	
	genvar i;
	generate for(i=0; i<BITS; i = i + 1) 
		begin:muxs
			mux onebit(out1[i], in2[i], in1[i], select);
		end
	endgenerate
		
endmodule


module one_bit_adder(S, cout, cin, b, a);
	input a, b, cin;
	output cout, S;
	
	assign S = a ^ b ^ cin;
	assign cout = (a & b) | ((a ^ b) & cin);
	
endmodule

/* module test_adder;
	reg in1, in2, cin;
	reg signed [2:0] a;
	wire c, cout;
	
	reg [2: 0] failed = 0;
	
	one_bit_adder onebit_add(.S(c), .cout(cout), .cin(cin), .b(in2), .a(in1));

	initial begin
	  a = 0;
	  repeat (8) begin
		in1 = a[0];
		in2 = a[1];
		cin = a[2];
		
		#1 // time for values to propagate
	
		$display("%b %b %b -- %b %b", in1, in2, cin, c, cout);
		if( ((^a) ^ c) ) failed = failed + 1;
			
		#1 a = a + 1;
	  end
	  $display("All cases tested; %d correct, %d failed", 8 - failed, failed);
			
	end
	
endmodule  */

module n_bit_adder(S, b, a);
	parameter BITS = 16;
	input signed [BITS - 1:0] a, b;
	output signed [BITS - 1:0] S;
	wire [BITS - 1:0] temp;
	
	one_bit_adder onebit_0(.S(S[0]), .cout(temp[0]), .cin(0), .b(b[0]), .a(a[0]));

	genvar i;
	generate for(i=1; i<BITS; i = i + 1) 
		begin:adds
			one_bit_adder onebit(.S(S[i]), .cout(temp[i]), .cin(temp[i - 1]), .b(b[i]), .a(a[i]));
		end
	endgenerate
	
endmodule

module twos_complement(b, a);
	parameter BITS = 16;
	input [BITS - 1:0] a;
	output [BITS - 1:0] b;
	wire [BITS - 1:0] temp;
		
	n_bit_adder #(BITS) adder(.S(b), .b(1), .a(~a));
	
endmodule

module abs(b, a);
	parameter BITS = 16;
	input signed [BITS - 1:0] a;
	output signed [BITS - 1:0] b;
	
	wire [BITS - 1:0] temp;
	
	twos_complement #(BITS) twos(temp, a);
	
	n_mux_one_select #(BITS) mux_select(b, temp, a, a[15]);
	
endmodule


module testbench;
	parameter BITS = 16;
	reg signed [BITS - 1:0] a;
	wire signed [BITS - 1:0] b, c;
	reg [BITS - 1: 0] failed = 0;
	
	//assign correct = 0;

	refabs #(BITS) testabs(b, a);
	abs #(BITS) myabs(c, a);

	initial begin
	  a = -(2**(BITS-1));
	  repeat (2**BITS) begin
		if (b != c)
		begin
			$display("abs(%d) = %d != %d", a, b, c);
			failed = failed + 1;
		end
		#1 a = a + 1;
	  end
	  $display("All cases tested; %d correct, %d failed", 2**BITS - failed, failed);
	end
	
endmodule