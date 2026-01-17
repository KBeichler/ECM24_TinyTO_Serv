`default_nettype none
module soc_top_tb;

   parameter memfile = "hello_uart.hex";
   parameter memsize = 8192;
   parameter width = 1;
   parameter with_csr = 0;
   parameter compressed = 0;
   parameter align = compressed;
   
   localparam baud_rate = 57600;

   reg wb_clk = 1'b0;
   reg wb_rst = 1'b1;

   wire q;

   always  #31 wb_clk <= !wb_clk;
   initial #62 wb_rst <= 1'b0;


   uart_decoder #(baud_rate) uart_decoder (q);

   reg [1023:0] firmware_file;
   initial
     if ($value$plusargs("firmware=%s", firmware_file)) begin
	$display("Loading RAM from %0s", firmware_file);
	$readmemh(firmware_file, dut.ram.mem);
     end

   ECM24_serv_soc_top
     #(.memfile  (memfile),
       .memsize  (memsize),
       .width    (width),
       .debug    (0),
       .sim      (0),
       .with_csr (with_csr),
       .compress (compressed[0:0]),
       .align    (align[0:0]))
   dut(wb_clk, wb_rst, q);


endmodule
