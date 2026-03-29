`include "../src/pc.v"
`include "../src/pc_adder.v"
`include "../src/mux.v"
`include "../src/decoder.v"
`include "../src/reg_file.v"
`include "../src/imm_extend.v"
`include "../src/alu.v"
`include "../src/store_filter.v"
`include "../src/ld_filter.v"
`include "../src/jb_unit.v"
`include "../src/csr.v"
`include "../src/top_controller.v"

module top(
    input           clk,
    input           rst,
    // Instruction Memory Interface
    input           im_valid, 
    input  [31:0]   im_read_data,
    output          im_req,      
    output [31:0]   im_addr,
       
    // Data Memory Interface
    input           dm_valid,
    input  [31:0]   dm_read_data,     
    output          dm_req,  
    output          dm_WEB,       // 0: Write, 1: Read
    output [31:0]   dm_bit_en, //byte enable mask for writes (active low) 
    output [13:0]   dm_addr,    
    output [31:0]   dm_write_data 
);
// implement your CPU here

    assign im_req = 1'b1;

    reg [31:0] pc;
    wire [31:0] pc_next;
    wire [31:0] pc_plus_4;

    assign im_addr = pc;

    wire [31:0] instruction = im_read_data;

    wire zero;
    wire negative;
    wire overflow;
    wire carry;
    wire [3:0] alu_control;
    wire [2:0] imm_src;
    wire reg_write;
    wire alu_src_a_sel;
    wire alu_src_b_sel;
    wire mem_write;
    wire [1:0] result_src;
    wire csr_result;
    wire pc_src;
    wire mul_enable;
    wire [1:0] load_store_size;
    wire load_signed;

    wire cpu_enable = ((dm_req | mem_write) ? dm_valid : 1'b1) & im_valid;

    pc pc_reg(
        .clk(clk),
        .rst(rst),
        .enable(cpu_enable),
        .pc_next(pc_next),
        .pc(pc)
    );  

    pc_adder pc_adder(
        .pc(pc),
        .pc_plus_4(pc_plus_4)
    );  

    wire [31:0] jb_unit_result;

    mux_2to1 pc_mux(
        .in0(pc_plus_4),
        .in1(jb_unit_result),
        .sel(pc_src),
        .out(pc_next)
    );

    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [4:0] rd;
    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [6:0] funct7;

    decoder decoder_unit(
        .instruction(instruction),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7)
    );

    top_controller top_controller_unit(
        .funct7(funct7),
        .funct3(funct3),
        .opcode(opcode),
        .zero(zero),
        .negative(negative),
        .overflow(overflow),
        .carry(carry),
        .alu_control(alu_control),
        .imm_src(imm_src),
        .reg_write(reg_write),
        .alu_src_a(alu_src_a_sel),
        .alu_src_b(alu_src_b_sel),
        .mem_write(mem_write),
        .result_src(result_src),
        .csr_result(csr_result),
        .pc_src(pc_src),
        .mul_enable(mul_enable),
        .load_store_size(load_store_size),
        .load_signed(load_signed),
        .dm_request(dm_req)
    );

    assign dm_WEB = ~mem_write;

    wire [31:0] rd1;
    wire [31:0] rd2;

    wire actual_reg_write = reg_write & cpu_enable; 
    reg_file reg_file_unit(
        .clk(clk),
        .reg_write(actual_reg_write),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .wd(wd_result_including_csr_out),
        .rd1(rd1),
        .rd2(rd2)
    );

    wire [31:0] imm_ext;
    imm_extend imm_extend_unit(
        .instruction(instruction),
        .imm_src(imm_src),
        .imm_ext(imm_ext)
    );

    wire [31:0] alu_src_a;
    wire [31:0] alu_src_b;

    mux_2to1 alu_src_a_mux(
        .in0(pc),
        .in1(rd1),
        .sel(alu_src_a_sel),
        .out(alu_src_a)
    );

    mux_2to1 alu_src_b_mux(
        .in0(imm_ext),
        .in1(rd2),
        .sel(alu_src_b_sel),
        .out(alu_src_b)
    );

    wire [31:0] alu_result;

    alu alu_unit(
        .src_a(alu_src_a),
        .src_b(alu_src_b),
        .alu_control(alu_control),
        .mul_enable(mul_enable),
        .alu_result(alu_result),
        .zero(zero),
        .overflow(overflow),
        .negative(negative),
        .carry(carry)
    );

    jb_unit jb_unit(
        .src_a(alu_src_a),
        .src_b(imm_ext),
        .result(jb_unit_result)
    );

    store_filter store_filter_unit(
        .addr_lsb(alu_result[1:0]),        
        .store_size(load_store_size),      
        .rs2_data(rd2),         
        .dm_write_data(dm_write_data),   
        .dm_bit_en(dm_bit_en)        
    );

    assign dm_addr = alu_result[13:0];

    wire [31:0] filted_read_data;

    ld_filter ld_filter_unit(
        .read_data(dm_read_data),
        .addr_lsb(alu_result[1:0]),
        .load_size(load_store_size),
        .load_signed(load_signed),
        .filted_read_data(filted_read_data)
    );

    wire [31:0] result_out;

    mux_4to1 wd_result_mux(
        .in0(alu_result),
        .in1(filted_read_data),
        .in2(imm_ext),
        .in3(pc_plus_4),
        .sel(result_src),
        .out(result_out)
    );

    wire [63:0] num_ins;
    wire [63:0] num_cycle;
    wire [31:0] csr_out;

    csr csr_unit(
        .clk(clk),
        .rst(rst),
        .csr_addr(im_read_data[31:20]), 
        .inc_inst(cpu_enable),           
        .csr_out(csr_out)
    );

    wire [31:0] wd_result_including_csr_out;
    mux_2to1 wd_result_including_csr_mux(
        .in0(wd_result_mux),
        .in1(csr_out),
        .sel(csr_result),
        .out(wd_result_including_csr_out)  
    );


endmodule