module alu_controller(
    input [2:0] funct3,
    input funct7_5,
    input funct7_0,
    input op_5,
    input [1:0] alu_op,
    output reg [3:0] alu_control,
    output mul_enable
);
    wire is_sub = funct7_5 & op_5;
    wire is_shift_arithmetic = funct7_5;

    assign mul_enable = (alu_op == 2'b10) & funct7_0 & op_5;

    always @(*) begin
        case (alu_op)
            2'b00: alu_control = 4'd0; //load, store, jump
            2'b01: alu_control = 4'b1000; //branch
            2'b10: begin //i-type, r-type
                case (funct3)
                    3'b000: alu_control = {is_sub, funct3};
                    3'b101: alu_control = {is_shift_arithmetic, funct3};
                    default: alu_control = {1'b0, funct3};
                endcase
            end
            default: alu_control = 4'bx; 
        endcase
    end
endmodule