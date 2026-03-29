module pc_controller(
    input zero,
    input overflow,
    input negative, 
    input carry, 
    input [2:0] funct3,
    input branch,
    input jump,
    output reg pc_src
);

    reg branch_taken;

    always @(*) begin
        case(funct3)
            3'b000: branch_taken = zero; // BEQ: A == B
            3'b001: branch_taken = ~zero; // BNE: A != B
            
            3'b100: branch_taken = (negative ^ overflow); // BLT: A < B (singed)
            3'b101: branch_taken = ~(negative ^ overflow); // BGE: A >= B (signed)
            
            3'b110: branch_taken = ~carry; // BLTU: A < B (unsigned)
            3'b111: branch_taken = carry; // BGEU: A >= B (unsigned)
            
            default: branch_taken = 1'b0;
        endcase
    end

    always @(*) begin
        if (jump) begin
            pc_src = 1'b1; 
        end else if (branch) begin
            pc_src = branch_taken; 
        end else begin
            pc_src = 1'b0; 
        end
    end
    
endmodule