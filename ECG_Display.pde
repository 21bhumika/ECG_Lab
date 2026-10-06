/******************************************************************************
BME/CS 479 Group 7 - Lab 2 (ECG) - Dominic, Atulya, Luka, Bhumika
******************************************************************************/

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.HashMap;
import processing.serial.*;

// ----- SERIAL ------
// DATA,time,ecgRaw,ecgFiltered,fsrRaw,fsrFiltered,heartRate,respRate,inhaleTime,exhaleTime
String[] dataFields = {"time", "ecgRaw", "ecgFiltered", "fsrRaw", "fsrFiltered",
                       "heartRate", "respRate", "inhaleTime", "exhaleTime"};
int serialPortIndex = 0; // index into Serial.list(), check the console output
int maxSeriesLength = 1000; // 10 s at 100 samples/s
Serial port;
Map<String, List<Float>> series = new HashMap<>();

// ----- CONSTS ------
String[] screens = {"Input + Wait", "Main Page", "Fitness Mode", "Stress Mode - Menu", "Stress Mode - Elevating", "Stress Mode - Calming", "Stress Mode - Result", "Meditate Mode - Menu", "Meditate Mode - Game", "Meditate Mode - Result", "History"};
int currentScreen = 2;
int[] fitnessZoneTimes = {0, 0, 0, 0, 0, 0}; // No, VL, L, M, H, VH Zones
List<Integer> bpms = new ArrayList<>(Arrays.asList());
List<Integer> rpms = new ArrayList<>(Arrays.asList());
int bpmSum = 0, rpmSum = 0, sampleCount = 0;
int lastSecondMs = 0;

int screenWidth = 800, screenHeight = 800;
int gridOffset = 0; // scrolling grid
int historyTimeframe = 30; // how many s the graph will check back to

PFont headerFont;
PFont mainFont;

// colors
color black = color(0, 0, 0);
color gray = color(172, 172, 172);
color lightGray = color(236, 236, 236);
color purple = color(176, 38, 240);
color darkPurple = color(110, 20, 150);
color red = color(232, 54, 95);
color orange = color(249,108,8);
color yellow = color(249,201,8);
color green = color(57, 230, 13);
color blue = color(8, 185, 249);

int time = 0;

// top bar
int navHeight = 60;
int backX1 = 30, backY1 = 10, backX2 = 140, backY2 = 50;
boolean navBackActive = false;
int navBackTarget = 0;

// screen 0
String ageText = "";
int age = 21;
boolean ageFocused = false;
int ageBoxW = 145, ageBoxH = 55;
int ageBoxX = screenWidth/2 + 20, ageBoxY = screenHeight/2 - ageBoxH/2;

int continueBoxW = 340, continueBoxH = 52;
int continueBoxX = screenWidth/2 - continueBoxW/2, continueBoxY = 620;
int waitSeconds = 30;

// screen 1
// main menu buttons
String[] menuLabels = {"Fitness", "Stress", "Meditate", "History"};
color[] menuColors = {color(239, 188, 116), color(172, 244, 118),
                      color(130, 206, 242), color(176, 108, 238)};
int[] menuTargets = {2, 4, 8, 10};
int menuX1 = 437, menuX2 = 760;
int menuY = 228, menuH = 84, menuGap = 22;

// screen 2
int graphMode = 0; // 0 = HR, 1 = RR


void settings() {
    size(screenWidth, screenHeight);  
}

void setup () {
  frameRate(10);

  for (String f : dataFields) series.put(f, new ArrayList<Float>());
  String[] ports = Serial.list();
  printArray(ports);
  if (serialPortIndex < ports.length) {
    port = new Serial(this, ports[serialPortIndex], 115200);
    port.clear();
  }

  // fonts
  headerFont = createFont("AveriaSerifLibre-Regular.ttf", 32);
  mainFont  = createFont("ShareTech-Regular.ttf", 20);
}



// read every complete line waiting on the port
void readSerial() {
  if (port == null) return;
  while (port.available() > 0) {
    String line = port.readStringUntil('\n');
    if (line == null) return;
    parseLine(trim(line));
  }
}

