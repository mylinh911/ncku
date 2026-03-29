module mem_op_controller(
    input [2:0] funct3,
    output [1:0] load_store_size,
    output load_signed
);
    //load_store_size: 00-byte, 01-halfword, 10-word
    assign load_store_size = funct3[1:0];
    assign load_signed = ~funct3[2];
    
endmodule