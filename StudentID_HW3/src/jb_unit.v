module jb_unit(
    input [31:0] src_a,
    input [31:0] src_b,
    output [31:0] result
);
    assign result = src_a + src_b;
endmodule