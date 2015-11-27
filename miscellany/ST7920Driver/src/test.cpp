#include "ST7920LCDDriver.h"

// Wiring 
//  Pin 1 (Vss)     GND
//  Pin 2 (Vdd)     5V
//  Pin 3 (VO)      N/C
//  Pin 4 (RS)      A0 (SS Pin)
//  Pin 5 (R/W)     A1 (MOSI Pin)
//  Pin 6 (E)       A2 (SClk Pin)
//  Pin 7-14 (DBx)  N/C
//  Pin 15 (RSB)    GND
//  Pin 16 (NC)     N/C
//  Pin 17 (RST)    N/C
//  Pin 18 (VOUT)   N/C
//  Pin 19 (BLA)    5V
//  Pin 20 (BLK)    0V

#define SPI_MOSI   A1
#define SPI_CLK   A2
#define SPI_ENABLE     A0 

static ST7920LCDDriver lcd(SPI_CLK, SPI_MOSI, 0);

// Initialization
void setup()
{
  pinMode(SPI_ENABLE, OUTPUT);   // must do this before we use the lcd in SPI mode
  digitalWrite(SPI_ENABLE, HIGH);
  lcd.begin(true);          
  lcd.clear();
  for (int x = 0;x < 8;x++) {
  	for (int y = 0;y < 8;y++) {
  		uint8_t b[2];
      uint8_t c = (x + y * 8) * 2+0x80;
  		b[0] = (c & 0xFF);
      b[1] = ((c+1) & 0xFF);
  		lcd.drawText(x,y*8,b); 
  	}
  }
}

void loop()
{
}


