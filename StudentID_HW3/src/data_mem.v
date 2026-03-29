module data_mem #(
    parameter ADDR_WIDTH = 10,
    parameter INIT_FILE = "data.hex"
)(
    input clk
    input [31:0] addr,
    input [31:0] write_data,
    input write_enable,
    input [1:0] mem_size, //00: word, 01: halfword, 10: byte
    output [31:0] read_data
);

    localparam MEM_SIZE = 1 << ADDR_WIDTH;
    reg [31:0] mem [0:MEM_SIZE-1];
    wire [ADDR_WIDTH-1:0] word_addr = addr[ADDR_WID]

    assign read_data = mem[addr[ADDR_WIDTH+1:2]]; // word-aligned access
    
    always @(posedge clk) begin
        if (write_enable) begin
            case (mem_size) 
                2'b00: begin //byte
                    case (addr[1:0])
                        2'b00: mem[word_addr][7:0] <= write_data[7:0];
                        2'b01: mem[word_add][15:8] <= write_data[7:0];
                        2'b10: mem[word_addr][23:16] <= write_data[7:0];
                        2'b11: mem[word_addr][31:24] <= write_data [7:0];
                    endcase
                end
                2'b01: begin //halfword
                    if (addr[1] == 1'b0)
                        mem[word_addr][15:0] <= write_data[15:0];
                    else
                        mem[word_addr][31:16] <= write_data[15:0];
                end
                2'b10: mem[word_addr] <= write_data[31:0];  //word
                default: ;
            endcase
        end
    end

    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem);
        end else begin
            integer i;
            for (i = 0; i < MEM_SIZE; i = i + 1) begin
                mem[i] = 32'b0;
            end
        end
    end
endmodule