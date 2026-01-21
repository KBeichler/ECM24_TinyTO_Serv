//Test Program to Write and Read form 23LC512 512-Kbit SPI Serial SRAM

#include <SPI.h>
#include <SRAM_23LC.h>

#define SPI_PERIPHERAL		SPI
#define CHIP_SELECT_PIN		10

// function prototypes
bool write_word(uint32_t word_addr, uint32_t value);
bool read_word(uint32_t word_addr, uint32_t *out_value);
void u32_to_hex(uint32_t value, char *buffer);

//include data
#define START_ADDRESS 0
#define SRAM_DATA_SIZE 16
uint32_t sram_data[SRAM_DATA_SIZE] = {
#include "sram_data.h"
};

#define DEBUG true

// sram library
SRAM_23LC SRAM(&SPI_PERIPHERAL, CHIP_SELECT_PIN, SRAM_23LC512);

void setup() 
{
  SRAM.begin(4000000UL);      // 4 MHz SPI
  Serial.begin(115200);

  while (!Serial); // wait for serial monitor to connect

  Serial.println("---------------------------------------");
  Serial.println("--------- Writing data to SRAM --------");
  Serial.print  ("---- Start Address: \t0x");
  Serial.println  (START_ADDRESS, HEX);
  Serial.print  ("---- Data Length: \t0x");
  Serial.println(SRAM_DATA_SIZE, HEX);
  Serial.println("---------------------------------------");

  delay(1000);

  //write sequential words
  for(int i = 0; i < SRAM_DATA_SIZE; i++)
  {
    uint32_t address = START_ADDRESS + i;
    uint32_t write_value = sram_data[i];
    write_word(address, write_value);
    if(DEBUG)
    {
      char hexbuf[9];
      u32_to_hex(address, hexbuf);
      Serial.print("0x");
      Serial.print(hexbuf);
      u32_to_hex(write_value, hexbuf);
      Serial.print(": 0x");
      Serial.println(hexbuf);
    }
  }

  Serial.println("---------------------------------------");
  Serial.println("------- Writing Data Successful -------");
  Serial.println("---------------------------------------");
  Serial.println();
  delay(1000);
  Serial.println("Send any character to read back data...");
}

void loop() 
{
  //wait until serial command
  while (!Serial.available()){}

  if (Serial.read() != '\n')
    return;

  char hexbuf[9];
  uint32_t read_value;

  //read sequential words
  for(int i = 0; i < SRAM_DATA_SIZE; i++)
  {
    uint32_t address = START_ADDRESS + i;
    read_word(address, &read_value);

    u32_to_hex(address, hexbuf);
    Serial.print("0x");
    Serial.print(hexbuf);
    u32_to_hex(read_value, hexbuf);
    Serial.print(": 0x");
    Serial.println(hexbuf);
  }

  Serial.println("---------------------------------------");
  Serial.println("--------- Read Data Complete ----------");
  Serial.println("---------------------------------------");

  
  delay(2000);
}



bool write_word(uint32_t word_addr, uint32_t value)
{
  uint32_t byte_addr = word_addr * 4UL;

  uint8_t tmp[4];
  tmp[0] = (uint8_t)( value        & 0xFF);
  tmp[1] = (uint8_t)((value >>  8) & 0xFF);
  tmp[2] = (uint8_t)((value >> 16) & 0xFF);
  tmp[3] = (uint8_t)((value >> 24) & 0xFF);

  return SRAM.writeBlock(byte_addr, 4, tmp);
}


bool read_word(uint32_t word_addr, uint32_t *out_value)
{
  if (out_value == nullptr) return false;

  uint32_t byte_addr = word_addr * 4UL;

  uint8_t tmp[4];
  if (!SRAM.readBlock(byte_addr, 4, tmp)) return false;

  *out_value =
      ((uint32_t)tmp[0]      ) |
      ((uint32_t)tmp[1] <<  8) |
      ((uint32_t)tmp[2] << 16) |
      ((uint32_t)tmp[3] << 24);

  return true;
}


void u32_to_hex(uint32_t value, char *buffer)
{
  static const char hex_digits[] = "0123456789ABCDEF";

  for (int i = 7; i >= 0; i--)
  {
    buffer[i] = hex_digits[value & 0x0F];
    value >>= 4;
  }
  buffer[8] = '\0';
}


