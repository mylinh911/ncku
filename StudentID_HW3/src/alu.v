module alu(
    input [31:0] src_a,
    input [31:0] src_b,
    input [3:0] alu_control,
    input mul_enable,
    output reg [31:0] alu_result,
    output zero,
    output overflow,
    output negative,
    output carry
);

    wire [31:0] mul_result;
    mul mul_unit (
        .mul_control(alu_control[1:0]),
        .mul_enable(mul_enable),
        .src_a(src_a),
        .src_b(src_b),
        .result(mul_result)
    );

    wire [31:0] b_eff = alu_control[3] ? ~src_b : src_b;
    wire [32:0] sum_full = {1'b0, src_a} + {1'b0, b_eff} + alu_control[3];

    always @(*) begin
        if (mul_enable) begin
            alu_result = mul_result;
        end else begin
            if (alu_control[3] == 1'b0) begin
                case (alu_control[2:0])
                    3'b000: alu_result = src_a + src_b; // ADD
                    3'b001: alu_result = src_a << src_b[4:0]; // SLL
                    3'b010: alu_result = ($signed(src_a) < $signed(src_b)) ? 32'd1 : 32'd0; // SLT
                    3'b011: alu_result = (src_a < src_b) ? 32'd1 : 32'd0; // SLTU
                    3'b100: alu_result = src_a ^ src_b; // XOR
                    3'b101: alu_result = src_a >> src_b[4:0]; // SRL (Logic)
                    3'b110: alu_result = src_a | src_b; // OR
                    3'b111: alu_result = src_a & src_b; // AND
                    default: alu_result = 32'd0;
                endcase
            end else begin
                case (alu_control[2:0])
                    3'b000: alu_result = src_a - src_b; // SUB
                    3'b101: alu_result = $signed(src_a) >>> src_b[4:0]; // SRA
                    default: alu_result = 32'd0;
                endcase
            end
        end
    end

    assign zero = (alu_result == 32'd0);
    assign overflow = (sum_full[31] ^ src_a[31]) &&  ~(alu_control[3] ^ src_a[31] ^ src_b[31]);
    assign negative = alu_result[31];
    assign carry = sum_full[32];

endmodule