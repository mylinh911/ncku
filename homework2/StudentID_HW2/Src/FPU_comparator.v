module FPU_comparator(
    input [31:0] A,
    input [31:0] B,
    input mode, 
    output reg [31:0] answer   
);

//put ur design here 
    // Unpack data to SEF
	wire sign_a = A[31];
	wire sign_b = B[31];
	wire [7:0] exp_a = A[30:23];
	wire [7:0] exp_b = B[30:23];
	wire [22:0] frac_a = A[22:0];
	wire [22:0] frac_b = B[22:0];

	// Find specials cases (NaN, Ind, Zero)
	wire NaN_a, NaN_b, Inf_a, Inf_b, Zero_a, Zero_b;
	assign NaN_a = (exp_a == 8'hFF) && (frac_a != 0);
	assign NaN_b = (exp_b == 8'hFF) && (frac_b != 0);
	assign Inf_a = (exp_a == 8'hFF) && (frac_a == 0);
	assign Inf_b = (exp_b == 8'hFF) && (frac_b == 0);
	assign Zero_a = (exp_a == 0) && (frac_a == 0);
	assign Zero_b = (exp_b == 0) && (frac_b == 0);

    always @(*) begin
        if (NaN_a || NaN_b) begin
            answer <= 32'hFFC00000;
        end
        else if (Zero_a && Zero_b) begin
            answer <= 32'd0;
            end
        else if (Inf_a || Inf_b) begin
            if (Inf_a && Inf_b) begin
                if (sign_a == sign_b) begin
                    answer <= sign_a ? 32'hFF800000 : 32'h7F800000; // Both are the same infinity
                end
                else begin
                    if (mode) begin
                        answer <= 32'h7F800000; 
                    end
                    else begin
                        answer <= 32'hFF800000; 
                    end
                end
            end
            else if (Inf_a) begin
                if (!mode) begin
                    answer <= sign_a ? 32'hFF800000 : B;
                end
                else begin
                    answer <= sign_a ? B : 32'h7F800000;
                end
                
            end
            else if (Inf_b) begin
                if (!mode) begin
                    answer <= sign_b ? 32'hFF800000 : A;
                end
                else begin
                    answer <= sign_b ? A : 32'h7F800000;
                end
            end
        end
        else begin
            if (sign_a != sign_b) begin
                if (mode) begin
                    answer <= sign_a ? B : A;
                end
                else begin
                    answer <= sign_a ? A : B;
                end
            end
            else begin
                if (exp_a != exp_b) begin
                    if (mode) begin
                        answer <= (exp_a > exp_b) ? A : B;
                    end
                    else begin 
                        answer <= (exp_a > exp_b) ? B : A;
                    end
                end
                else begin
                    if (mode) begin
                        answer <= (frac_a > frac_b) ? A : B;
                    end
                    else begin
                        answer <= (frac_a > frac_b) ? B : A;
                    end
                end
            end
        end
    end

endmodule