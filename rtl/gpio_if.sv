module gpio_if (
    input  wire        i_wb_clk,
    input  wire        i_wb_rst,

    // Wishbone (minimal classic subset)
    input  wire [31:0] i_wb_adr,
    input  wire [31:0] i_wb_dat,
    input  wire        i_wb_we,
    input  wire        i_wb_stb,
    output reg  [31:0] o_wb_rdt,
    output reg         o_wb_ack,

    // GPIO
    input  wire [3:0]  i_gpio_in,
    output reg  [3:0]  o_gpio_out
);

    always @(posedge i_wb_clk) begin
        if (i_wb_rst) begin
            o_gpio_out <= 4'b0000;
            o_wb_rdt   <= 32'd0;
        end else begin

            // Readback always reflects current inputs + latched outputs            
            o_wb_rdt <= {24'd0, i_gpio_in, o_gpio_out};

            if (i_wb_stb && i_wb_we) begin
                // Only low nibble is writable (outputs)
                o_gpio_out <= i_wb_dat[3:0];
            end
        end
    end

// ack cannot be asserted longer than i_wb_stb, otherwise the Serv Core dies
assign o_wb_ack = i_wb_stb ? 1'b1 : 1'b0;
endmodule
