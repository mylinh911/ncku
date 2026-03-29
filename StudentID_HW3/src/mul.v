module mul(
    input [1:0] mul_control,
    input mul_enable,
    input [31:0] src_a,
    input [31:0] src_b,
    output reg [31:0] result
);

    wire [31:0] mul_src_a = mul_enable ? src_a : 32'd0;
    wire [31:0] mul_src_b = mul_enable ? src_b : 32'd0;

    wire is_signed_a = (mul_control == 2'b01) || (mul_control == 2'b10);
    wire is_signed_b = (mul_control == 2'b01);

    wire [63:0] ext_a = { {32{is_signed_a && mul_src_a[31]}}, mul_src_a };
    wire [63:0] ext_b = { {32{is_signed_b && mul_src_b[31]}}, mul_src_b };

    wire [63:0] mul_result_64 = ext_a * ext_b;

    always @(*) begin
        if (mul_control == 2'b00) begin
            result = mul_result_64[31:0]; // MUL
        end
        else begin
            result = mul_result_64[63:32]; // MULH, MULHSU, MULHU
        end
    end
    
endmodule