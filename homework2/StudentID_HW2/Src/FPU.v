`include "../Src/FPU_comparator.v"
`include "../Src/FPU_adder.v"
module FPU(
    input clk,
    input rst,
    input enable,
    input [1:0] instruction,
    input [31:0] ai,
    input [31:0] bi,
    output reg [31:0] co,
    output reg valid
);

    wire [31:0] adder_result;
    wire adder_valid;
    wire [31:0] comparator_result;
    //put ur design here

    FPU_adder adder(
        .input_a(ai),
        .input_b(bi),
        .enable(enable),
        .sub(instruction[0]),
        .clk(clk),
        .rst(rst),
        .output_c(adder_result),
        .output_c_ready(adder_valid)
    );

    FPU_comparator comparator(
        .A(ai),
        .B(bi),
        .mode(instruction[0]), 
        .answer(comparator_result)       
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            co <= 32'b0;
            valid <= 1'b1;
        end
        else begin
            if (enable) begin
                if (instruction[1]) begin
                    co <= adder_result;
                    valid <= adder_valid;
                end
                else begin 
                    co <= comparator_result;
                    valid <= 1'b1;
                end
            end
            else begin
                co <= co;
                valid <= valid;
            end
        end
    end


endmodule
