# ECM24 SERV Core

## Vivado Project

The **serv_soc** folder contains the Vivado project with the SoC.

- `ECM24_serv_soc_top`: instantiates all modules
    - SERV core with servile wrapper
    - `rf_ram_if` and `RAM32` macro
    - Wishbone interface to RAM
        - currently uses *servant_ram* for simulation testing
        - this should be replaced with an SPI–RAM interface
    - `subservient_gpio`
        - the servile wrapper maps all addresses higher than `0x40000000` to the external Wishbone bus
        - currently a single GPIO can be accessed by writing to this address
        - a custom Wishbone–IO module may be implemented here

## Example Programs

The **example_program** folder contains a sample program to test the SoC in simulation. This program is loaded into the *servant_ram* module when the simulation starts.

This example was taken from the official SERV repository:

https://github.com/olofk/serv/tree/main