/*
 * Copyright (c) 2026 FH Joanneum
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: tt_um_ECM24_serv_soc_top
// Description: SERV RISC-V SoC top-level module for TinyTapeout
//              Integrates SERV CPU core with RAM and GPIO peripherals
// 
// Create Date: 17.01.2026 11:15:30
//////////////////////////////////////////////////////////////////////////////////

module tt_um_ECM24_serv_soc_top
(
 input  wire [7:0] ui_in,    // Dedicated inputs
 output wire [7:0] uo_out,   // Dedicated outputs
 input  wire [7:0] uio_in,   // IOs: Input path
 output wire [7:0] uio_out,  // IOs: Output path
 output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
 input  wire       ena,      // always 1 when the design is powered, so you can ignore it
 input  wire       clk,      // clock
 input  wire       rst_n     // reset_n - low to reset
);

   //=============================================================================
   // Parameters
   //=============================================================================
   parameter reset_strategy = "MINI";      // Reset strategy for RAM
   parameter width = 1;                    // SERV CPU width (bit-serial)
   parameter sim = 0;                      // Simulation mode flag
   parameter [0:0] debug = 1'b0;          // Enable debug features
   parameter with_csr = 0;                 // Include CSR support
   parameter [0:0] compress = 0;          // Enable compressed instructions
   parameter [0:0] align = compress;      // Alignment configuration

   localparam [0:0] with_mdu = 1'b0;      // MDU (multiply/divide) disabled
   localparam csr_regs = with_csr*4;      // Number of CSR registers
   localparam rf_width = 32;              // Register file width
   localparam rf_l2d = $clog2(rf_width);  // Register file depth

   //=============================================================================
   // Pin Mapping
   //=============================================================================
   // Inputs
   wire spi_miso = ui_in[0];
   wire gpio_module_in = ui_in[7:4];
   wire gpio_module_out  = uo_out[7:4];
   
   // Outputs
   wire gpio_out;
   wire spi_mosi;
   wire spi_clk;
   wire spi_cs1_n;
   wire spi_cs2_n;
   assign spi_cs2_n = 1'b1;
   
   assign uo_out[0] = spi_mosi;
   assign uo_out[1] = spi_clk;
   assign uo_out[2] = spi_cs1_n;
   assign uo_out[3] = spi_cs2_n;
   
   // Bidirectional pins not used
   assign uio_out = 8'b0;
   assign uio_oe  = 8'b0;
   
   // Internal clock and reset
   wire wb_clk = clk;
   wire wb_rst = ~rst_n;

   //=============================================================================
   // Wishbone Memory Bus Signals (CPU <-> RAM)
   //=============================================================================
   wire [31:0] 	wb_mem_adr;
   wire [31:0] 	wb_mem_dat;
   wire [3:0] 	wb_mem_sel;
   wire 	   wb_mem_we;
   wire 	       wb_mem_stb;
   wire [31:0] 	wb_mem_rdt;
   wire 	   wb_mem_ack;

   //=============================================================================
   // Wishbone External Bus Signals (CPU <-> Peripherals)
   //=============================================================================
   wire [31:0]	   wb_ext_adr;
   wire [31:0]	   wb_ext_dat;
   wire [3:0]	   wb_ext_sel;
   wire		   wb_ext_we;
   wire		   wb_ext_stb;
   wire [31:0]	   wb_ext_rdt;
   wire		   wb_ext_ack;

   //=============================================================================
   // Register File Signals (CPU <-> RF RAM)
   //=============================================================================
   wire [rf_l2d-1:0]   rf_waddr;
   wire [rf_width-1:0] rf_wdata;
   wire		           rf_wen;
   wire [rf_l2d-1:0]   rf_raddr;
   wire		           rf_ren;
   wire [rf_width-1:0] rf_rdata;

   //=============================================================================
   // RAM Module - Main memory for the SoC
   //=============================================================================
      
    spi_sram ram_spi_if(
    .clk(wb_clk),
    .rst_n(rst_n),

    .cyc(wb_mem_stb),     // cycle valid
    .adr(wb_mem_adr[15:2]),    // word address (14-bit for 64KB range)
    .we(wb_mem_we),
    .dat_i(wb_mem_dat),   // write data
    .sel(wb_mem_sel),     // byte select
    .dat_o(wb_mem_rdt),   // read data
    .ack(wb_mem_ack),     // acknowledge

    // SPI interface
    .spi_miso(spi_miso),
    .spi_clk(spi_clk),
    .spi_mosi(spi_mosi),
    .spi_cs_n(spi_cs1_n));

   //=============================================================================
   // GPIO Module - Simple GPIO peripheral for output
   //=============================================================================

      
     gpio_if  u_gpio_if (
      .i_wb_clk  (wb_clk),
      .i_wb_rst  (wb_rst),

      .i_wb_adr  (wb_ext_adr),
      .i_wb_dat  (wb_ext_dat),
      .i_wb_we   (wb_ext_we),
      .i_wb_stb  (wb_ext_stb),
      .o_wb_rdt  (wb_ext_rdt),
      .o_wb_ack  (wb_ext_ack),

      .i_gpio_in (ui_in[7:4]),
      .o_gpio_out(uo_out[7:4])
   );

   //=============================================================================
   // Register File RAM - RAM32 macro with interface
   //=============================================================================
   
   // RAM32 Interface signals
   wire [4:0]  ram32_addr;
   wire [31:0] ram32_din;
   wire [3:0]  ram32_we;
   wire        ram32_en;
   wire [31:0] ram32_dout;

   // RAM32 Interface Module
   serv_ram32_if 
     #(.rf_width (rf_width),
       .rf_l2d   (rf_l2d))
   rf_if
     (.i_clk      (wb_clk),
      .i_rf_waddr (rf_waddr),
      .i_rf_wdata (rf_wdata),
      .i_rf_wen   (rf_wen),
      .i_rf_raddr (rf_raddr),
      .o_rf_rdata (rf_rdata),
      .i_rf_ren   (rf_ren),
      .o_ram_addr (ram32_addr),
      .o_ram_din  (ram32_din),
      .o_ram_we   (ram32_we),
      .o_ram_en   (ram32_en),
      .i_ram_dout (ram32_dout));

   // RAM32 Macro Instance
   RAM32 rf_ram
     (
`ifdef USE_POWER_PINS
      .VPWR (1'b1),
      .VGND (1'b0),
`endif
      .CLK  (wb_clk),
      .WE0  (ram32_we),
      .EN0  (ram32_en),
      .A0   (ram32_addr),
      .Di0  (ram32_din),
      .Do0  (ram32_dout));

   //=============================================================================
   // SERV CPU Core - Bit-serial RISC-V CPU
   //=============================================================================
   servile
     #(.width    (width),
       .sim      (0),
       .debug    (debug),
       .rf_width(rf_width),
       .with_c   (compress[0]),
       .with_csr (with_csr[0]),
       .with_mdu (with_mdu))
   cpu
     (
      .i_clk        (wb_clk),
      .i_rst        (wb_rst),
      .i_timer_irq  (1'b0),

      .o_wb_mem_adr   (wb_mem_adr),
      .o_wb_mem_dat   (wb_mem_dat),
      .o_wb_mem_sel   (wb_mem_sel),
      .o_wb_mem_we    (wb_mem_we),
      .o_wb_mem_stb   (wb_mem_stb),
      .i_wb_mem_rdt   (wb_mem_rdt),
      .i_wb_mem_ack   (wb_mem_ack),

      .o_wb_ext_adr   (wb_ext_adr),
      .o_wb_ext_dat   (wb_ext_dat),
      .o_wb_ext_sel   (wb_ext_sel),
      .o_wb_ext_we    (wb_ext_we),
      .o_wb_ext_stb   (wb_ext_stb),
      .i_wb_ext_rdt   (wb_ext_rdt),
      .i_wb_ext_ack   (wb_ext_ack),

      .o_rf_waddr  (rf_waddr),
      .o_rf_wdata  (rf_wdata),
      .o_rf_wen    (rf_wen),
      .o_rf_raddr  (rf_raddr),
      .o_rf_ren    (rf_ren),
      .i_rf_rdata  (rf_rdata));

   // List all unused inputs to prevent warnings
   wire _unused = &{ena, ui_in[7:6], uio_in, 1'b0};

endmodule