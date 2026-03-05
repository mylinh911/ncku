`timescale 1ns/10ps
`define patternNum 75
`define PatternPATH "./pattern/"

`include "ALU.v"



module tb_ALU;

localparam INT_WIDTH    = 12;
localparam FRAC_WIDTH   = 20;
localparam DATA_WIDTH   = INT_WIDTH + FRAC_WIDTH;
localparam ALU_FUNCT3_WIDTH = 3; 
localparam ALU_FUNCT7_WIDTH = 7; 

reg   [ALU_FUNCT3_WIDTH-1:0]   funct3;
reg   [ALU_FUNCT7_WIDTH-1:0]   funct7;
reg   [DATA_WIDTH-1:0  ]   src_A_i;
reg   [DATA_WIDTH-1:0  ]   src_B_i;
wire  [DATA_WIDTH-1:0  ]   result_o;

logic [ALU_FUNCT3_WIDTH+ALU_FUNCT7_WIDTH+DATA_WIDTH*2-1:0]   ALU_inputData  [`patternNum-1:0];
logic [DATA_WIDTH-1:0]       ALU_outputData [`patternNum-1:0];


string inst_str;
logic [DATA_WIDTH-1:0]  golden;

int error[14];
int score[14] = {5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5};
int total_score = 0;

ALU ALU (
    .funct3  (funct3 ),
    .funct7  (funct7 ),
    .src_A_i (src_A_i),
    .src_B_i (src_B_i),
    .result_o(result_o)
);

initial begin
  src_A_i    = 32'd0;
  src_B_i    = 32'd0;
  funct3     = 3'd0;
  funct7     = 7'd0;
  golden     = 32'd0;
  
  // check instruction 0~13
  for(int inst=0;inst<14;inst++)begin
    inst_str.itoa(inst);
    $readmemb({`PatternPATH, "Inst", inst_str, "_i.dat"}, ALU_inputData );
    $readmemb({`PatternPATH, "Inst", inst_str, "_o.dat"}, ALU_outputData);
    for(int patIdx=0;patIdx<`patternNum;patIdx++)begin
      {funct7, src_B_i, src_A_i, funct3} = ALU_inputData[patIdx];
      golden = ALU_outputData[patIdx];
      #10;
      // check ALU result data
      if($isunknown(result_o))begin
        $display(" ============ Unknown value occurs at your result_o, simulation stop ============");
        $finish;
      end
      else begin
        if(result_o !== golden)begin
          error[inst] += 1;
          if(error[inst] > 0)$display("time = %0t ps ,Inst %2d pattern t%2d Error, your data_o = %b, expect data_o = %b" ,$time, inst, patIdx+1, result_o, golden);
        end
      end
    end
    if(error[inst] === 0)$display("Instruction %2d ALL PASS !!!", inst);
  end

  if(error[0] == 0 && error[1] == 0 && error[2] == 0 && error[3] == 0 && error[4] == 0 && error[5] == 0 && error[6] == 0 && error[7] == 0 && error[8] == 0 && error[9] == 0 && error[10] == 0 && error[11] == 0 && error[12] == 0 && error[13] == 0)begin
    $display("\n");
    $display(" ****************************               ");
    $display(" **                        **       |\__||  ");
    $display(" **  Congratulations !!    **      / O.O  | ");
    $display(" **                        **    /_____   | ");
    $display(" **  Simulation PASS!!     **   /^ ^ ^ \\  |");
    $display(" **                        **  |^ ^ ^ ^ |w| ");
    $display(" ****************************   \\m___m__|_|");
  end
  else begin
    $display("\n");
    $display(" ****************************               ");
    $display(" **                        **       |\__||  ");
    $display(" **  OOPS!!                **      / X,X  | ");
    $display(" **                        **    /_____   | ");
    $display(" **  Simulation Failed!!   **   /^ ^ ^ \\  |");
    $display(" **                        **  |^ ^ ^ ^ |w| ");
    $display(" ****************************   \\m___m__|_|");
  end
  
  for(int i=0;i<14;i++)begin
    if(error[i] === 0)total_score += score[i];
  end
  $display("\n====== Your score : %2d / 70 ======\n", total_score);
  $finish;
end

initial begin
	`ifdef FSDB
		$dumpfile("ALU.fsdb");
		$dumpvars(0, tb_ALU);
	`endif
end

endmodule
