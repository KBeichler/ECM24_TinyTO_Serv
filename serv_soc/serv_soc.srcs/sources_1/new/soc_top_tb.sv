`timescale 1ns / 1ps
`default_nettype none
module soc_top_tb;

   parameter memfile = "hello_uart_8b.hex";
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

   // 16 MHZ clock
   always  #31 wb_clk <= !wb_clk;
   initial #124 wb_rst <= 1'b0;


   uart_decoder #(baud_rate) uart_decoder (q);

   reg [1023:0] firmware_file;
   
   // Comment out direct memory access - SRAM model doesn't expose mem array
    initial
    begin
   //     $display("Loading RAM from %0s", firmware_file);
        $readmemh("hello_uart_8b.hex", sram_model.mem);
    end

     


   ECM24_serv_soc_top
     #(.memfile  (memfile),
       .memsize  (memsize),
       .width    (width),
       .debug    (debug),
       .sim      (sim),
       .with_csr (with_csr),
       .compress (compressed[0:0]),
       .align    (align[0:0]))
   dut(
       .wb_clk(wb_clk),
       .wb_rst(wb_rst), 
       .q(q),
       .spi_miso(spi_miso),
       .spi_mosi(spi_mosi),
       .spi_clk(spi_clk),
       .spi_cs1(spi_cs1),
       .spi_cs2(spi_cs2)
   );

   // Instantiate SRAM model and connect to DUT
   sram_23lc512_model sram_model (
       .sck(spi_clk),
       .cs_n(spi_cs1),
       .si(spi_mosi),
       .so(spi_miso)
   );


endmodule
