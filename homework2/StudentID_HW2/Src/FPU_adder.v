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
	wire [7:0] delta_exp;
	assign delta_exp = (exp_a > exp_b) ? (exp_a - exp_b) : (exp_b - exp_a);

	wire [23:0] shifted_frac_a, shifted_frac_b;
	assign shifted_frac_a = (exp_a > exp_b) ? {1'b1, frac_a} : ({1'b1, frac_a} >> delta_exp);
	assign shifted_frac_b = (exp_b > exp_a) ? {1'b1, frac_b} : ({1'b1, frac_b} >> delta_exp);

	wire [23:0] small_frac = (exp_a > exp_b) ? {1'b1, frac_b} : {1'b1, frac_a};

	// Calculate guard, round, and sticky bits for rounding
	reg guard_bit, round_bit, sticky_bit;
	// assign guard_bit = (delta_exp != 0) ? ((exp_a > exp_b) ? frac_b[delta_exp -1] : frac_a[delta_exp -1]) : 0;
	// assign round_bit = (delta_exp != 0) ? ((exp_a > exp_b) ? frac_b[delta_exp -2] : frac_a[delta_exp -2]) : 0;
	// assign sticky_bit = (delta_exp != 0) ? ((exp_a > exp_b) ? |frac_b[delta_exp -3:0] : |frac_a[delta_exp -3:0]) : 0;

	reg [24:0] sum_frac, sum_frac_norm;
	reg [7:0] sum_exp, sum_exp_norm;
	reg sum_sign;

	integer i;
	reg [26:0] ext_frac_a, ext_frac_b;
	reg [27:0] sum_frac_ext; // 28-bit để chứa cả bit tràn (carry out)
	reg [26:0] temp_norm;

	always @(*) begin
		guard_bit  = 1'b0;
		round_bit  = 1'b0;
		sticky_bit = 1'b0;

		// 2. Trích xuất Guard an toàn (Chỉ lấy khi chỉ số nằm trong khoảng 0 -> 23)
        // Nếu delta_exp >= 25, guard_bit tự động bằng 0
        if (delta_exp >= 1 && delta_exp <= 24) begin
            guard_bit = small_frac[delta_exp - 1];
        end

        // 3. Trích xuất Round an toàn (Chỉ lấy khi chỉ số nằm trong khoảng 0 -> 23)
        // Nếu delta_exp >= 26, round_bit tự động bằng 0
        if (delta_exp >= 2 && delta_exp <= 25) begin
            round_bit = small_frac[delta_exp - 2];
        end

        // 4. Trích xuất Sticky an toàn
        if (delta_exp >= 3) begin
            if (delta_exp > 25) begin
                // Nếu dịch quá xa, toàn bộ 24 bit của số nhỏ đều rơi hết vào giỏ Sticky
                sticky_bit = |small_frac; 
            end else begin
                sticky_bit = 1'b0;
                for (i = 0; i < 24; i = i + 1) begin
                    if (i < delta_exp - 2) begin
                        sticky_bit = sticky_bit | small_frac[i];
                    end
                end
            end
        end
		
		if (!(NaN_a || NaN_b || Inf_a || Inf_b || Zero_a || Zero_b)) begin
            sum_exp = (exp_a > exp_b) ? exp_a : exp_b; 

            // 1. GHÉP MANTISSA VÀ GRS THÀNH 27-BIT
            if (exp_a > exp_b) begin
                ext_frac_a = {shifted_frac_a, 3'b000};
                ext_frac_b = {shifted_frac_b, guard_bit, round_bit, sticky_bit};
            end else if (exp_b > exp_a) begin
                ext_frac_a = {shifted_frac_a, guard_bit, round_bit, sticky_bit};
                ext_frac_b = {shifted_frac_b, 3'b000};
            end else begin
                ext_frac_a = {shifted_frac_a, 3'b000};
                ext_frac_b = {shifted_frac_b, 3'b000};
            end

            // 2. TÍNH TOÁN TRÊN THANH GHI 27-BIT CHUẨN (Tự động handle mượn/nhớ bit)
            if (!sub) begin
                if (sign_a == sign_b) begin
                    sum_frac_ext = ext_frac_a + ext_frac_b;
                    sum_sign = sign_a;
                end else begin
                    sum_frac_ext = (ext_frac_a > ext_frac_b) ? (ext_frac_a - ext_frac_b) : (ext_frac_b - ext_frac_a);
                    sum_sign = (ext_frac_a > ext_frac_b) ? sign_a : sign_b;
                end
            end else begin
                if (sign_a == sign_b) begin
                    sum_frac_ext = (ext_frac_a > ext_frac_b) ? (ext_frac_a - ext_frac_b) : (ext_frac_b - ext_frac_a);
                    sum_sign = (ext_frac_a > ext_frac_b) ? sign_a : ~sign_a;
                end else begin
                    sum_frac_ext = ext_frac_a + ext_frac_b;
                    sum_sign = sign_a;
                end
            end

            // 3. CHUẨN HÓA (NORMALIZATION)
            if (sum_frac_ext[27]) begin 
                // Tràn bit (Carry out) -> Dịch phải 1 bit
                sum_frac_norm = sum_frac_ext[27:4];
                guard_bit     = sum_frac_ext[3];
                round_bit     = sum_frac_ext[2];
                sticky_bit    = sum_frac_ext[1] | sum_frac_ext[0]; // Gom các bit rớt ra vào sticky
                sum_exp_norm  = sum_exp + 8'd1;
            end else begin
                // Không tràn -> Kiểm tra triệt tiêu (Cancellation) để dịch trái
                sum_exp_norm = sum_exp;
                temp_norm    = sum_frac_ext[26:0];

                if (temp_norm != 0) begin
                    for (i = 0; i < 24; i = i + 1) begin
                        if ((temp_norm[26] == 0) && (sum_exp_norm > 0)) begin
                            temp_norm    = temp_norm << 1;
                            sum_exp_norm = sum_exp_norm - 8'd1;
                        end
                    end
                end
                
                // Tách ngược lại Mantissa 24-bit và GRS sau khi đã dịch xong
                sum_frac_norm = temp_norm[26:3];
                guard_bit     = temp_norm[2];
                round_bit     = temp_norm[1];
                sticky_bit    = temp_norm[0];
            end

            // 4. LÀM TRÒN (ROUNDING)
            if (guard_bit && (round_bit || sticky_bit || sum_frac_norm[0])) begin
                sum_frac_norm = sum_frac_norm + 24'd1;
                if (sum_frac_norm[24]) begin // Tràn sau khi làm tròn
                    sum_exp_norm  = sum_exp_norm + 8'd1;
                    sum_frac_norm = sum_frac_norm >> 1;
                end
            end
        end
		else begin
			sum_frac_norm = 0;
			sum_exp_norm = 0;
			sum_sign = 0;
		end
	end

	always @(*) begin
        // Khởi tạo mặc định để tránh sinh ra Latch
        output_c = 32'b0;
        output_c_ready = 1'b0;

        if (rst) begin
            output_c = 32'b0;
            output_c_ready = 1'b1;
        end
        else if (enable) begin
            if (!(NaN_a || NaN_b || Inf_a || Inf_b || Zero_a || Zero_b)) begin
                // Normal case
                output_c = {sum_sign, sum_exp_norm, sum_frac_norm[22:0]};
                output_c_ready = 1'b1;
                
            end else if (NaN_a || NaN_b) begin
                output_c = 32'hFFC00000; // NaN
                output_c_ready = 1'b1;
            end
            // Any inf in operand
            else if (Inf_a || Inf_b) begin
				if (Inf_a && Inf_b) begin
					if (sign_a == sign_b) begin
						if (!sub) begin
							output_c = {sign_a, 8'hFF, 23'b0}; // Inf
							output_c_ready = 1'b1;
						end 
						else begin
							output_c = 32'hFFC00000;
							output_c_ready = 1'b1;
						end
					end
					// sign mismatch inf (+inf + -inf)
					else begin
						if (sub) begin
							output_c = {sign_a, 8'hFF, 23'b0}; // Inf
							output_c_ready = 1'b1;
						end 
						else begin
							output_c = 32'hFFC00000;
							output_c_ready = 1'b1;
						end 
					end
				end else if (Inf_a) begin
					if (!sub) begin
						output_c = {sign_a, 8'hFF, 23'b0}; // Inf
						output_c_ready = 1'b1;
					end 
					else begin
						output_c = 32'hFFC00000;
						output_c_ready = 1'b1;
					end
				end else if (Inf_b) begin
					if (!sub) begin
						output_c = {sign_b, 8'hFF, 23'b0}; // Inf
						output_c_ready = 1'b1;
					end 
					else begin
						output_c = 32'hFFC00000;
						output_c_ready = 1'b1;
					end 
				end
                if (sign_a == sign_b) begin
                    if (!sub) begin
                        output_c = {sign_a, 8'hFF, 23'b0}; // Inf
                        output_c_ready = 1'b1;
                    end 
                    else begin
                        output_c = 32'hFFC00000;
                        output_c_ready = 1'b1;
                    end
                end
                // sign mismatch inf (+inf + -inf)
                else begin
                    if (sub) begin
                        output_c = {sign_a, 8'hFF, 23'b0}; // Inf
                        output_c_ready = 1'b1;
                    end 
                    else begin
                        output_c = 32'hFFC00000;
                        output_c_ready = 1'b1;
                    end 
                end
            end
            //  0 + 0 (sign depand on & each other)
            else if (Zero_a && Zero_b) begin
                output_c = (sign_a && sign_b) ? 32'h80000000 : 32'h00000000;
                output_c_ready = 1'b1;
            end
            // Only a 0 in operand
            else if (Zero_a && !Zero_b) begin
                output_c = (sub) ? {~sign_b, exp_b, frac_b} : {sign_b, exp_b, frac_b};
                output_c_ready = 1'b1;
            end
            else if (!Zero_a && Zero_b) begin
                output_c = input_a;
                output_c_ready = 1'b1;
            end
        end
        // Nếu enable == 0, các giá trị sẽ tự động nhận giá trị khởi tạo (32'b0) ở đầu khối always
    end

//put ur design here
	// always @(posedge clk or posedge rst) begin
	// 	if (rst) begin
	// 		output_c <= 32'b0;
	// 		output_c_ready <= 1'b1;
	// 	end
	// 	else begin
	// 		if (enable) begin
	// 			if (!(NaN_a || NaN_b || Inf_a || Inf_b || Zero_a || Zero_b)) begin
	// 				// Normal case
	// 				output_c <= {sum_sign, sum_exp_norm, sum_frac_norm[22:0]};
	// 				output_c_ready <= 1'b1;
					
	// 			end else if (NaN_a || NaN_b) begin
	// 				output_c <= 32'hFFC00000; // NaN
	// 				output_c_ready <= 1'b1;
	// 			end
	// 			// Any inf in operand
	// 			else if (Inf_a || Inf_b) begin
	// 				if (sign_a == sign_b) begin
	// 					if (!sub) begin
	// 						output_c <= {sign_a, 8'hFF, 23'b0}; // Inf
	// 						output_c_ready <= 1'b1;
	// 					end 
	// 					else begin
	// 						output_c <= 32'hFFC00000;
	// 						output_c_ready <= 1'b1;
	// 					end
	// 				end
	// 				// sign mismatch inf (+inf + -inf)
	// 				else begin
	// 					if (sub) begin
	// 						output_c <= {sign_a, 8'hFF, 23'b0}; // Inf
	// 						output_c_ready <= 1'b1;
	// 					end	
	// 					else begin
	// 						output_c <= 32'hFFC00000;
	// 						output_c_ready <= 1'b1;
	// 					end 
	// 				end
	// 			end
	// 			//  0 + 0 (sign depand on & each other)
	// 			else if (Zero_a && Zero_b) begin
	// 				output_c <= (sign_a && sign_b) ? 32'h80000000 : 32'h00000000;
	// 				output_c_ready <= 1'b1;
	// 			end
	// 			// Only a 0 in operand
	// 			else if (Zero_a && !Zero_b) begin
	// 				output_c <= (sub) ? {~sign_b, exp_b, frac_b} : {sign_b, exp_b, frac_b};
	// 				output_c_ready <= 1'b1;
	// 			end
	// 			else if (!Zero_a && Zero_b) begin
	// 				output_c <= input_a;
	// 				output_c_ready <= 1'b1;
	// 			end
	// 		end
	// 		else begin
	// 			output_c <= 32'b0;
	// 			output_c_ready <= 1'b0;
	// 		end
	// 	end
	// end
  
endmodule        