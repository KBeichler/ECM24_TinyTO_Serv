# ECM24 SERV Core

https://github.com/olofk/serv/tree/main


# TODO

- [ ] Check correct RAM size and set stack pointer in start.S
- [ ] verify spi_sram.sv with real hardware. Reading and writing

- [x] check if reset has correct polarity for ASIC (SERV reset is active high)
- [ ] check pinout again -> TinyTO breakout board https://tinytapeout.com/specs/pinouts/
    - [ ] Could use RP2040 for RAM emulation https://github.com/MichaelBell/spi-ram-emu 
    - [ ] compability to PMOD extensions (uart)
- [ ] we have space -> more peripherals? UART?
- [ ] Do we use RAM32 macro right now? or just FFs

- [ ] QSPI Ram IF?

## Vivado Project

The **vivado_prj** folder contains the Vivado project with the SoC.

All RTL code needed for the system is int he **rtl subfolder**:

- `ECM24_serv_soc_top`: instantiates all modules
    - SERV core with servile wrapper
    - `rf_ram_if` and `RAM32` macro
    - Wishbone interface to SPI SRAM `spi_sram`
    - `gpio_if`
        - the servile wrapper maps all addresses higher than `0x40000000` to the external Wishbone bus
        - currently 4 input and 4 outputs are mapped to the 8 bits of address  `0x40000000`
            - [3:0] Output, [7:4] Input
    
All testbench code is located in the **tb** folder.


## Example Programs

The **sw** folder contains sample programs to test the SoC in simulation. Any c file can be build with the command `make SRC=my_custom_file.c`. These programs can be loaded into the *SRAM_Mock* module when the simulation starts in `soc_top_tb.sv`.



# IO

IOs are mapped in SW to address `0x40000000`.

What IOs are used by top module?

Available:
    - 8 Input
    - 8 Output
    - 8 Bidirection


Used:
    - SPI - 4 Out 1 In

Maybe:
    - 4 GPIO Out + 4 GPIO In

External Reset to SRV core?