void parseLine(String line) {
  if (!line.startsWith("DATA,")) return;
  String[] parts = split(line, ',');
  if (parts.length != dataFields.length + 1) return;

  float[] values = new float[dataFields.length];
  for (int i = 0; i < dataFields.length; i++) {
    try {
      values[i] = Float.parseFloat(parts[i + 1]);
    } catch (NumberFormatException e) {
      return; // drop the whole line if any field is garbled
    }
  }

  for (int i = 0; i < dataFields.length; i++) {
    List<Float> list = series.get(dataFields[i]);
    list.add(values[i]);
    if (list.size() > maxSeriesLength) list.remove(0);
  }
}

float latest(String field) {
  List<Float> list = series.get(field);
  return list.isEmpty() ? 0 : list.get(list.size() - 1);
}

// sample average over second
void collectSample(int bpm, int rpm) {
  bpmSum += bpm;
  rpmSum += rpm;
  sampleCount++;

  if (millis() - lastSecondMs >= 1000) {
    bpms.add(round(bpmSum / float(sampleCount)));
    rpms.add(round(rpmSum / float(sampleCount)));
    bpmSum = 0;
    rpmSum = 0;
    sampleCount = 0;
    lastSecondMs = millis();
  }
}

// draw box style
void drawBox(float x1, float y1, float x2, float y2, color c, String label, float fontSize) {
  float w = x2 - x1;
  float h = y2 - y1;
  float shadow = 6;
  float inset = 3;

  // drop shadow
  noStroke();
  fill(black, 128);
  rect(x1 + shadow, y1 + shadow, w, h);

  // black outline with white edge
  stroke(black);
  strokeWeight(2);
  fill(255);
  rect(x1, y1, w, h);

  // colored inside
  noStroke();
  fill(c);
  rect(x1 + inset, y1 + inset, w - inset*2, h - inset*2);

  float lightness = 0.299 * red(c) + 0.587 * green(c) + 0.114 * blue(c);
  fill(lightness > 150 ? black : color(255));
  textFont(mainFont);
  textSize(fontSize);
  textAlign(CENTER, CENTER);
  text(label, x1 + w/2, y1 + h/2);
}

// draw plain box
void drawPlainBox(float x1, float y1, float x2, float y2, color c, String label, float fontSize) {
  stroke(black);
  strokeWeight(2);
  fill(c);
  rect(x1, y1, x2 - x1, y2 - y1);

  fill(black);
  textFont(mainFont);
  textSize(fontSize);
  textAlign(CENTER, CENTER);
  text(label, (x1 + x2) / 2, (y1 + y2) / 2);
}

// draw top bar
void drawTopBar(int backScreen, String title, String time,
                boolean showNavbar, boolean showBack, boolean showTitle) {
  navBackActive = showNavbar && showBack;
  navBackTarget = backScreen;
  if (!showNavbar) return;

  // bar
  noStroke();
  fill(purple);
  rect(0, 0, width, navHeight);

  // back button
  if (showBack) {
    drawBox(backX1, backY1, backX2, backY2, red, "Back", 26);
  }

  // title
  if (showTitle) {
    fill(darkPurple);
    textFont(headerFont);
    textSize(32);
    textAlign(CENTER, CENTER);
    text(title, width/2, navHeight/2);
  }

  // time
  fill(255);
  textFont(mainFont);
  textSize(26);
  textAlign(RIGHT, CENTER);
  text(time, width - 20, navHeight/2);
}

String clockTime() {
  int h = hour() % 12;
  if (h == 0) h = 12;
  String ampm = hour() < 12 ? "AM" : "PM";
  return h + ":" + nf(minute(), 2) + " " + ampm;
}



