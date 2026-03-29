module instruction_mem #(
    parameter ADDR_WIDTH = 10,
    parameter INIT_FILE = "instructions.hex"
)(
    input [31:0] addr,
    output [31:0] read_data
);

    localparam MEM_SIZE = 1 << ADDR_WIDTH;
    reg [31:0] mem [0:MEM_SIZE-1];

    assign read_data = mem[addr[ADDR_WIDTH+1:2]]; // word-aligned access

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