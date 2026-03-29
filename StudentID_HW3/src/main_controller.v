module main_controller(
    input  wire [6:0] opcode,
    output reg [1:0] alu_op,
    output reg [2:0] imm_src,
    output reg reg_write,
    output reg alu_src_a,
    output reg alu_src_b,
    output reg mem_write,
    output reg [1:0] result_src,
    output reg csr_result,
    output reg branch,
    output reg jump,
    output reg dm_request,
);

    always @(*) begin
        alu_op     = 2'bx;
        imm_src    = 3'bx;
        reg_write  = 1'b0;
        alu_src_a  = 1'b0;
        alu_src_b  = 1'b0;
        mem_write  = 1'b0;
        result_src = 2'bx;
        csr_result = 1'b0;
        branch     = 1'b0;
        jump = 1'b0;
        dm_request = 1'b0;

        case (opcode)
            7'b0110011: begin // R-Type
                alu_op     = 2'b10;
                reg_write  = 1'b1;
                alu_src_a  = 1'b1;  // rs1
                alu_src_b  = 1'b1;  // rs2
                result_src = 2'b00; // ALU
            end
            
            7'b0010011: begin // I-Type 
                alu_op     = 2'b10;
                imm_src    = 3'b001; 
                reg_write  = 1'b1;
                alu_src_a  = 1'b1;  // rs1
                alu_src_b  = 1'b0;  // imm
                result_src = 2'b00; // ALU
            end
            
            7'b0000011: begin // LW 
                alu_op     = 2'b00;
                imm_src    = 3'b001;
                reg_write  = 1'b1;
                alu_src_a  = 1'b1;  // rs1
                alu_src_b  = 1'b0;  // imm
                result_src = 2'b01; // Memory
                dm_request = 1'b1;
            end
            
            7'b0100011: begin // SW 
                alu_op     = 2'b00;
                imm_src    = 3'b010;
                alu_src_a  = 1'b1;  // rs1
                alu_src_b  = 1'b0;  // imm
                mem_write  = 1'b1;
            end
            
            7'b1100011: begin // BEQ 
                alu_op     = 2'b01;
                imm_src    = 3'b100;
                alu_src_a  = 1'b1;  // rs1
                alu_src_b  = 1'b1;  // rs2 
                branch     = 1'b1;
            end

            7'b1101111: begin // JAL
                alu_op     = 2'b00;
                imm_src    = 3'b000;
                reg_write  = 1'b1;
                result_src = 2'b11; // PC + 4
                jump = 1'b1;
            end
            
            7'b1110011: begin // CSR
                alu_op     = 2'b11;
                imm_src    = 3'b001;
                reg_write  = 1'b1;
                csr_result = 1'b1;
            end
            
            7'b0110111: begin // LUI
                alu_op     = 2'b00;
                imm_src    = 3'b011; // U-Type
                reg_write  = 1'b1;
                result_src = 2'b10;  // imm
            end

            7'b0010111: begin // AUIPC
                alu_op     = 2'b00;
                imm_src    = 3'b011; // U-Type
                reg_write  = 1'b1;
                alu_src_a  = 1'b0;   // PC
                alu_src_b  = 1'b0;   // imm
                result_src = 2'b00;  // ALU (PC + imm)
            end

            7'b1100111: begin // JALR
                alu_op     = 2'b00;
                imm_src    = 3'b001; // I-Type
                reg_write  = 1'b1;
                alu_src_a  = 1'b1;   // rs1
                alu_src_b  = 1'b0;   // imm
                result_src = 2'b11;  // PC + 4
                jump = 1'b1;
            end
            
            default: ; 
        endcase
    end
endmodule