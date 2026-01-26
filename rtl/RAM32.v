/// sta-blackbox
`timescale 1ns/1ps 
`default_nettype none

module RAM32(
`ifdef USE_POWER_PINS
  input wire VPWR,
  input wire VGND,
`endif
  input wire CLK,
  input wire [3:0] WE0,
  input wire EN0,
  input wire [4:0] A0,
  input wire [31:0] Di0,
  output reg [31:0] Do0
);
    reg [31:0] RAM[31:0];
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            RAM[i] = 32'h00000000;
        end
    end
    always @(posedge CLK)
        if(EN0) begin
            Do0 <= RAM[A0];
            if(WE0[0]) RAM[A0][ 7: 0] <= Di0[7:0];
            if(WE0[1]) RAM[A0][15:8] <= Di0[15:8];
            if(WE0[2]) RAM[A0][23:16] <= Di0[23:16];
            if(WE0[3]) RAM[A0][31:24] <= Di0[31:24];
        end
        else
            Do0 <= 32'b0;

endmodule