module DSP48A1_tb;

parameter A0REG=0;parameter A1REG=1;
parameter B0REG=0;parameter B1REG=1;

parameter CREG=1;parameter DREG=1;
parameter MREG=1;parameter PREG=1;
parameter CARRYINREG=1;parameter CARRYOUTREG=1;
parameter OPMODEREG=1;
parameter CARRYINSEL = "OPMODE5";
parameter B_INPUT = "DIRECT";
parameter RSTTYPE = "SYNC";

reg clk;
reg [17:0] A, B, D, BCIN;
reg [47:0] C, PCIN;
reg CARRYIN;
reg [7:0] OPMODE;
reg CEA, CEB, CEC, CED, CEP;
reg CEM, CECARRYIN, CEOPMODE;
reg RSTA, RSTB, RSTC, RSTD, RSTM, RSTP;
reg RSTCARRYIN, RSTOPMODE;


wire [47:0] P, PCOUT;
wire [35:0] M;
wire CARRYOUT, CARRYOUTF;
wire [17:0] BCOUT;

reg [47:0]P_expected;

reg [17:0] stage1;
reg [35:0] stage2;


DSP2 uut (
        .clk(clk), .A(A), .B(B), .D(D), .BCIN(BCIN), .C(C), .PCIN(PCIN),
        .CARRYIN(CARRYIN), .OPMODE(OPMODE),
        .CEA(CEA), .CEB(CEB), .CEC(CEC), .CED(CED), .CEP(CEP),
        .CEM(CEM), .CECARRYIN(CECARRYIN), .CEOPMODE(CEOPMODE),
        .RSTA(RSTA), .RSTB(RSTB), .RSTC(RSTC), .RSTD(RSTD), .RSTM(RSTM), .RSTP(RSTP),
        .RSTCARRYIN(RSTCARRYIN), .RSTOPMODE(RSTOPMODE),
        .P(P), .PCOUT(PCOUT), .M(M), .CARRYOUT(CARRYOUT), .CARRYOUTF(CARRYOUTF), .BCOUT(BCOUT)
);

initial begin
clk=0;
forever
#1 clk=~clk;
end

initial begin

        A = 18'd10; B = 18'd5; D = 18'd3; BCIN = 18'd2;
        C = 48'd20; PCIN = 48'd15;CARRYIN = 1'b0;
        OPMODE = 8'b00000001;
        
        RSTA = 1; RSTB = 1; RSTC = 1; RSTD = 1; RSTM = 1; RSTP = 1;
        RSTCARRYIN = 1; RSTOPMODE = 1;


