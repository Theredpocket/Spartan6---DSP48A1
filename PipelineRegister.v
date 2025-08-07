module PipelineRegister #(parameter WIDTH = 18,parameter DREG=1, parameter RSTTYPE = "SYNC") (
    input clk,
    input rst,
    input ce,
    input [WIDTH-1:0] d_in,
    output [WIDTH-1:0] d_out
);
reg [WIDTH-1:0] d_temp;
    generate
        if (RSTTYPE == "ASYNC") begin
            always @(posedge clk or posedge rst) begin
                if (rst) d_temp <= 0;
                else if (ce) d_temp <= d_in;
            end
        end 
	else begin // SYNC
            always @(posedge clk) begin
                if (rst) d_temp <= 0;
                else if (ce) d_temp <= d_in;
            end
        end 
    endgenerate

assign d_out = (DREG)? d_temp : d_in;
endmodule