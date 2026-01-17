/// sta-blackbox

`default_nettype none

module serv_ram32_if
  #(    
    parameter	    rf_width = 32,
    parameter	    rf_l2d = $clog2(rf_width))
  (
   input wire                 i_clk,
   
   // SERV RF SRAM Interface (32-bit)
   input wire [rf_l2d-1:0]    i_rf_waddr,
   input wire [31:0]          i_rf_wdata,
   input wire                 i_rf_wen,
   input wire [rf_l2d-1:0]    i_rf_raddr,
   output reg [31:0]          o_rf_rdata,
   input wire                 i_rf_ren,
   
   // RAM32 Interface (32-bit operations)
   output wire [4:0]          o_ram_addr,
   output wire [31:0]         o_ram_din,
   output wire [3:0]          o_ram_we,
   output wire                o_ram_en,
   input wire [31:0]          i_ram_dout
);
  
  // Read logic: Direct 32-bit passthrough
  assign o_rf_rdata = i_ram_dout;
  // RAM32 control - full 32-bit operations

  assign o_ram_addr = i_rf_wen ? i_rf_waddr : i_rf_raddr;
  assign o_ram_din = i_rf_wdata;
  assign o_ram_we = i_rf_wen ? 4'b1111 : 4'b0000;
  assign o_ram_en = i_rf_wen | i_rf_ren;

endmodule

`default_nettype wire