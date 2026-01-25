`timescale 1ns / 1ps

module sram_23lc512_model #(
    parameter memsize = 8192)               // RAM size in bytes
   (
    input  logic sck,   // Serial Clock [cite: 37]
    input  logic cs_n,  // Chip Select (active low) [cite: 31, 37]
    input  logic si,    // Serial Data Input [cite: 30, 37]
    output reg so     // Serial Data Output [cite: 30, 37]
);

    // Memory Organization: 64K x 8-bit [cite: 16]
    logic [7:0] mem [0:4096]; 

    // Internal registers
    logic [7:0]  cmd_reg;
    logic [15:0] addr_reg;
    logic [7:0]  data_out_buffer;
    
    // SPI States
    typedef enum {IDLE, GET_CMD, GET_ADDR, DATA_TRANSFER} state_t;
    state_t state;

    integer bit_count;
    logic [15:0] current_addr;

    // Output logic: SO updated after falling edge of SCK 
    assign so = (state == DATA_TRANSFER && cmd_reg == 8'h03) ? data_out_buffer[7] : 1'b0;

    always @(posedge sck or posedge cs_n) begin
        if (cs_n) begin
            state <= IDLE;
            bit_count <= 0;
            data_out_buffer <= 8'h00;
        end else begin
            case (state)
                IDLE: begin
                    state <= GET_CMD;
                    bit_count <= 7;
                    cmd_reg <= {cmd_reg[6:0], si}; // [cite: 137]
                end

                GET_CMD: begin
                    if (bit_count == 0) begin
                        state <= GET_ADDR;
                        bit_count <= 16;
                    end else begin
                        bit_count <= bit_count - 1;
                        cmd_reg <= {cmd_reg[6:0], si};
                    end
                end

                GET_ADDR: begin                    
                    if (bit_count == 0) begin
                        state <= DATA_TRANSFER;
                        bit_count <= 7;
                        current_addr <= {addr_reg[14:0]};
                        // Pre-fetch for Read
                        data_out_buffer <= mem[{addr_reg[14:0]}];
                    end else begin
                        addr_reg <= {addr_reg[14:0], si}; // [cite: 155]
                        bit_count <= bit_count - 1;
                    end
                end

                DATA_TRANSFER: begin
                    if (cmd_reg == 8'h02) begin // WRITE 
                        mem[current_addr] <= {mem[current_addr][6:0], si};
                        if (bit_count == 0) begin
                            current_addr <= current_addr + 1; // Sequential Write [cite: 170]
                            bit_count <= 7;
                        end else begin
                            bit_count <= bit_count - 1;
                        end
                    end else if (cmd_reg == 8'h03) begin // READ 
                        if (bit_count == 0) begin
                            current_addr <= current_addr + 1; // Sequential Read [cite: 159]
                            data_out_buffer <= mem[current_addr + 1];
                            bit_count <= 7;
                        end else begin
                            bit_count <= bit_count - 1;
                            data_out_buffer <= {data_out_buffer[6:0], 1'b0};
                        end
                    end
                end
            endcase
        end
    end

    // Falling edge logic for SO data shift [cite: 414]
    always @(negedge sck) begin
        if (!cs_n && state == DATA_TRANSFER && cmd_reg == 8'h03) begin
             if (bit_count != 7) begin
                // Shift handled in posedge block for synchronization, 
                // but effectively SO represents the MSB.
             end
        end
    end

endmodule