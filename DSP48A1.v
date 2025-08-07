module DSP48A1 (clk,A,B,D,BCIN,C,PCIN,CARRYIN,OPMODE,CEA, CEB, CEC, CED, CEM, CEP,CECARRYIN, CEOPMODE,
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
reg [17:0] A_reg, B_reg, D_reg, A0_reg, B0_reg, BIN;
reg [47:0] C_reg;
reg CARRYIN_reg,CARRY0,CARRYOUT_reg,CARRYOUT0;
reg [7:0] OPMODE_reg;
reg [35:0] M_reg;
reg [47:0] Z;
reg [47:0] X;
reg [47:0] P_reg;
wire [17:0] A0, B0, D0, A1, B1;
wire [47:0] C0;
wire [7:0] OPMODE0;
wire CIN;

reg [17:0] preadder_out;
wire [35:0] multiplier_out;
reg [47:0] postadder_out;

    // Pipeline stages and resets
generate
if (RSTTYPE == "ASYNC") begin //async reset
	always @(posedge clk or posedge RSTA) begin

	if (RSTA) begin
		A_reg <= 0;
		A0_reg <= 0;
	end
	else if (CEA) begin 
		A_reg <= A;
		A0_reg <= A0;
	end
	
	end

        always @(posedge clk or posedge RSTB) begin
	
	if (RSTB) begin
		B_reg <= 0;
		B0_reg <= 0;
	end
	else if (CEB) begin 
		B_reg <= BIN;
		B0_reg <= preadder_out;
	end

	end
        
	always @(posedge clk or posedge RSTCARRYIN) begin
	
	if (RSTCARRYIN)begin 
		CARRYIN_reg <= 0; 
		CARRYOUT_reg<=0;
	end
	else if (CECARRYIN) begin
		CARRYIN_reg <= CARRY0;
		CARRYOUT_reg<=CARRYOUT0;
	end
        
	end

        always @(posedge clk or posedge RSTD) begin
            if (RSTD) D_reg <= 0;
            else if (CED) D_reg <= D;
        end

        always @(posedge clk or posedge RSTOPMODE) begin
            if (RSTOPMODE) OPMODE_reg <= 0;
            else if (CEOPMODE) OPMODE_reg <= OPMODE;
        end

        always @(posedge clk or posedge RSTC) begin
            if (RSTC) C_reg <= 0;
            else if (CEC) C_reg <= C;
        end

        always @(posedge clk or posedge RSTM) begin
            if (RSTM) M_reg <= 0;
            else if (CEM) M_reg <= multiplier_out;
        end

        always @(posedge clk or posedge RSTP) begin
            if (RSTP) P_reg <= 0;
            else if (CEP) P_reg <= postadder_out;
        end


end 

else begin //sync reset
always @(posedge clk) begin
	//A
	if (RSTA) begin
		A_reg <= 0;
		A0_reg <= 0;
	end
	else if (CEA) begin 
		A_reg <= A;
		A0_reg <= A0;
	end
        
	//B
	if (RSTB) begin
		B_reg <= 0;
		B0_reg <= 0;
	end
	else if (CEB) begin 
		B_reg <= BIN;
		B0_reg <= preadder_out;
	end
	
	//CARRYIN and CARRYOUT
	if (RSTCARRYIN)begin 
		CARRYIN_reg <= 0; 
		CARRYOUT_reg<=0;
	end
	else if (CECARRYIN) begin
		CARRYIN_reg <= CARRY0;
		CARRYOUT_reg<=CARRYOUT0;
	end

	if (RSTD) D_reg <= 0; else if (CED) D_reg <= D;
	if (RSTOPMODE) OPMODE_reg <= 0; else if (CEOPMODE) OPMODE_reg <= OPMODE;
        if (RSTC) C_reg <= 0; else if (CEC) C_reg <= C;
        if (RSTM) M_reg <= 0; else if (CEM) M_reg <= multiplier_out;
        if (RSTP) P_reg <= 0; else if (CEP) P_reg <= postadder_out;
end

end
endgenerate

assign A0 = (A0REG)? A_reg : A;
assign A1 = (A1REG)? A0_reg : A0;
assign B0 = (B0REG)? B_reg : BIN;
assign B1 = (B1REG)? B0_reg : preadder_out;
assign C0 = (CREG)? C_reg : C;
assign D0 = (DREG)? D_reg : D;
assign CIN = (CARRYINREG)? CARRYIN_reg : CARRY0;
assign M = (MREG)? M_reg : multiplier_out;
assign P = (PREG)? P_reg : postadder_out;
assign OPMODE0 = (OPMODEREG)? OPMODE_reg : OPMODE;
assign CARRYOUT = (CARRYOUTREG)? CARRYOUT_reg : CARRYOUT0;

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