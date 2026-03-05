module RISCVALU (funct3, funct7, src_A_i, src_B_i, result_o);
    input [2:0] funct3;
    input [6:0] funct7;
    input [31:0] src_A_i, src_B_i;
    output reg [31:0] result_o;

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
                    3'b000: result_o = (src_A_i * src_B_i)[31:0]; //MUL
                    3'b001: result_o = ($signed(src_A_i) * $signed(src_B_i))[63:32]; //MULH
                    3'b010: result_o = ($signed(src_A_i) * src_B_i)[63:32]; //MULHSU
                    3'b011: result_o = (src_A_i * $signed(src_B_i))[63:32]; //MULHU
                    default: result_o = 0;
                endcase
            end

        endcase
    end