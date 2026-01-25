# ECM24 SERV Core

https://github.com/olofk/serv/tree/main


# TODO

- [ ] Check correct RAM size and set stack pointer in start.S
- [ ] verify spi_sram.sv with real hardware. Reading and writing
- [ ] check if reset has correct polarity for ASIC (SERV reset is active high)
- [ ] now we uses sysclk for SPI -> should we change that?


## Vivado Project

The **vivado_prj** folder contains the Vivado project with the SoC.

All RTL code needed for the system is int he **rtl subfolder**:

- `ECM24_serv_soc_top`: instantiates all modules
    - SERV core with servile wrapper
    - `rf_ram_if` and `RAM32` macro
    - Wishbone interface to SPI SRAM `spi_sram`
    - `subservient_gpio`
        - the servile wrapper maps all addresses higher than `0x40000000` to the external Wishbone bus
        - currently a single GPIO can be accessed by writing to this address
        - a custom Wishbone–IO module may be implemented here
    
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