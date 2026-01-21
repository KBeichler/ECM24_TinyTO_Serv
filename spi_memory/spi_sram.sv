`timescale 1ns / 1ps

module spi_sram (
    input wire clk,
    input wire rst_n,
    
    // Wishbone interface
    input  logic        cyc,     // cycle valid
    input  logic [13:0] adr,     // word address (one word = 32-bit)
    input  logic        we,
    input  logic [31:0] dat_i,   // write data
    input  logic [3:0]  sel,     // byte select
    output logic [31:0] dat_o,   // read data
    output logic        ack,     // acknowledge

    // SPI interface
    input  logic spi_miso,
    output logic spi_clk,
    output logic spi_mosi,
    output logic spi_cs_n
    );
    
typedef enum logic [3:0] {S_IDLE, S_LOAD_CMD, S_SHIFT_CMD, S_LOAD_ADDR, S_SHIFT_ADDR, S_LOAD_WRITE_DATA, S_SHIFT_WRITE_DATA, S_LOAD_READ_DATA, S_SHIFT_READ_DATA, S_DONE} state_t;
    
logic [5:0] cycle_counter;
logic [31:0] data_reg;
state_t state_reg;
state_t state_next;

// state register
always_ff @(posedge clk or negedge rst_n)
begin
    if (~rst_n) begin
        state_reg <= S_IDLE;      
    end else begin
        state_reg <= state_next;    
    end
end

// enable shift register
assign shift_enable = (state_reg ==  S_SHIFT_CMD) || (state_reg ==  S_SHIFT_ADDR) ||
                      (state_reg ==  S_SHIFT_WRITE_DATA) || (state_reg ==  S_SHIFT_READ_DATA);
                      

// cycle counter
always_ff @(posedge clk or negedge rst_n)
begin
    if (~rst_n) begin
        cycle_counter <= 0;  
    end else begin   
        if(!shift_enable)
            cycle_counter <= 0;
        else
            cycle_counter <= cycle_counter + 1;
    end
end

// write to shift register
always_ff @(posedge clk)
begin
    if(shift_enable & cycle_counter < 32) begin
        data_reg <= {data_reg[30:0], spi_miso}; // shift register
    end else begin
        case (state_reg)
            S_LOAD_CMD : begin
                if(we)
                    data_reg <= 32'h2;   // write command
                else 
                    data_reg <= 32'h3;   // read command
                end

            S_LOAD_ADDR : begin
                data_reg[15:2] <= adr; // convert word-address to byte address (*4)
                end
                
            S_LOAD_WRITE_DATA : begin
                    data_reg <= dat_i;
                end
                
            S_LOAD_READ_DATA : begin
                data_reg[31:0] <= 32'h0;
                end
        endcase
    end
end

// Update MOSI on falling edge
always_ff @(negedge clk) begin
    if (shift_enable) begin
        case(state_reg)
            S_SHIFT_CMD : 
                spi_mosi = data_reg[7];
            S_SHIFT_ADDR : 
                spi_mosi = data_reg[15];
            S_SHIFT_WRITE_DATA : 
                spi_mosi = data_reg[31];
        endcase
    end
end 

// next state logic
always_comb 
begin
    state_next = state_reg;
    case (state_reg) 
        S_IDLE : begin
            if (cyc)
                state_next = S_LOAD_CMD; 
            end
            
        S_LOAD_CMD : begin        
            state_next = S_SHIFT_CMD; 
            end
            
        S_SHIFT_CMD : begin
            if(cycle_counter > 7)
                state_next = S_LOAD_ADDR; 
            end  
                 
        S_LOAD_ADDR : begin        
            state_next = S_SHIFT_ADDR; 
            end       
             
        S_SHIFT_ADDR : begin
            if(cycle_counter > 15) begin
                if(we)
                    state_next = S_LOAD_WRITE_DATA;    
                else
                    state_next = S_LOAD_READ_DATA; 
                end
            end  
                      
        S_LOAD_WRITE_DATA : begin           
            state_next = S_SHIFT_WRITE_DATA; 
            end   
                               
        S_SHIFT_WRITE_DATA : begin
            if(cycle_counter > 31)
                state_next = S_DONE; 
            end   
            
        S_LOAD_READ_DATA : begin           
            state_next = S_SHIFT_READ_DATA; 
            end       
                 
        S_SHIFT_READ_DATA : begin
            if(cycle_counter > 31)
                state_next = S_DONE; 
            end
            
        S_DONE : begin
            if(!cyc)
                state_next = S_IDLE; 
            end
        
    endcase
end  

// spi outputs  
assign spi_clk  = clk & shift_enable & (cycle_counter > 0);
assign spi_cs_n = (state_reg == S_IDLE || state_reg == S_DONE);

// wishbone outputs
assign ack   = (state_reg == S_DONE);
assign dat_o = data_reg;
    
endmodule
