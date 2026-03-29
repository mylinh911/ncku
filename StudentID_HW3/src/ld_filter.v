module ld_filter(
    input [31:0] read_data,
    input [1:0]  addr_lsb,
    input [1:0]  load_size,
    input load_signed,
    output reg  [31:0] filted_read_data
);
    wire [7:0]  target_byte;
    wire [15:0] target_half;

    assign target_half = addr_lsb[1] ? read_data[31:16] : read_data[15:0];
    assign target_byte = (addr_lsb == 2'b00) ? read_data[7:0]   :
                         (addr_lsb == 2'b01) ? read_data[15:8]  :
                         (addr_lsb == 2'b10) ? read_data[23:16] : read_data[31:24];

    always @(*) begin
        case (load_size)
            2'b00: filted_read_data = ~load_signed ? {24'd0, target_byte} : { {24{target_byte[7]}}, target_byte }; //byte
            
            2'b01: filted_read_data = ~load_signed ? {16'd0, target_half} : { {16{target_half[15]}}, target_half }; //halfword
            
            2'b10: filted_read_data = read_data; //word
            
            default: filted_read_data = 32'bx;
        endcase
    end 
endmodule