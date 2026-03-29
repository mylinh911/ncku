`timescale 1ns/10ps
`define CYCLE 10.0  
`define MAX 500000 
`ifdef SYN
`include "top_syn.v"
`timescale 1ns/10ps
`include "../sim/tsmc13_neg.v"
`else
`include "top.v"
`endif
`timescale 1ns/10ps
`define SIM_END 'h3fff
`define SIM_END_CODE -32'd1
`define TEST_START 'h2000
`include "sim_pkg.sv"
import sim_pkg::*;
module tb;

  //================================================================
  // Testbench Signals and Variables
  //================================================================
  logic clk;
  logic rst;
  
  // Golden data and file handling
  logic [31:0] GOLDEN[64];
  integer      gf, i, num_golden, a, b;
  integer      err_count;
  string       prog_path;
  string rdcycle;
  // Program loading helpers
  logic [7:0]  Memory_byte0[16383:0], Memory_byte1[16383:0], Memory_byte2[16383:0], Memory_byte3[16383:0];
  logic [31:0] Memory_word[16383:0];

  //================================================================
  // CPU <-> Testbench Interface
  //================================================================
  // To CPU (driven by TB memory model)
  logic [31:0] im_read_data;
  logic [31:0] dm_read_data;
  logic        im_valid;
  logic        dm_valid;

  // From CPU (requests to TB memory model)
  wire        im_req;
  wire [13:0] im_addr;
  wire        dm_req;
  wire        dm_WEB; // 0=Write, 1=Read
  wire [13:0] dm_addr;
  wire [31:0] dm_write_data;
  wire [31:0] dm_bit_en;

  //================================================================
  // DUT (CPU) Instantiation
  //================================================================
  top DUT (
      .clk(clk),
      .rst(rst),
      .im_req(im_req),
      .im_addr(im_addr),
      .im_read_data(im_read_data),
      .im_valid(im_valid),
      .dm_req(dm_req),
      .dm_WEB(dm_WEB),
      .dm_bit_en(dm_bit_en),
      .dm_addr(dm_addr),
      .dm_write_data(dm_write_data),
      .dm_read_data(dm_read_data),
      .dm_valid(dm_valid)
  );

  //================================================================
  // Clock and Reset Generation
  //================================================================
  always #(`CYCLE/2) clk = ~clk;

  //================================================================
  // Testbench-Internal Memory Models with Delay
  //================================================================
  localparam IM_WORDS = 16384;
  localparam DM_WORDS = 16384;
  logic [31:0] im_mem [0:IM_WORDS-1];
  logic [31:0] dm_mem [0:DM_WORDS-1];

  // --- Instruction Memory Model ---
  reg im_busy;
  reg [3:0] im_delay_counter;
  reg [13:0] captured_im_addr;
  reg [3:0] im_pattern_idx;
  
  always @(posedge clk or posedge rst) begin
      if (rst) begin
          im_busy <= 1'b0;
          im_valid <= 1'b0;
          im_delay_counter <= 4'd0;
          im_pattern_idx <= 4'd0;
      end else begin
          im_valid <= 1'b0;

          if (!im_busy) begin
            im_read_data <= 32'd0;
              if (im_req) begin
                  im_busy <= 1'b1;
                  captured_im_addr <= im_addr;
                  im_pattern_idx <= im_pattern_idx + 1;
                  
                  case(im_pattern_idx)
                      4'h0: im_delay_counter <= 6;
                      4'h1: im_delay_counter <= 8;
                      4'h2: im_delay_counter <= 7;
                      4'h3: im_delay_counter <= 11;
                      4'h4: im_delay_counter <= 9;
                      4'h5: im_delay_counter <= 12;
                      4'h6: im_delay_counter <= 6;
                      4'h7: im_delay_counter <= 10;
                      4'h8: im_delay_counter <= 8;
                      4'h9: im_delay_counter <= 7;
                      4'hA: im_delay_counter <= 9;
                      4'hB: im_delay_counter <= 11;
                      4'hC: im_delay_counter <= 6;
                      4'hD: im_delay_counter <= 10;
                      4'hE: im_delay_counter <= 8;
                      4'hF: im_delay_counter <= 9;
                  endcase
              end
          end 
          else begin
              if (im_delay_counter > 1) begin
                  im_delay_counter <= im_delay_counter - 1;
                  im_read_data <= 32'd0;
              end else begin
                  im_busy <= 1'b0;
                  im_valid <= 1'b1;
                  im_read_data <= im_mem[captured_im_addr];
              end
          end
      end
  end

  // --- Data Memory Model ---
  reg dm_busy;
  reg [3:0] dm_delay_counter;
  reg [13:0] captured_dm_addr;
  reg [31:0] captured_dm_wdata;
  reg [31:0] captured_dm_bit_en;
  reg captured_dm_WEB;
  reg [3:0] dm_pattern_idx;
  
  always @(posedge clk or posedge rst) begin
      if (rst) begin
          dm_busy <= 1'b0;
          dm_valid <= 1'b0;
          dm_delay_counter <= 4'd0;
          dm_pattern_idx <= 4'd0;
      end else begin
          dm_valid <= 1'b0;

          if (!dm_busy) begin
              if (dm_req && !dm_valid) begin
                  dm_busy <= 1'b1;
                  captured_dm_addr <= dm_addr;
                  captured_dm_WEB <= dm_WEB;
                  captured_dm_wdata <= dm_write_data;
                  captured_dm_bit_en <= dm_bit_en;
                  dm_pattern_idx <= dm_pattern_idx + 1;

                  case(dm_pattern_idx)
                      4'h0: dm_delay_counter <= 7;
                      4'h1: dm_delay_counter <= 9;
                      4'h2: dm_delay_counter <= 11;
                      4'h3: dm_delay_counter <= 8;
                      4'h4: dm_delay_counter <= 10;
                      4'h5: dm_delay_counter <= 7;
                      4'h6: dm_delay_counter <= 9;
                      4'h7: dm_delay_counter <= 8;
                      4'h8: dm_delay_counter <= 11;
                      4'h9: dm_delay_counter <= 7;
                      4'hA: dm_delay_counter <= 10;
                      4'hB: dm_delay_counter <= 8;
                      default: dm_delay_counter <= 9;
                  endcase
              end
          end else begin
              if (dm_delay_counter > 1) begin
                  dm_delay_counter <= dm_delay_counter - 1;
                  captured_dm_addr <= dm_addr;
              end 
              else begin
                  dm_busy <= 1'b0;
                  dm_valid <= 1'b1;
                  captured_dm_addr <= dm_addr;
                  captured_dm_WEB <= dm_WEB;
                  captured_dm_wdata <= dm_write_data;
                  captured_dm_bit_en <= dm_bit_en;
                  if (captured_dm_WEB == 0) begin
                      if (!captured_dm_bit_en[0]) dm_mem[captured_dm_addr][7:0]   <= captured_dm_wdata[7:0];
                      if (!captured_dm_bit_en[8]) dm_mem[captured_dm_addr][15:8]  <= captured_dm_wdata[15:8];
                      if (!captured_dm_bit_en[16]) dm_mem[captured_dm_addr][23:16] <= captured_dm_wdata[23:16];
                      if (!captured_dm_bit_en[24]) dm_mem[captured_dm_addr][31:24] <= captured_dm_wdata[31:24];
                  end 
                  else begin 
                      dm_read_data <= dm_mem[captured_dm_addr];
                  end
              end
          end
      end
  end

  //================================================================
  // Main Simulation and Verification Flow
  //================================================================
  initial begin
    $value$plusargs("prog_path=%s", prog_path);
    $value$plusargs("rdcycle=%s", rdcycle);
    clk = 0; rst = 1;
    #(`CYCLE*2) rst = 0;

    $readmemh({prog_path, "/main0.hex"}, Memory_byte0);
    $readmemh({prog_path, "/main1.hex"}, Memory_byte1); 
    $readmemh({prog_path, "/main2.hex"}, Memory_byte2);
    $readmemh({prog_path, "/main3.hex"}, Memory_byte3); 
    
    for(a = 0; a < IM_WORDS; a = a + 1) begin
      Memory_word[a] = {Memory_byte3[a], Memory_byte2[a], Memory_byte1[a], Memory_byte0[a]};
      im_mem[a] = Memory_word[a];
      dm_mem[a] = Memory_word[a];
    end

    num_golden = 0;
    gf = $fopen({prog_path, "/golden.hex"}, "r");
    while ($fscanf(gf, "%h\n", GOLDEN[num_golden]) == 1) begin
      num_golden++;
    end
    $fclose(gf);

    wait(dm_mem[`SIM_END] == `SIM_END_CODE);
    
    $display("\nDone\n");
    err_count = 0;

    for (i = 0; i < num_golden; i++) begin
      if (dm_mem[`TEST_START + i] !== GOLDEN[i]) begin
        err_count = err_count + 1;
      end
      else
      begin
        
      end
    end
    show_lab_title();
    show_report();
    result(err_count, num_golden);
    for (i = 0; i < num_golden; i++) begin
      if (dm_mem[`TEST_START + i] !== GOLDEN[i]) begin
        $display("DM[0x%h] = %h, expect = %h", `TEST_START + i, dm_mem[`TEST_START + i], GOLDEN[i]);
      end
      else
      begin
        $display("DM[0x%h] = %h, pass", `TEST_START + i, dm_mem[`TEST_START + i]);
      end
    end
    if (rdcycle == "1") begin
      $display("your total cycle is %f ",dm_mem[`TEST_START + num_golden]);
      $display("your total cycle is %f ",dm_mem[`TEST_START + num_golden+1]);
    end
    $display("\n");
    if(err_count == 0) begin
      show_result(0);
    end
    else begin
      show_result(1);
    end
    $finish;
  end

  initial begin
    `ifdef FSDB
    $fsdbDumpfile("top.fsdb");
    $fsdbDumpvars(0, tb);
    `elsif FSDB_ALL
    $fsdbDumpfile("top.fsdb");
    $fsdbDumpvars("+struct", "+mda", tb);
    `endif
    #(`CYCLE * `MAX);
    show_lab_title();
    show_report();
    for (i = 0; i < num_golden; i++) begin
      if (dm_mem[`TEST_START + i] !== GOLDEN[i]) begin
        $display("DM[0x%h] = %h, expect = %h", `TEST_START + i, dm_mem[`TEST_START + i], GOLDEN[i]);
      end
      else
      begin
        $display("DM[0x%h] = %h, pass", `TEST_START + i, dm_mem[`TEST_START + i]);
      end
    end
    $display("\n");
    show_result(2);
    $display("SIMULATION TIMEOUT after %d cycles", `MAX);
    $finish;
  end

    task result;
    input integer err;
    input integer num;
    integer rf;
    begin
      `ifdef SYN
			rf = $fopen({prog_path, "/result_syn.txt"}, "w");
      `else
			rf = $fopen({prog_path, "/result_rtl.txt"}, "w");
      `endif
      $fdisplay(rf, "%d,%d", num - err, num);
      if (err === 0)
      begin
        $display("\n");
      end
      else
      begin
        $display("\n");
      end
    end
  endtask

endmodule