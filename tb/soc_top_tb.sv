`timescale 1ns / 1ps
`default_nettype none
module soc_top_tb;

   //parameter memfile = "hello_uart_8b.hex";
   //parameter memfile = "blink.hex";
   parameter memfile = "gpio_test.hex";
   parameter memsize = 8192;
   parameter sim = 0;
   parameter debug = 0;
   parameter width = 1;
   parameter with_csr = 0;
   parameter compressed = 0;
   parameter align = compressed;
   
   localparam baud_rate = 57600;

   reg wb_clk = 1'b0;
   reg wb_rst = 1'b1;

   wire q;
   
   // SPI signals between DUT and SRAM model
   wire spi_miso;
   wire spi_mosi;
   wire spi_clk;
   wire spi_cs1;
   wire spi_cs2;
   
    wire [3:0]  gpio_in;
    wire [3:0]  gpio_out;       // GPIO output

   // 1 MHZ clock
   always  #500 wb_clk <= !wb_clk;
   initial #1000 wb_rst <= 1'b0;


   uart_decoder #(baud_rate) uart_decoder (gpio_out[0]);

   reg [1023:0] firmware_file;
   
   // Comment out direct memory access - SRAM model doesn't expose mem array
    initial
    begin
   //     $display("Loading RAM from %0s", firmware_file);
        $readmemh(memfile, sram_model.mem);
    end

     
    assign gpio_in = 4'b0100;

   tt_um_ECM24_serv_soc_top     
   #(  .width    (width),
       .debug    (debug),
       .sim      (sim),
       .with_csr (with_csr),
       .compress (compressed[0:0]),
       .align    (align[0:0]))
    dut(
    .ui_in({gpio_in, 3'b000, spi_miso}),    // Dedicated inputs
    .uo_out({gpio_out, spi_cs2, spi_cs1, spi_clk, spi_mosi }),   // Dedicated outputs
    .uio_in(),   // IOs: Input path
    .uio_out(),  // IOs: Output path
    .uio_oe(),   // IOs: Enable path (active high: 0=input, 1=output)
    .ena(1'b1),
    .clk(wb_clk),
    .rst_n(~wb_rst)
   );

   // Instantiate SRAM model and connect to DUT
   sram_23lc512_model# (
        .memsize(memsize)) sram_model (
       .sck(spi_clk),
       .cs_n(spi_cs1),
       .si(spi_mosi),
       .so(spi_miso)
   );


endmodule