// ----- screen 1 -----
void drawAgeBox() {
  // box (thicker border when selected)
  stroke(black);
  strokeWeight(ageFocused ? 3 : 2);
  fill(lightGray);
  rect(ageBoxX, ageBoxY, ageBoxW, ageBoxH);

  // typed text + blinking cursor
  fill(black);
  textAlign(LEFT, CENTER);
  String shown = ageText;
  if (ageFocused && (millis() / 500) % 2 == 0) {
    shown += "|";
  }
  text(shown, ageBoxX + 12, ageBoxY + ageBoxH/2);
}

int secondsWaited() {
  return min(millis() / 1000, waitSeconds);
}

boolean canContinue() {
  return secondsWaited() >= waitSeconds && ageText.length() > 0;
}

void drawConfirmationBox() {
  String label = "Continue";
  if (secondsWaited() < waitSeconds) {
    label = "Continue (Wait " + secondsWaited() + "/" + waitSeconds + "s)";
  }

  if (canContinue()) {
    drawBox(continueBoxX, continueBoxY,
            continueBoxX + continueBoxW, continueBoxY + continueBoxH,
            lightGray, label, 28);
  } else {
    stroke(gray);
    strokeWeight(2);
    fill(lightGray);
    rect(continueBoxX, continueBoxY, continueBoxW, continueBoxH);

    fill(gray);
    textFont(mainFont);
    textSize(28);
    textAlign(CENTER, CENTER);
    text(label, continueBoxX + continueBoxW/2, continueBoxY + continueBoxH/2);
  }
}



// ------ screen 2 ------
void drawMainMenu() {
  for (int i = 0; i < menuLabels.length; i++) {
    float y = menuY + i * (menuH + menuGap);
    drawPlainBox(menuX1, y, menuX2, y + menuH, menuColors[i], menuLabels[i], 52);
  }
}

void drawFitnessGraph(List<Integer> values) {
  for (int i = 0; i < historyTimeframe; i++) {
    color lineColor;
    switch
  }
}



void keyPressed() {
  if (currentScreen == 0) {
    if (!ageFocused) return;

    if ((key == BACKSPACE || key == DELETE) && ageText.length() > 0) {
      ageText = ageText.substring(0, ageText.length() - 1);
    }
    else if (key >= '0' && key <= '9' && ageText.length() < 3) {
      ageText += key;  // digits only, max 3 characters
    }
  }
}



void mousePressed() {
  if (navBackActive && mouseX > backX1 && mouseX < backX2 &&
      mouseY > backY1 && mouseY < backY2) {
    currentScreen = navBackTarget;
    return;
  }

  if (currentScreen == 0) {
    ageFocused = mouseX > ageBoxX && mouseX < ageBoxX + ageBoxW &&
                 mouseY > ageBoxY && mouseY < ageBoxY + ageBoxH;

    boolean onContinue = mouseX > continueBoxX && mouseX < continueBoxX + continueBoxW &&
                         mouseY > continueBoxY && mouseY < continueBoxY + continueBoxH;

    if (onContinue && canContinue()) {
      currentScreen = 1;
      age = Integer.parseInt(ageText);
    }
  }
  else if (currentScreen == 1) {
    for (int i = 0; i < menuLabels.length; i++) {
      float y = menuY + i * (menuH + menuGap);
      if (mouseX > menuX1 && mouseX < menuX2 && mouseY > y && mouseY < y + menuH) {
        currentScreen = menuTargets[i];
      }
    }
  }
}



void drawGrid() {
  // grid
  stroke(245);
  strokeWeight(2);
  for (int x = 0; x <= width; x += 50) {
    line(x, 0, x, height);
  }
  for (int y = gridOffset; y <= height; y += 50) {
    line(0, y, width, y);
  }

  // fade to white toward the bottom
  strokeWeight(1);
  int fadeStart = height / 2;
  for (int y = fadeStart; y < height; y++) {
    float alpha = map(y, fadeStart, height, 0, 255);
    stroke(255, alpha);
    line(0, y, width, y);
  }
  gridOffset = (gridOffset + 1) % 50;

  stroke(0);
}



