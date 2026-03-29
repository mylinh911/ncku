module reg_file(
    input clk,
    input reg_write,
    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd,
    input [31:0] wd,
    output [31:0] rd1,
    output [31:0] rd2
);

    reg [31:0] registers [31:0];

    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            registers[i] = 32'd0;
        end
    end

    assign rd1 = (rs1 != 0) ? registers[rs1] : 32'd0; 
    assign rd2 = (rs2 != 0) ? registers[rs2] : 32'd0; 

    always @(posedge clk) begin
        if (reg_write && (rd != 5'd0)) begin
            registers[rd] <= wd;
        end
    end
endmodule