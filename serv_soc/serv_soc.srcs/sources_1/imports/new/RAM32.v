`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.01.2026 11:46:49
// Design Name: 
// Module Name: RAM32
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


/// sta-blackbox

module RAM32(
`ifdef USE_POWER_PINS
  input VPWR,
  input VGND,
`endif
  input wire CLK,
  input wire WE0,
  input wire RE0,
  input wire [4:0] RA0,
  input wire [4:0] WA0,

  input wire [31:0] Di0,
  output reg [31:0] Do0
);
    reg [31:0] RAM[31:0];

// Standard Verilog integer for the loop index
    integer i;

    // This block runs once at the very start of simulation
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            RAM[i] = 32'h00000000;
        end
    end
    
    always @(posedge CLK) begin
        if(RE0) Do0 <= RAM[RA0];
        else Do0 <= 32'b0;
        if(WE0) RAM[WA0] <= Di0;
    end
endmodule