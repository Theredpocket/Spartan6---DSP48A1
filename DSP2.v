module DSP2 (clk,A,B,D,BCIN,C,PCIN,CARRYIN,OPMODE,CEA, CEB, CEC, CED, CEM, CEP,CECARRYIN, CEOPMODE,
RSTA,RSTB,RSTC,RSTD,RSTM,RSTP,RSTCARRYIN, RSTOPMODE,P,PCOUT,M,CARRYOUT, CARRYOUTF,BCOUT);

parameter A0REG=0;parameter A1REG=1;
parameter B0REG=0;parameter B1REG=1;

parameter CREG=1;parameter DREG=1;
parameter MREG=1;parameter PREG=1;
parameter CARRYINREG=1;parameter CARRYOUTREG=1;
parameter OPMODEREG=1;
parameter CARRYINSEL = "OPMODE5";
parameter B_INPUT = "DIRECT";
parameter RSTTYPE = "SYNC";

input clk;
input [17:0] A, B, D, BCIN;
input [47:0] C, PCIN;
input CARRYIN;
input [7:0] OPMODE;
input CEA, CEB, CEC, CED, CEP; //clock enable input ports
input CEM, CECARRYIN, CEOPMODE; //clock enable for multiplier,carryin,opmode
input RSTA, RSTB, RSTC, RSTD, RSTM, RSTP; //reset input ports
input RSTCARRYIN, RSTOPMODE;
output [47:0] P, PCOUT;
output [35:0] M;
output CARRYOUT, CARRYOUTF;
output [17:0] BCOUT;

    // Internal registers
reg CARRY0,CARRYOUT0;
reg [47:0] Z;
reg [47:0] X;
reg [17:0] BIN;
wire [17:0] A0, B0, D0, A1, B1;
wire [47:0] C0;
wire [7:0] OPMODE0;
wire CIN;

reg [17:0] preadder_out;
wire [35:0] multiplier_out;
reg [47:0] postadder_out;


// Pipeline stage instances
PipelineRegister #(18, A0REG, RSTTYPE) A_stage0 (.clk(clk), .rst(RSTA), .ce(CEA), .d_in(A), .d_out(A0));
PipelineRegister #(18, A1REG, RSTTYPE) A_stage1 (.clk(clk), .rst(RSTA), .ce(CEA), .d_in(A0), .d_out(A1));

PipelineRegister #(18, B0REG, RSTTYPE) B_stage0 (.clk(clk), .rst(RSTB), .ce(CEB), .d_in(BIN), .d_out(B0));
PipelineRegister #(18, B1REG, RSTTYPE) B_stage1 (.clk(clk), .rst(RSTB), .ce(CEB), .d_in(preadder_out), .d_out(B1));

PipelineRegister #(48, CREG, RSTTYPE) C_stage (.clk(clk), .rst(RSTC), .ce(CEC), .d_in(C), .d_out(C0));
PipelineRegister #(18, DREG, RSTTYPE) D_stage (.clk(clk), .rst(RSTD), .ce(CED), .d_in(D), .d_out(D0));
PipelineRegister #(8,OPMODEREG,  RSTTYPE) OPMODE_stage (.clk(clk), .rst(RSTOPMODE), .ce(CEOPMODE), .d_in(OPMODE), .d_out(OPMODE0));
PipelineRegister #(1,CARRYINREG,  RSTTYPE) CARRYIN_stage (.clk(clk), .rst(RSTCARRYIN), .ce(CECARRYIN), .d_in(CARRY0), .d_out(CIN));
PipelineRegister #(36,MREG,  RSTTYPE) M_stage (.clk(clk), .rst(RSTM), .ce(CEM), .d_in(multiplier_out), .d_out(M));
PipelineRegister #(48,PREG,  RSTTYPE) P_stage (.clk(clk), .rst(RSTP), .ce(CEP), .d_in(postadder_out), .d_out(P));
PipelineRegister #(1, CARRYINREG,  RSTTYPE) CARRYOUT_stage (.clk(clk), .rst(RSTCARRYIN),.ce(CECARRYIN), .d_in(CARRYOUT0), .d_out(CARRYOUT));

// Arithmetic operations
always @(*) begin
	case (OPMODE0[4])
            1'b0: preadder_out = B0;
            1'b1: 
		if(OPMODE0[6]) preadder_out = D0 - B0;
		else preadder_out = D0 + B0;
        endcase

        case (OPMODE0[1:0])
            	2'b00: X = 48'b0;
            	2'b01: X = {12'b0,M};
            	2'b10: X = P;
            	2'b11: X = {D0[11:0], A1, B1};
        endcase

	case (OPMODE0[3:2])
		2'b00: Z = 48'b0;
        	2'b01: Z = PCIN;
        	2'b10: Z = P;
        	2'b11: Z = C0;
    	endcase
	
	case (OPMODE0[7])
        	1'b0: {CARRYOUT0,postadder_out} = Z + (X + CIN);
        	1'b1: {CARRYOUT0,postadder_out} = Z - (X + CIN);
    	endcase
	
	if (CARRYINSEL == "OPMODE5")CARRY0 = OPMODE0[5];
	else if (CARRYINSEL == "CARRYIN")CARRY0 = CARRYIN; 
	else CARRY0 = 1'b0; // Default case
	
    	if (B_INPUT == "DIRECT")BIN = B;
    	else if (B_INPUT == "CASCADE")BIN = BCIN;
    	else BIN = 18'b0; // Default case	
	
end

// Multiplier logic
assign multiplier_out = B1 * A1;


assign CARRYOUTF = CARRYOUT;
assign BCOUT = B1;
assign PCOUT = P;

endmodule
