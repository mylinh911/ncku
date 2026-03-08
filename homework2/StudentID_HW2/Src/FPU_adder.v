module FPU_adder(
		input [31:0] input_a,
		input [31:0] input_b,
		input enable,
		input sub,
		input clk,
		input rst,
		output reg [31:0] output_c,
		output reg output_c_ready);

	// Unpack data to SEF
	wire sign_a = input_a[31];
	wire sign_b = input_b[31];
	wire [7:0] exp_a = input_a[30:23];
	wire [7:0] exp_b = input_b[30:23];
	wire [22:0] frac_a = input_a[22:0];
	wire [22:0] frac_b = input_b[22:0];

	// Find specials cases (NaN, Ind, Zero)
	wire NaN_a, NaN_b, Inf_a, Inf_b, Zero_a, Zero_b;
	assign NaN_a = (exp_a == 8'hFF) && (frac_a != 0);
	assign NaN_b = (exp_b == 8'hFF) && (frac_b != 0);
	assign Inf_a = (exp_a == 8'hFF) && (frac_a == 0);
	assign Inf_b = (exp_b == 8'hFF) && (frac_b == 0);
	assign Zero_a = (exp_a == 0) && (frac_a == 0);
	assign Zero_b = (exp_b == 0) && (frac_b == 0);

	// Right-shift the mantissa of the operand with the smaller exponent
	wire delta_exp;
	assign delta_exp = (exp_a > exp_b) ? (exp_a - exp_b) : (exp_b - exp_a);

	wire [23:0] shifted_frac_a, shifted_frac_b;
	assign shifted_frac_a = (exp_a > exp_b) ? {1'b1, frac_a} : ({1'b1, frac_a} >> delta_exp);
	assign shifted_frac_b = (exp_b > exp_a) ? {1'b1, frac_b} : ({1'b1, frac_b} >> delta_exp);

	// Calculate guard, round, and sticky bits for rounding
	wire guard_bit, round_bit, sticky_bit;
	assign guard_bit = (delta_exp != 0) ? ((exp_a > exp_b) ? frac_b[delta_exp -1] : frac_a[delta_exp -1]) : 0;
	assign round_bit = (delta_exp != 0) ? ((exp_a > exp_b) ? frac_b[delta_exp -2] : frac_a[delta_exp -2]) : 0;
	assign sticky_bit = (delta_exp != 0) ? ((exp_a > exp_b) ? |frac_b[delta_exp -3:0] : |frac_a[delta_exp -3:0]) : 0;

	wire [24:0] sum_frac, sum_frac_norm;
	wire [7:0] sum_exp, sum_exp_norm;
	wire sum_sign;

	always @(*) begin
		if (!(NaN_a || NaN_b || Inf_a || Inf_b || Zero_a || Zero_b)) begin
			sum_exp = (exp_a > exp_b) ? exp_a : exp_b; // The exponent of the result is the larger one

			if (!sub) begin
				if (sign_a == sign_b) begin
					sum_frac = shifted_frac_a + shifted_frac_b;
					sum_sign = sign_a; // Same sign, result has the same sign
				end
				else begin
					sum_frac = (shifted_frac_a > shifted_frac_b) ? (shifted_frac_a - shifted_frac_b) : (shifted_frac_b - shifted_frac_a);
					sum_sign = (shifted_frac_a > shifted_frac_b) ? sign_a : sign_b; // Different sign, result has the sign of the larger mantissa
				end
			end
			else begin
				if (sign_a == sign_b) begin
					sum_frac = (shifted_frac_a > shifted_frac_b) ? (shifted_frac_a - shifted_frac_b) : (shifted_frac_b - shifted_frac_a);
					sum_sign = (shifted_frac_a > shifted_frac_b) ? sign_a : ~sign_a;
				end
				else begin
					sum_frac = shifted_frac_a + shifted_frac_b;
					sum_sign = sign_a; // Same sign, result has the same sign
				end	
			end

			// Handle carry, cancellation
			if (sum_frac[24]) begin
				sum_frac_norm = sum_frac >> 1;
				sum_exp_norm = sum_exp + 1;
			end else begin
				sum_exp_norm = sum_exp;
				sum_frac_norm = sum_frac;

				for (i = 0; i < 24; i = i + 1) begin
					if ((sum_frac_norm[23] == 0) && (sum_exp_norm > 0)) begin
						sum_frac_norm = sum_frac_norm << 1;
						sum_exp_norm  = sum_exp_norm - 1;
					end
				end
			end
			// Apply rounding policy using GRS
			if (guard_bit && (round_bit || sticky_bit || sum_frac_norm[0])) begin
				sum_frac_norm = sum_frac_norm + 1;
				if (sum_frac_norm[24]) begin
					sum_exp_norm = sum_exp_norm + 1;
					sum_frac_norm = sum_frac_norm >> 1;
				end
			end
			else begin
				sum_frac_norm = sum_frac_norm;
				sum_exp_norm = sum_exp_norm;
			end
			
		end 
		else begin
			sum_frac_norm = 0;
			sum_exp_norm = 0;
			sum_sign = 0;
		end
	end


//put ur design here
	always @(posedge clk or posedge rst) begin
		if (rst) begin
			output_c <= 32'b0;
			output_c_ready <= 1'b1;
		end
		else begin
			if (enable) begin
				if (!(NaN_a || NaN_b || Inf_a || Inf_b || Zero_a || Zero_b)) begin
					// Normal case
					output_c <= {sum_sign, sum_exp_norm, sum_frac_norm[22:0]};
					output_c_ready <= 1'b1;
					
				end else if (NaN_a || NaN_b) begin
					output_c <= 32'hFFC00000; // NaN
					output_c_ready <= 1'b1;
				end
				// Any inf in operand
				else if (Inf_a || Inf_b) begin
					if (sign_a == sign_b) begin
						if (!sub) begin
							output_c <= {sign_a, 8'hFF, 23'b0}; // Inf
							output_c_ready <= 1'b1;
						end 
						else begin
							output_c <= 32'hFFC00000;
							output_c_ready <= 1'b1;
						end
					end
					// sign mismatch inf (+inf + -inf)
					else begin
						if (sub) begin
							output_c <= {sign_a, 8'hFF, 23'b0}; // Inf
							output_c_ready <= 1'b1;
						end	
						else begin
							output_c <= 32'hFFC00000;
							output_c_ready <= 1'b1;
						end 
					end
				end
				//  0 + 0 (sign depand on & each other)
				else if (Zero_a && Zero_b) begin
					output_c <= (sign_a && sign_b) ? 32'h80000000 : 32'h00000000;
					output_c_ready <= 1'b1;
				end
				// Only a 0 in operand
				else if (Zero_a && !Zero_b) begin
					output_c <= (sub) ? {~sign_b, exp_b, frac_b} : {sign_b, exp_b, frac_b};
					output_c_ready <= 1'b1;
				end
				else if (!Zero_a && Zero_b) begin
					output_c <= input_a;
					output_c_ready <= 1'b1;
				end
			end
			else begin
				output_c <= output_c;
				output_c_ready <= output_c_ready;
			end
		end
	end
  
endmodule        