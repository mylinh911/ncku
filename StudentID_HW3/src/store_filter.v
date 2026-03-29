module store_filter(
    input  wire [1:0]  addr_lsb,        
    input  wire [1:0]  store_size,      
    input  wire [31:0] rs2_data,         
    output reg  [31:0] dm_write_data,   
    output reg  [31:0] dm_bit_en        
);

    always @(*) begin
        dm_bit_en     = 32'hFFFF_FFFF;
        dm_write_data = 32'd0;

        case (store_size)
            2'b00: begin //byte
                dm_write_data = {4{rs2_data[7:0]}}; 
                case (addr_lsb)
                    2'b00: dm_bit_en = 32'hFFFF_FF00; 
                    2'b01: dm_bit_en = 32'hFFFF_00FF; 
                    2'b10: dm_bit_en = 32'hFF00_FFFF; 
                    2'b11: dm_bit_en = 32'h00FF_FFFF; 
                endcase
            end
            
            2'b01: begin // halfword
                dm_write_data = {2{rs2_data[15:0]}};
                if (addr_lsb[1] == 1'b0)
                    dm_bit_en = 32'hFFFF_0000; 
                else
                    dm_bit_en = 32'h0000_FFFF; 
            end
            
            2'b10: begin // word
                dm_write_data = rs2_data;
                dm_bit_en     = 32'h0000_0000; 
            end
            
            default: ; 
        endcase
    end
endmodule