@(negedge clk); 
	RSTA = 0; RSTB = 0; RSTC = 0; RSTD = 0; RSTM = 0; RSTP = 0;
     	RSTCARRYIN = 0; RSTOPMODE = 0;
	CEA = 1; CEB = 1; CEC = 1; CED = 1; CEP = 1;
        CEM = 1; CECARRYIN = 1; CEOPMODE = 1;

        // Apply various test cases for the first OPMODE
        

	//some initial indicaters to show they were used
	PCIN = 48'hFFFF0000FFFF;BCIN = 18'd5;
	
	OPMODE = 8'b00000000; //p=0
		repeat(5)begin
		A=$random & 18'h0FFFF;B=$random & 18'h0FFFF;D=$random & 18'h0FFFF;//avoiding overflow (preadder not optimized)
		C=$random & 48'h0FFFFFFFFFFF;CARRYIN=$random;

		P_expected=0;	
		
		@(negedge clk);@(negedge clk);@(negedge clk);@(negedge clk);//5clock cycles		
		
		end
	
	OPMODE = 8'b00000001; //p=M
		repeat(5)begin
		A=$random & 18'h0FFFF;B=$random & 18'h0FFFF;D=$random & 18'h0FFFF;
		C=$random & 48'h0FFFFFFFFFFF;CARRYIN=$random;
		stage1= B;
		stage2= stage1*A;
		P_expected=stage2;			
		
		@(negedge clk);@(negedge clk);@(negedge clk);@(negedge clk);//5clock cycles
		
		end
	
	OPMODE = 8'b00000010;CARRYIN=0; //p=old p
		repeat(5)begin
		A=$random & 18'h0FFFF;B=$random & 18'h0FFFF;D=$random & 18'h0FFFF;
		C=$random & 48'h0FFFFFFFFFFF;			
		
		@(negedge clk);@(negedge clk);@(negedge clk);@(negedge clk);//5clock cycles
		
		end
	
	OPMODE = 8'b00000011;//p=concatenated
		repeat(5)begin
		A=$random & 18'h0FFFF;B=$random & 18'h0FFFF;D=$random & 18'h0FFFF;
		C=$random & 48'h0FFFFFFFFFFF;CARRYIN=$random;

		P_expected={D[11:0], A, B};			
		
		@(negedge clk);@(negedge clk);@(negedge clk);@(negedge clk);//5clock cycles		
		
		end
	
	OPMODE = 8'b00000111;//concatenated+pcin
		repeat(5)begin
		A=$random & 18'h0FFFF;B=$random & 18'h0FFFF;D=$random & 18'h0FFFF;
		C=$random & 48'h0FFFFFFFFFFF;CARRYIN=$random;

		P_expected={D[11:0], A, B}+PCIN;			
		
		@(negedge clk);@(negedge clk);@(negedge clk);@(negedge clk);//5clock cycles	
		
		end
	
	CARRYIN=0;//no longer randomizing carry
	OPMODE = 8'b00001101;//M+C
		repeat(5)begin
		A=$random & 18'h0FFFF;B=$random & 18'h0FFFF;D=$random & 18'h0FFFF;
		C=$random & 48'h0FFFFFFFFFFF;
		stage1= B;
		stage2= stage1*A;
		P_expected=stage2+C;			
		
		@(negedge clk);@(negedge clk);@(negedge clk);@(negedge clk);//5clock cycles		
		
		end	
	
	OPMODE = 8'b00011101;//((B+D)*A)+C
		repeat(5)begin
		A=$random & 18'h0FFFF;B=$random & 18'h0FFFF;D=$random & 18'h0FFFF;
		C=$random & 48'h0FFFFFFFFFFF;
		stage1= B+D;
		stage2= stage1*A;
		P_expected=stage2+C;			
		
		@(negedge clk);@(negedge clk);@(negedge clk);@(negedge clk);//5clock cycles		
		
		end
	
	OPMODE = 8'b01010101;//PCIN+((D-B)*A)
		repeat(5)begin
		A=$random & 18'h0FFFF;B=$random & 18'h0FFFF;D=$random & 18'h0FFFF;
		C=$random & 48'h0FFFFFFFFFFF;
		stage1= D-B;
		stage2= stage1*A;
		P_expected=PCIN+stage2;			
		
		@(negedge clk);@(negedge clk);@(negedge clk);@(negedge clk);//5clock cycles

		end
	
	OPMODE = 8'b11010101;//PCIN-((D-B)*A)
		repeat(5)begin
		A=$random & 18'h0FFFF;B=$random & 18'h0FFFF;D=$random & 18'h0FFFF;
		C=$random & 48'h0FFFFFFFFFFF;

		stage1= D-B;
		stage2= stage1*A;
		P_expected=PCIN-stage2;			
		
		@(negedge clk);@(negedge clk);@(negedge clk);@(negedge clk);//5clock cycles
		
		end

	OPMODE = 8'b10101101;//C-((B*A)+1)
		repeat(5)begin
		A=$random & 18'h0FFFF;B=$random & 18'h0FFFF;D=$random & 18'h0FFFF;
		C=$random & 48'h0FFFFFFFFFFF;

		stage1= B;
		stage2= stage1*A;
		P_expected=(C)-(stage2+1);			
		
		@(negedge clk);@(negedge clk);@(negedge clk);@(negedge clk);//5clock cycles

		end
	
	OPMODE = 8'b00100000;//1 testing (opmode[5])
		repeat(5)begin
		A=$random & 18'h0FFFF;B=$random & 18'h0FFFF;D=$random & 18'h0FFFF;
		C=$random & 48'h0FFFFFFFFFFF;

		P_expected=1;			
		
		@(negedge clk);@(negedge clk);@(negedge clk);@(negedge clk);//5clock cycles

		end


        #50 $stop;

    end
endmodule
