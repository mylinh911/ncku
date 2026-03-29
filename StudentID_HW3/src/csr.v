module csr(
    input clk,
    input rst,
    input [11:0] csr_addr,
    input inc_inst,
    output reg [31:0] csr_out
);
    reg [63:0] num_ins;
    reg [63:0] num_cycles,

    always @(posedge clk) begin
        if (rst) 
            num_ins <= 64'd0;
            num_cycles <= 64'd0;
        else begin
            if (inc_inst) begin
                num_ins <= num_ins + 1;
            end
            num_cycles <= num_cycles + 1;
        end
    end

    always @(*) begin
        case (csr_addr)
            12'hC00: csr_out = num_cycles[31:0]; // cycle
            12'hC80: csr_out = num_cycles[63:32]; // cycleh
            12'hC02: csr_out = num_ins[31:0]; // instret
            12'hC82: csr_out = num_ins[63:32]; // instreth
            default: csr_out = 32'd0;             
        endcase
    end
endmodule