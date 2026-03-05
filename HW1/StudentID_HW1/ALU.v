module ALU (funct3, funct7, src_A_i, src_B_i, result_o);
    input [2:0] funct3;
    input [6:0] funct7;
    input [31:0] src_A_i, src_B_i;
    output reg [31:0] result_o;

    reg [63:0] mul_result;

    always @(funct3, funct7, src_A_i, src_B_i) begin
        case (funct7)
            7'b0000000: begin
                case (funct3)
                    3'b000: result_o = src_A_i + src_B_i; // ADD
                    3'b001: result_o = src_A_i << src_B_i[4:0]; //SLL
                    3'b010: result_o = ($signed(src_A_i) < $signed(src_B_i)) ? 1 : 0; // SLT
                    3'b011: result_o = (src_A_i < src_B_i) ? 1 : 0; // SLTU
                    3'b100: result_o = src_A_i ^ src_B_i; //XOR
                    3'b101: result_o = src_A_i >> src_B_i[4:0]; //SRL
                    3'b110: result_o = src_A_i | src_B_i; //XOR
                    3'b111: result_o = src_A_i & src_B_i; //AND
                    default: result_o = 0;
                endcase 
            end
            7'b0100000: begin
                case (funct3)
                    3'b000: result_o = src_A_i - src_B_i; //SUB
                    3'b101: result_o = src_A_i >>> src_B_i[4:0]; //SRA
                    default: result_o = 0;
                endcase
            end
            7'b0000001: begin
                case (funct3)
                3'b000: begin // MUL
                    mul_result = src_A_i * src_B_i;
                    result_o = mul_result[31:0];
                end
                3'b001: begin // MULH
                    mul_result = $signed(src_A_i) * $signed(src_B_i);
                    result_o = mul_result[63:32];
                end
                3'b010: begin // MULHSU
                    mul_result = $signed(src_A_i) * src_B_i;
                    result_o = mul_result[63:32];
                end
                3'b011: begin // MULHU
                    mul_result = src_A_i * src_B_i;
                    result_o = mul_result[63:32];
                end
                default: result_o = 0;
                endcase
            end

        endcase
    end
endmodule