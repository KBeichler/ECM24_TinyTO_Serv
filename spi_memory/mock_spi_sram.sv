`timescale 1ns / 1ps
module M23LC512 (
    input  logic CS_n,  // Chip Select (Active Low) [cite: 416]
    input  logic SCK,   // Serial Clock [cite: 412]
    input  logic SI,    // Serial Input (MOSI) [cite: 425]
    output logic SO,    // Serial Output (MISO) [cite: 421]
    input  logic HOLD_n // Hold (Active Low) [cite: 437]
);

    // -------------------------------------------------------------------------
    // Parameters and Memory Storage
    // -------------------------------------------------------------------------
    // 64K x 8-bit Organization (512 Kbit) 
    localparam MEM_SIZE = 65536; 
    
    // Memory Array
    logic [7:0] mem_array [0:MEM_SIZE-1];

    // -------------------------------------------------------------------------
    // Instructions (Hex Codes) 
    // -------------------------------------------------------------------------
    localparam CMD_READ  = 8'h03;
    localparam CMD_WRITE = 8'h02;
    localparam CMD_RDMR  = 8'h05; // Read Mode Register
    localparam CMD_WRMR  = 8'h01; // Write Mode Register
    
    // Note: EDIO, EQIO, RSTIO are for Dual/Quad modes and are not 
    // implemented in this standard SPI model.

    // -------------------------------------------------------------------------
    // Mode Register [cite: 312]
    // -------------------------------------------------------------------------
    // Bits 7:6 define operation mode:
    // 00 = Byte Mode
    // 10 = Page Mode
    // 01 = Sequential Mode (Default) [cite: 310]
    logic [7:0] mode_reg = 8'b01000000; 

    // -------------------------------------------------------------------------
    // Internal States and Counters
    // -------------------------------------------------------------------------
    typedef enum {
        IDLE,
        GET_CMD,
        GET_ADDR,
        READ_DATA,
        WRITE_DATA,
        RDMR_STATE,
        WRMR_STATE
    } state_t;

    state_t state = IDLE;

    logic [7:0]  cmd_buffer;
    logic [15:0] addr_buffer;
    logic [7:0]  data_buffer; // For collecting incoming write data
    logic [7:0]  out_buffer;  // For shifting out read data
    
    int bit_cnt;  // Counter for bits within a byte/word
    
    // Drive SO control
    logic drive_so;

    // -------------------------------------------------------------------------
    // Reset and Chip Select Logic
    // -------------------------------------------------------------------------
    // When CS is high, device is in Standby and SO is High-Z [cite: 417, 418]
    always @(posedge CS_n) begin
        state <= IDLE;
        drive_so <= 0;
        bit_cnt <= 0;
    end

    // -------------------------------------------------------------------------
    // Serial Input Logic (Latch on Rising Edge) 
    // -------------------------------------------------------------------------
    always @(posedge SCK or posedge CS_n) begin
        if (CS_n) begin
            // Async reset handled above, but strictly logic reset here
            cmd_buffer <= 0;
        end 
        else if (HOLD_n) begin // Ignore transitions if HOLD is active [cite: 438]
            
            case (state)
                IDLE: begin
                    state <= GET_CMD;
                    bit_cnt <= 0;
                    // Latch first bit of command
                    cmd_buffer <= {cmd_buffer[6:0], SI}; 
                    bit_cnt <= 1;
                end

                GET_CMD: begin
                    cmd_buffer <= {cmd_buffer[6:0], SI};
                    bit_cnt <= bit_cnt + 1;
                    
                    if (bit_cnt == 7) begin // 8th bit received
                        bit_cnt <= 0;
                        case ({cmd_buffer[6:0], SI})
                            CMD_READ:  state <= GET_ADDR;
                            CMD_WRITE: state <= GET_ADDR;
                            CMD_RDMR:  begin
                                state <= RDMR_STATE;
                                out_buffer <= mode_reg; // Load mode reg to output
                            end
                            CMD_WRMR:  state <= WRMR_STATE;
                            default:   state <= IDLE; // Unknown command
                        endcase
                    end
                end

                GET_ADDR: begin
                    addr_buffer <= {addr_buffer[14:0], SI};
                    bit_cnt <= bit_cnt + 1;
                    if (bit_cnt == 15) begin // 16th bit received
                        bit_cnt <= 0;
                        if (cmd_buffer == CMD_READ) begin
                            state <= READ_DATA;
                            // Pre-load data for the falling edge output
                            out_buffer <= mem_array[{addr_buffer[14:0], SI}];
                        end else begin
                            state <= WRITE_DATA;
                        end
                    end
                end

                WRITE_DATA: begin
                    data_buffer <= {data_buffer[6:0], SI};
                    bit_cnt <= bit_cnt + 1;
                    if (bit_cnt == 7) begin // Byte complete
                        // Perform Write
                        mem_array[addr_buffer] <= {data_buffer[6:0], SI};
                        bit_cnt <= 0;
                        
                        // Handle Address Incrementing based on Mode 
                        handle_address_increment();
                    end
                end

                WRMR_STATE: begin
                    // Writing to Mode Register [cite: 359]
                    mode_reg <= {mode_reg[6:0], SI};
                    bit_cnt <= bit_cnt + 1;
                    if (bit_cnt == 7) begin
                        state <= IDLE; // WRMR is single byte
                    end
                end

                READ_DATA: begin
                    // Input side just counts clocks in Read mode to handle address logic
                    bit_cnt <= bit_cnt + 1;
                    if (bit_cnt == 7) begin
                        bit_cnt <= 0;
                        // Pre-fetch NEXT byte for output
                        // Address increment happens here to prepare for next byte
                         handle_address_increment();
                         out_buffer <= mem_array[addr_buffer];
                    end
                end

                RDMR_STATE: begin
                    // Just dummy cycling on input side, waiting for CS_n to go high
                end
            endcase
        end
    end

    // -------------------------------------------------------------------------
    // Serial Output Logic (Change on Falling Edge) 
    // -------------------------------------------------------------------------
    always @(negedge SCK or posedge CS_n) begin
        if (CS_n) begin
            drive_so <= 0;
        end 
        else if (HOLD_n) begin
            case (state)
                READ_DATA: begin
                    drive_so <= 1;
                end
                RDMR_STATE: begin
                    drive_so <= 1;
                end
                default: begin
                    drive_so <= 0;
                end
            endcase
            
            // Shift output data
            if (drive_so) begin
                out_buffer <= {out_buffer[6:0], 1'b0};
            end
        end
    end

    // Assign Output with Tristate [cite: 418]
    assign SO = (drive_so && !CS_n && HOLD_n) ? out_buffer[7] : 1'bz;

    // -------------------------------------------------------------------------
    // Helper Task: Address Increment Logic
    // -------------------------------------------------------------------------
    // Logic derived from Section 2.2 Modes of Operation [cite: 142]
    task handle_address_increment();
        logic [1:0] mode;
        mode = mode_reg[7:6]; // Bits 7 and 6 control mode 

        case (mode)
            2'b00: begin 
                // Byte Mode: "Read/write operations are limited to only one byte".
                // We do not increment. If clock continues, we overwrite/reread same index 
                // or just stop. Standard behavior is usually static address or ignore.
                // Keeping address static allows repeated read/write of same byte if CS held.
            end

            2'b10: begin 
                // Page Mode: 32-byte page. [cite: 147]
                // "Internal address counter will increment to the start of the page" on wrap[cite: 149].
                logic [4:0] page_offset;
                page_offset = addr_buffer[4:0] + 1;
                addr_buffer = {addr_buffer[15:5], page_offset};
            end

            2'b01: begin 
                // Sequential Mode (Default). [cite: 150]
                // Address rolls over to 0x0000 after 0xFFFF.
                addr_buffer = addr_buffer + 1;
            end
            
            default: begin 
                // Reserved (Treat as sequential or idle)
                addr_buffer = addr_buffer + 1;
            end
        endcase
    endtask

    // -------------------------------------------------------------------------
    // Simulation Backdoor Access (Optional)
    // -------------------------------------------------------------------------
    // Helper to load memory from file for testbench initialization
    task load_memory(string filename);
        $readmemh(filename, mem_array);
    endtask

endmodule

/*
logic CS_n, SCK, SI, HOLD_n;
    wire SO;

    // Instantiate the SRAM
    M23LC512 sram_inst (
        .CS_n(CS_n),
        .SCK(SCK),
        .SI(SI),
        .SO(SO),
        .HOLD_n(HOLD_n)
    );
*/

module sram_23lc512_model (
    input  logic sck,   // Serial Clock [cite: 37]
    input  logic cs_n,  // Chip Select (active low) [cite: 31, 37]
    input  logic si,    // Serial Data Input [cite: 30, 37]
    output reg so     // Serial Data Output [cite: 30, 37]
);

    // Memory Organization: 64K x 8-bit [cite: 16]
    logic [7:0] mem [0:1024]; 

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
                    cmd_reg <= {cmd_reg[6:0], si};
                    if (bit_count == 0) begin
                        state <= GET_ADDR;
                        bit_count <= 15;
                    end else begin
                        bit_count <= bit_count - 1;
                        
                    end
                end

                GET_ADDR: begin
                    addr_reg <= {addr_reg[14:0], si}; // [cite: 155]
                    if (bit_count == 0) begin
                        state <= DATA_TRANSFER;
                        bit_count <= 7;
                        current_addr <= {addr_reg[14:0], si};
                        // Pre-fetch for Read
                        data_out_buffer <= mem[{addr_reg[14:0], si}];
                    end else begin
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