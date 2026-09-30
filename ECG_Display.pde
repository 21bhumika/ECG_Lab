/******************************************************************************
BME/CS 479 Group 7 - Lab 2 (ECG) - Dominic, Atulya, Luka, Bhumika
******************************************************************************/

void setup () {
  // set the window size:
  size(800, 800);   
  frameRate(10);
}


void draw () {
     fill(0);
     background(255);
     
     int bpm = int(random(0, 101));
     int resp = int(random(0, 101));
     int spo2 = int(random(0, 101));
     
     text("BPM: " + bpm, 20, 20);
     text("RPM: " + resp, 20, 40);
     text("SpO2: " + spo2, 20, 60);  
}
