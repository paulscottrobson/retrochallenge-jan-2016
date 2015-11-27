// *******************************************************************************************************************************
// *******************************************************************************************************************************
//
//    Name:     ST7920LCDDriver.h
//    Purpose:  LCD Interface for STD7920 128x64 LCD Display (Header)
//    Created:  20th October 2015
//    Authors:  Paul Robson (paul@robsons.org.uk), David Crocker (original code)
//
// *******************************************************************************************************************************
// *******************************************************************************************************************************

#include <Arduino.h>

class ST7920LCDDriver
{
public:
  ST7920LCDDriver(uint8_t cPin, uint8_t dPin, bool useSpi);    // constructor
  void begin(bool gmode = true);
  void clear(void);
  void drawText(uint8_t x,uint8_t y,uint8_t *char4);
private:
  bool gfxMode;
  bool extendedMode;
  bool useSpi;
  uint8_t clockPin, dataPin;  
  void draw(uint8_t x,uint8_t y,uint16_t word);
  void sendLcdCommand(uint8_t command);
  void sendLcdData(uint8_t data);
  void sendLcd(uint8_t data1, uint8_t data2);
  void sendLcdSlow(uint8_t data);
  void commandDelay();
  void setGraphicsAddress(unsigned int r, unsigned int c);
  void ensureBasicMode();
  void ensureExtendedMode();
};
