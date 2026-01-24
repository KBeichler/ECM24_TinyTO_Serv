`timescale 1ns / 1ps

// Minimal Wishbone to SPI SRAM interface for 23LC512
// - 4-state FSM: IDLE -> SHIFT_CMD_ADDR -> SHIFT_DATA -> DONE
// - Full-speed SPI clock (no division)
// - No byte-swapping (handled in software)
// - Assumes sequential mode preset on SRAM

module spi_sram (
    input  wire        clk,
    input  wire        rst_n,
    
    // Wishbone interface
    input  logic        cyc,        // cycle valid
    input  logic [13:0] adr,        // word address (32-bit words)
    input  logic        we,         // write enable
    input  logic [31:0] dat_i,      // write data
    input  logic [3:0]  sel,        // byte select (ignored - always 32-bit)
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
    
    // Convert word address to byte address
    wire [15:0] byte_addr = {adr, 2'b00};
    
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
        end else begin
            case (state)
                S_IDLE: begin
                    if (cyc)
                        bit_cnt <= 23;  // 24 bits for cmd+addr
                end
                
                S_SHIFT_CMD_ADDR: begin
                    if (bit_cnt == 0)
                        bit_cnt <= 31;  // 32 bits for data
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
                        tx_data <= dat_i;
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
