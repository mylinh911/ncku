module top_controller(
    input [6:0] funct7,
    input [2:0] funct3,
    input [6:0] opcode,
    input zero,
    input negative,
    input overflow,
    input carry,
    output [3:0] alu_control,
    output [2:0] imm_src,
    output reg_write,
    output alu_src_a,
    output alu_src_b,
    output mem_write,
    output [1:0] result_src,
    output csr_result,
    output pc_src,
    output mul_enable,
    output [1:0] load_store_size,
    output load_signed,
    output dm_request
);
    wire [1:0] alu_op;
    wire branch;
    wire jump;

    main_controller main_controller_unit(
        .opcode(opcode),
        .alu_op(alu_op),
        .imm_src(imm_src),
        .reg_write(reg_write),
        .alu_src_a(alu_src_a),
        .alu_src_b(alu_src_b),
        .mem_write(mem_write),
        .result_src(result_src),
        .csr_result(csr_result),
        .branch(branch),
        .jump(jump)
        .dm_request(dm_request)
    );

    alu_controller alu_controller_unit(
        .funct3(funct3),
        .funct7_5(funct7[5]),
        .funct7_0(funct7[0]),
        .op_5(opcode[5]),
        .alu_op(alu_op),
        .alu_control(alu_control),
        .mul_enable(mul_enable)
    );

    mem_op_controller mem_op_controller_unit(
        .funct3(funct3),
        .load_store_size(load_store_size),
        .load_signed(load_signed)
    );

    pc_controller pc_controller_unit(
        .zero(zero),
        .overflow(overflow),
        .negative(negative), 
        .carry(carry), 
        .funct3(funct3),
        .branch(branch),
        .jump(jump),
        .pc_src(pc_src)
    );

endmodule