#include <Arduino.h>


void setup() {
  // put your setup code here, to run once:
  Serial.begin(9600);
}

int n = 0;

void loop() {
  n = n + 1;
  Serial.print("S=");
  Serial.print(n);
  // put your main code here, to run repeatedly:
  Serial.print(" V=");
  Serial.print(analogRead(A8));
  int n = pulseIn(8,LOW);
  n = n + pulseIn(8,HIGH);
  Serial.print(" F=");
  Serial.println(1000000/n);
  delay(100);
}
