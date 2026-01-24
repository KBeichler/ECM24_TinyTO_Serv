`timescale 1ns / 1ps

// Minimal Wishbone to SPI SRAM interface for 23LC512
// - 4-state FSM: IDLE -> SHIFT_CMD_ADDR -> SHIFT_DATA -> DONE
// - Full-speed SPI clock (no division)
// - No byte-swapping (handled in software)
// - Assumes sequential mode preset on SRAM
// - Supports byte/halfword/word writes via sel (aligned only)

module spi_sram (
    input  wire        clk,
    input  wire        rst_n,
    
    // Wishbone interface
    input  logic        cyc,        // cycle valid
    input  logic [13:0] adr,        // word address (32-bit words)
    input  logic        we,         // write enable
    input  logic [31:0] dat_i,      // write data
    input  logic [3:0]  sel,        // byte select
    output logic [31:0] dat_o,      // read data
    output logic        ack,        // acknowledge

    // SPI interface
    input  logic        spi_miso,
    output logic        spi_clk,
    output logic        spi_mosi,
    output logic        spi_cs_n
);

    // State machine
    typedef enum logic [1:0] {
        S_IDLE,
        S_SHIFT_CMD_ADDR,
        S_SHIFT_DATA,
        S_DONE
    } state_t;
    
    state_t state, state_next;
    
    // Registers
    logic [23:0] tx_cmd_addr;   // 8-bit cmd + 16-bit address
    logic [31:0] tx_data;       // write data shift register
    logic [31:0] rx_data;       // read data shift register
    logic [5:0]  bit_cnt;       // bit counter
    logic        is_write;      // latched write flag
    logic [5:0]  data_bits;     // number of data bits to shift (8, 16, or 32)
    
    // Convert word address to byte address (base)
    wire [15:0] byte_addr_base = {adr, 2'b00};
    
    // Calculate byte offset and data bits based on sel
    logic [1:0]  byte_offset;
    logic [5:0]  num_data_bits;
    logic [31:0] aligned_data;
    
    always_comb begin
        // Default: full word
        byte_offset   = 2'b00;
        num_data_bits = 32;
        aligned_data  = dat_i;
        
        if (we) begin
            case (sel)
                // Byte writes
                4'b1000: begin byte_offset = 2'b00; num_data_bits = 8;  aligned_data = {dat_i[31:24], 24'b0}; end
                4'b0100: begin byte_offset = 2'b01; num_data_bits = 8;  aligned_data = {dat_i[23:16], 24'b0}; end
                4'b0010: begin byte_offset = 2'b10; num_data_bits = 8;  aligned_data = {dat_i[15:8],  24'b0}; end
                4'b0001: begin byte_offset = 2'b11; num_data_bits = 8;  aligned_data = {dat_i[7:0],   24'b0}; end
                // Halfword writes
                4'b1100: begin byte_offset = 2'b00; num_data_bits = 16; aligned_data = {dat_i[31:16], 16'b0}; end
                4'b0011: begin byte_offset = 2'b10; num_data_bits = 16; aligned_data = {dat_i[15:0],  16'b0}; end
                // Word write (default)
                4'b1111: begin byte_offset = 2'b00; num_data_bits = 32; aligned_data = dat_i; end
                default: begin byte_offset = 2'b00; num_data_bits = 32; aligned_data = dat_i; end
            endcase
        end
    end
    
    wire [15:0] byte_addr = byte_addr_base + {14'b0, byte_offset};
    
    // Shift enable signal
    wire shifting = (state == S_SHIFT_CMD_ADDR) || (state == S_SHIFT_DATA);
    
    // State register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= S_IDLE;
        else
            state <= state_next;
    end
    
    // Next state logic
    always_comb begin
        state_next = state;
        case (state)
            S_IDLE: begin
                if (cyc)
                    state_next = S_SHIFT_CMD_ADDR;
            end
            
            S_SHIFT_CMD_ADDR: begin
                if (bit_cnt == 0)
                    state_next = S_SHIFT_DATA;
            end
            
            S_SHIFT_DATA: begin
                if (bit_cnt == 0)
                    state_next = S_DONE;
            end
            
            S_DONE: begin
                state_next = S_IDLE;
            end
        endcase
    end
    
    // Bit counter
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_cnt <= 0;
            data_bits <= 32;
        end else begin
            case (state)
                S_IDLE: begin
                    if (cyc) begin
                        bit_cnt <= 23;  // 24 bits for cmd+addr
                        data_bits <= we ? num_data_bits : 32;  // reads always 32 bits
                    end
                end
                
                S_SHIFT_CMD_ADDR: begin
                    if (bit_cnt == 0)
                        bit_cnt <= data_bits - 1;  // data bits based on sel
                    else
                        bit_cnt <= bit_cnt - 1;
                end
                
                S_SHIFT_DATA: begin
                    if (bit_cnt > 0)
                        bit_cnt <= bit_cnt - 1;
                end
                
                default: bit_cnt <= 0;
            endcase
        end
    end
    
    // TX cmd/addr shift register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_cmd_addr <= 0;
            is_write <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    if (cyc) begin
                        // Load command (0x02=write, 0x03=read) + byte address
                        tx_cmd_addr <= {we ? 8'h02 : 8'h03, byte_addr};
                        is_write <= we;
                    end
                end
                
                S_SHIFT_CMD_ADDR: begin
                    tx_cmd_addr <= {tx_cmd_addr[22:0], 1'b0};
                end
                
                default: ;
            endcase
        end
    end
    
    // TX data shift register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_data <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    if (cyc)
                        tx_data <= aligned_data;
                end
                
                S_SHIFT_DATA: begin
                    if (is_write)
                        tx_data <= {tx_data[30:0], 1'b0};
                end
                
                default: ;
            endcase
        end
    end
    
    // RX data shift register - sample on rising edge
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data <= 0;
        end else begin
            if (state == S_SHIFT_DATA && !is_write)
                rx_data <= {rx_data[30:0], spi_miso};
        end
    end
    
    // SPI outputs
    assign spi_cs_n = (state == S_IDLE);
    assign spi_clk  = clk & shifting;
    assign spi_mosi = (state == S_SHIFT_CMD_ADDR) ? tx_cmd_addr[23] :
                      (state == S_SHIFT_DATA && is_write) ? tx_data[31] : 1'b0;
    
    // Wishbone outputs
    assign ack   = (state == S_DONE);
    assign dat_o = rx_data;

endmodule