void draw () {
     fill(0);
     background(255);
     
     readSerial();
     if (port != null) {
       collectSample(round(latest("heartRate")), round(latest("respRate")));
     } else {
       collectSample(int(random(0, 301)), int(random(0, 41)));
     }
     int bpm = bpms.isEmpty() ? 0 : bpms.get(bpms.size() - 1);
     int rpm = rpms.isEmpty() ? 0 : rpms.get(rpms.size() - 1);
     drawGrid();
     
     switch(currentScreen) {
       // input
       case 0:
         // title
         textFont(headerFont);
         textSize(60);
         textAlign(CENTER, CENTER);
         text("Mind Times", width/2, 200);
         
         // textbox
         textFont(mainFont);
         textSize(30);
         textAlign(RIGHT, CENTER);
         text("Enter your age:", width/2 - 10, height/2);
         drawAgeBox();
         drawConfirmationBox();
         break;
  
       // main
       case 1:
         drawTopBar(0, "", clockTime(), false, false, true);
         fill(black);
         textFont(headerFont);
         textSize(60);
         textAlign(CENTER, CENTER);
         text("Mind Time", width/4, height/2);
         
         drawMainMenu();
         break;
         
       // fitness mode
       case 2:
         drawTopBar(1, "Fitness Mode", clockTime(), true, true, true);
         
         
         float fitnessStrain = bpm / float(220 - age);
         String fitnessZoneText = "NO EFFORT";
         color zoneColor = gray;
         if (fitnessStrain > 0.9) { fitnessZoneText = "VERY HARD"; zoneColor = red; }
         else if (fitnessStrain > 0.8) { fitnessZoneText = "HARD"; zoneColor = orange; }
         else if (fitnessStrain > 0.7) { fitnessZoneText = "MODERATE"; zoneColor = yellow; }
         else if (fitnessStrain > 0.6) { fitnessZoneText = "LIGHT"; zoneColor = green; } 
         else if (fitnessStrain > 0.5) { fitnessZoneText = "VERY LIGHT"; zoneColor = blue; }
         
         // Left Side
         drawBox(width/2 - 300, height/2 - 275, width/2 - 100, height/2 - 200, zoneColor, fitnessZoneText, 32);
         textFont(mainFont);
         textSize(25);
         textAlign(LEFT, CENTER);
         fill(red);
         text("VERY HARD", width/8 + 20, height - 500);
         fill(black);
         text(fitnessZoneTimes[5], width/8 + 150, height - 500);
         fill(orange);
         text("HARD", width/8 + 20, height - 460);
         fill(black);
         text(fitnessZoneTimes[4], width/8 + 150, height - 460);
         fill(yellow);
         text("MODERATE", width/8 + 20, height - 420);
         fill(black);
         text(fitnessZoneTimes[3], width/8 + 150, height - 420);
         fill(green);
         text("LIGHT", width/8 + 20, height - 380);
         fill(black);
         text(fitnessZoneTimes[2], width/8 + 150, height - 380);
         fill(blue);
         text("VERY LIGHT", width/8 + 20, height - 340);
         fill(black);
         text(fitnessZoneTimes[2], width/8 + 150, height - 340);
         fill(gray);
         text("NO EFFORT", width/8 + 20, height - 300);
         fill(black);
         text(fitnessZoneTimes[2], width/8 + 150, height - 300);
         
         drawBox(width/2 - 325, height/2 + 200, width/2 - 200, height/2 + 250, gray, Integer.toString(bpm) + " BPM", 20);
         drawBox(width/2 - 175, height/2 + 200, width/2 - 50, height/2 + 250, gray, Integer.toString(rpm) + " RPM", 20);
         drawBox(width/2 - 325, height/2 + 275, width/2 - 200, height/2 + 325, gray, "Beat Interval", 20);
         drawBox(width/2 - 175, height/2 + 275, width/2 - 50, height/2 + 325, gray, "SpO2", 20);
         
         // Right
         fill(255);
         rect(width/2, 60, width/2, height-60);
         fill(0);
         rect(width/2 - 1, 60, 2, height-60);
         
     }
}
