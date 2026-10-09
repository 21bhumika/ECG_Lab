/******************************************************************************
BME/CS 479 Group 7 - Lab 2 (ECG) - Dominic, Atulya, Luka, Bhumika
******************************************************************************/

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.Collections;
import java.util.LinkedHashSet;
import processing.serial.*;

// ----- SERIAL ------
// DATA,time,ecgRaw,ecgFiltered,fsrRaw,fsrFiltered,heartRate,respRate,inhaleTime,exhaleTime
String[] dataFields = {"time", "ecgRaw", "ecgFiltered", "fsrRaw", "fsrFiltered",
                       "heartRate", "respRate", "inhaleTime", "exhaleTime"};
int serialPortIndex = 2; // index into Serial.list(), check the console output
int maxSeriesLength = 3000; // 30 s at 100 samples/s
Serial port;
Map<String, List<Float>> series = new HashMap<>();

// ----- CONSTS ------
String[] screens = {"Input + Wait", "Main Page", "Fitness Mode", "Stress Mode - Menu", "Stress Mode - Elevating", "Stress Mode - Calming", "Stress Mode - Result", "Meditate Mode", "(unused)", "(unused)", "History"};
int currentScreen = 0;
color[] zoneColors = new color[6];
float[] fitnessZoneTimes = {0, 0, 0, 0, 0, 0}; // seconds in No, VL, L, M, H, VH Zones
float[] zoneRpmTime = new float[6];     // seconds of valid breathing data per zone
float[] zoneRpmSum = new float[6];      // time-weighted sums
float[] zoneInhaleSum = new float[6];
float[] zoneExhaleSum = new float[6];
int lastFrameMs = 0;

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
float restingBpm = 0, restingRpm = 0;
boolean restingDone = false;

// screen 1
// main menu buttons
String[] menuLabels = {"Fitness", "Stress", "Meditate", "History"};
color[] menuColors = {color(239, 188, 116), color(172, 244, 118),
                      color(130, 206, 242), color(176, 108, 238)};
int[] menuTargets = {2, 3, 7, 10};
int menuX1 = 437, menuX2 = 760;
int menuY = 228, menuH = 84, menuGap = 22;

// screen 3
int stressBoxW = 250, stressBoxH = 100;
int stressBoxX = screenWidth/2 - stressBoxW/2;
int calmBoxY = 330, elevateBoxY = 460, autoBoxY = 590;

// screen 4 (elevating game)
int elevateSeconds = 30;
int elevateStartMs = 0;
int elevateScore = 0;
String elevatePrompt = "";
String elevateQuestion = "";
String[] elevateOptions = new String[4];
int elevateAnswer = 0;
int optW = 300, optH = 90, optGap = 30;
int optX0 = screenWidth/2 - optW - optGap/2, optY0 = 480;
String[] wordBank = {"HEART", "BREATH", "PULSE", "ENERGY", "FOCUS", "RHYTHM", "MUSCLE",
                     "CARDIO", "SPRINT", "STRESS", "BRAIN", "SIGNAL", "NERVES", "OXYGEN"};

// screen 5 (calming paint)
int calmSeconds = 30;
int calmStartMs = 0;
PGraphics paint;
int canvasX = 40, canvasY = 180, canvasW = 720, canvasH = 580;
color[] paletteColors;
int paletteIndex = 5; // black
int paletteSize = 44, paletteGap = 16, paletteY = 135;
int brushSize = 16;
boolean painting = false;
String[] calmWordBank = {"TREE", "HOUSE", "CAT", "DOG", "APPLE", "BANANA", "FLOWER", "CAR", "COMPUTER", "MOUNTAIN"};
String drawWord = "";

// screen 6 (result): vitals recorded during the activity
List<Float> activityHr = new ArrayList<Float>();
List<Float> activityRr = new ArrayList<Float>();
int doneBoxW = 220, doneBoxH = 80;
int doneBoxX = screenWidth/2 - doneBoxW/2, doneBoxY = 640;

// screen 7 (meditate)
String[] ratioLabels = {"2x", "1x", "1/2x", "1/3x", "1/4x"};
float[] ratioOptions = {2, 1, 0.5, 1.0 / 3, 0.25}; // target inhale / exhale
int ratioChoice = 3; // default
int fracBoxW = 80, fracBoxH = 50, fracBoxGap = 15, fracBoxY = 670;
int fracBoxX0 = screenWidth/2 - (5 * fracBoxW + 4 * fracBoxGap) / 2;
float ratioTolerance = 0.5;
int graceBreaths = 3;
int meditateBreaths = 0;
float meditateLastExhale = 0;

// screen 2
int graphMode = 0; // 0 = HR, 1 = RR


void settings() {
    size(screenWidth, screenHeight);  
}

void setup () {
  frameRate(60);
  zoneColors = new color[] {gray, blue, green, yellow, orange, red};

  for (String f : dataFields) series.put(f, new ArrayList<Float>());
  String[] ports = Serial.list();
  printArray(ports);
  if (serialPortIndex < ports.length) {
    port = new Serial(this, ports[serialPortIndex], 115200);
    port.clear();
  }

  paletteColors = new color[] {red, orange, yellow, green, blue, black, color(255)};
  paint = createGraphics(canvasW, canvasH);

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

float lastInhale = 0, lastExhale = 0;
float breathStartMs = -1;
List<Float> recentBreaths = new ArrayList<Float>();
int breathsAveraged = 4;
float breathTimeoutMs = 20000;

float computeRespRate(float timeMs, float inhale, float exhale) {
  if (inhale != lastInhale) lastInhale = inhale;
  if (exhale != lastExhale) {
    lastExhale = exhale;
    if (inhale > 0 && exhale > 0) {
      recentBreaths.add(inhale + exhale);
      if (recentBreaths.size() > breathsAveraged) recentBreaths.remove(0);
    }
    breathStartMs = timeMs;
  }
  if (recentBreaths.isEmpty() || breathStartMs < 0) return 0;

  float sum = 0;
  for (float b : recentBreaths) sum += b;
  float period = sum / recentBreaths.size();

  // a breath taking longer than average pulls the rate down smoothly
  float elapsed = (timeMs - breathStartMs) / 1000.0;
  if (elapsed * 1000 > breathTimeoutMs) return 0;
  return 60.0 / max(period, elapsed);
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

  values[6] = computeRespRate(values[0], values[7], values[8]);

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

float averageLast(String field, float seconds) {
  List<Float> times = series.get("time");
  List<Float> vals = series.get(field);
  if (times.isEmpty()) return 0;
  float cutoff = times.get(times.size() - 1) - seconds * 1000;
  float sum = 0;
  int n = 0;
  for (int i = times.size() - 1; i >= 0 && times.get(i) >= cutoff; i--) {
    sum += vals.get(i);
    n++;
  }
  return n == 0 ? 0 : sum / n;
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



// ----- screen 0 -----
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



// ------ screen 1 ------
void drawMainMenu() {
  for (int i = 0; i < menuLabels.length; i++) {
    float y = menuY + i * (menuH + menuGap);
    drawPlainBox(menuX1, y, menuX2, y + menuH, menuColors[i], menuLabels[i], 52);
  }
}

// zone 0-5 (No Effort .. Very Hard) for a heart rate
int zoneOf(float bpm) {
  float strain = bpm / float(220 - age);
  if (strain > 0.9) return 5;
  if (strain > 0.8) return 4;
  if (strain > 0.7) return 3;
  if (strain > 0.6) return 2;
  if (strain > 0.5) return 1;
  return 0;
}

void resetFitnessStats() {
  for (int z = 0; z < 6; z++) {
    fitnessZoneTimes[z] = 0;
    zoneRpmTime[z] = 0;
    zoneRpmSum[z] = 0;
    zoneInhaleSum[z] = 0;
    zoneExhaleSum[z] = 0;
  }
}

void drawZoneRow(String name, color c, int zone, float y) {
  textFont(mainFont);
  textAlign(LEFT, CENTER);
  textSize(22);
  fill(c);
  text(name, 20, y);
  fill(black);
  text(round(fitnessZoneTimes[zone]) + "s", 150, y);

  textSize(18);
  float t = zoneRpmTime[zone];
  if (t <= 0) {
    text("-", 205, y);
    text("-", 265, y);
    text("-", 325, y);
    return;
  }
  float delta = zoneRpmSum[zone] / t - restingRpm;
  text((delta >= 0 ? "+" : "") + nf(delta, 0, 1), 205, y);
  text(nf(zoneInhaleSum[zone] / t, 0, 1) + "s", 265, y);
  text(nf(zoneExhaleSum[zone] / t, 0, 1) + "s", 325, y);
}

void drawFitnessGraph(String field, String name, String unit, float minVal, float maxVal, float step, float panelTop, float panelBottom) {
  float labelW = 44;
  float x1 = width/2 + labelW, x2 = width;
  float yTop = panelTop + 28, yBottom = panelBottom - 14;

  // sideways label box
  stroke(black);
  strokeWeight(2);
  fill(gray);
  rect(width/2, panelTop, labelW, panelBottom - panelTop);
  fill(black);
  textFont(mainFont);
  textSize(24);
  textAlign(CENTER, CENTER);
  pushMatrix();
  translate(width/2 + labelW/2, (panelTop + panelBottom) / 2);
  rotate(-HALF_PI);
  text(name, 0, 0);
  popMatrix();

  // y axis
  textFont(mainFont);
  textSize(20);
  textAlign(LEFT, BOTTOM);
  for (float v = minVal; v <= maxVal; v += step) {
    float y = map(v, minVal, maxVal, yBottom, yTop);
    stroke(gray);
    strokeWeight(2);
    line(x1, y, x2, y);
    fill(gray);
    text(round(v) + (unit.equals("") ? "" : " " + unit), x1 + 6, y - 4);
  }

  List<Float> values = series.get(field);
  List<Float> hrs = series.get("heartRate");
  if (values.size() < 2) return;

  List<Float> times = series.get("time");
  float windowMs = historyTimeframe * 1000.0;
  float windowStart = max(times.get(0), times.get(times.size() - 1) - windowMs);

  strokeWeight(2);
  clip(x1, panelTop, x2 - x1, panelBottom - panelTop);
  for (int i = 1; i < values.size(); i++) {
    if (times.get(i - 1) < windowStart || times.get(i) < times.get(i - 1)) continue;
    float xa = map(times.get(i - 1), windowStart, windowStart + windowMs, x1, x2);
    float xb = map(times.get(i), windowStart, windowStart + windowMs, x1, x2);
    float ya = map(values.get(i - 1), minVal, maxVal, yBottom, yTop);
    float yb = map(values.get(i), minVal, maxVal, yBottom, yTop);
    stroke(zoneColors[zoneOf(hrs.get(i))]);
    line(xa, ya, xb, yb);
  }
  noClip();
}



// ----- automatic mode: stressed -> calming, calm -> elevating -----
float stressThreshold = 0.10;

boolean isStressed() {
  float bpm = averageLast("heartRate", 10);
  float rpm = averageLast("respRate", 10);

  float rise = 0;
  int signals = 0;
  if (bpm > 0 && restingBpm > 0) { rise += bpm / restingBpm - 1; signals++; }
  if (rpm > 0 && restingRpm > 0) { rise += rpm / restingRpm - 1; signals++; }

  if (signals == 0) return bpm > 90 || rpm > 20; // no resting baseline, use typical resting limits
  return rise / signals > stressThreshold;
}

void startAutomatic() {
  if (isStressed()) startCalming();
  else startElevating();
}

// ----- elevating game (screen 4) -----
void startElevating() {
  activityHr.clear();
  activityRr.clear();
  elevateScore = 0;
  elevateStartMs = millis();
  nextQuestion();
  currentScreen = 4;
}

// puts the correct answer at a random slot among the distractors
void setOptions(String correct, List<String> distractors) {
  List<String> all = new ArrayList<String>(distractors.subList(0, 3));
  all.add(correct);
  Collections.shuffle(all);
  for (int i = 0; i < 4; i++) elevateOptions[i] = all.get(i);
  elevateAnswer = all.indexOf(correct);
}

List<String> numberDistractors(int answer, int spread) {
  LinkedHashSet<Integer> set = new LinkedHashSet<Integer>();
  while (set.size() < 3) {
    int d = answer + int(random(-spread, spread + 1));
    if (d != answer) set.add(d);
  }
  List<String> out = new ArrayList<String>();
  for (int d : set) out.add(str(d));
  return out;
}

void nextQuestion() {
  int type = int(random(3));

  // math
  if (type == 0) {
    int a = int(random(2, 13)), b = int(random(2, 13));
    int op = int(random(3));
    int answer;
    if (op == 0) { answer = a + b; elevateQuestion = a + " + " + b + " = ?"; }
    else if (op == 1) { answer = a - b; elevateQuestion = a + " - " + b + " = ?"; }
    else { answer = a * b; elevateQuestion = a + " x " + b + " = ?"; }
    elevatePrompt = "Solve it";
    setOptions(str(answer), numberDistractors(answer, 10));
  }

  // word shuffle
  else if (type == 1) {
    String word = wordBank[int(random(wordBank.length))];
    String scrambled = word;
    while (scrambled.equals(word)) {
      List<Character> chars = new ArrayList<Character>();
      for (char c : word.toCharArray()) chars.add(c);
      Collections.shuffle(chars);
      scrambled = "";
      for (char c : chars) scrambled += c;
    }
    elevatePrompt = "Unscramble the word";
    elevateQuestion = scrambled;
    LinkedHashSet<String> others = new LinkedHashSet<String>();
    while (others.size() < 3) {
      String w = wordBank[int(random(wordBank.length))];
      if (!w.equals(word)) others.add(w);
    }
    setOptions(word, new ArrayList<String>(others));
  }

  // pattern matching (steps)
  else {
    int start = int(random(1, 10));
    int answer;
    if (random(1) < 0.7) {
      int step = int(random(2, 10));
      elevateQuestion = start + ", " + (start + step) + ", " + (start + 2*step) + ", " + (start + 3*step) + ", ?";
      answer = start + 4*step;
    } else {
      elevateQuestion = start + ", " + (start*2) + ", " + (start*4) + ", " + (start*8) + ", ?";
      answer = start * 16;
    }
    elevatePrompt = "What comes next?";
    setOptions(str(answer), numberDistractors(answer, 12));
  }
}

void answerElevating(int choice) {
  if (choice == elevateAnswer) elevateScore++;
  nextQuestion();
}

void drawElevating() {
  float elapsed = (millis() - elevateStartMs) / 1000.0;
  float left = elevateSeconds - elapsed;
  if (left <= 0) {
    currentScreen = 6;
    return;
  }

  // background intesify
  float redAmt = constrain(map(elapsed, elevateSeconds * 0.5, elevateSeconds, 0, 1), 0, 1);
  noStroke();
  fill(255, 0, 0, redAmt * 70);
  rect(0, 0, width, height);

  drawTopBar(3, "Elevating", clockTime(), true, true, true);

  // score (left) and countdown (right), under the navbar
  textFont(mainFont);
  textSize(30);
  fill(black);
  textAlign(LEFT, CENTER);
  text("Score: " + elevateScore, 20, navHeight + 30);
  fill(left <= 10 ? red : black);
  textAlign(RIGHT, CENTER);
  text(ceil(left) + "s", width - 20, navHeight + 30);

  // question
  fill(gray);
  textFont(mainFont);
  textSize(26);
  textAlign(CENTER, CENTER);
  text(elevatePrompt, width/2, 220);
  fill(black);
  textFont(headerFont);
  textSize(64);
  text(elevateQuestion, width/2, 320);

  // 2x2 options
  for (int i = 0; i < 4; i++) {
    float x = optX0 + (i % 2) * (optW + optGap);
    float y = optY0 + (i / 2) * (optH + optGap);
    drawBox(x, y, x + optW, y + optH, lightGray, elevateOptions[i], 36);
  }
}

// ----- calming paint (screen 5) -----
void startCalming() {
  activityHr.clear();
  activityRr.clear();
  paint.beginDraw();
  paint.background(255);
  paint.endDraw();
  paletteIndex = 5;
  painting = false;
  calmStartMs = millis();
  currentScreen = 5;
  drawWord = calmWordBank[int(random(calmWordBank.length))];
}

float paletteX(int i) {
  float total = paletteColors.length * paletteSize + (paletteColors.length - 1) * paletteGap;
  return (width - total) / 2 + paletteSize / 2 + i * (paletteSize + paletteGap);
}

boolean inCanvas(float x, float y) {
  return x > canvasX && x < canvasX + canvasW && y > canvasY && y < canvasY + canvasH;
}

void paintLine(float x1, float y1, float x2, float y2) {
  paint.beginDraw();
  paint.stroke(paletteColors[paletteIndex]);
  paint.strokeWeight(brushSize);
  paint.strokeCap(ROUND);
  paint.line(x1 - canvasX, y1 - canvasY, x2 - canvasX, y2 - canvasY);
  paint.endDraw();
}

void drawCalming() {
  float left = calmSeconds - (millis() - calmStartMs) / 1000.0;
  if (left <= 0) {
    currentScreen = 6;
    return;
  }

  drawTopBar(3, "Calming", clockTime(), true, true, true);

  fill(black);
  textFont(headerFont);
  textAlign(CENTER, CENTER);
  text("Draw a " + drawWord, width/2, navHeight + 30);

  // palette
  for (int i = 0; i < paletteColors.length; i++) {
    stroke(black);
    strokeWeight(i == paletteIndex ? 5 : 2);
    fill(paletteColors[i]);
    ellipse(paletteX(i), paletteY, paletteSize, paletteSize);
  }

  // canvas
  image(paint, canvasX, canvasY);
  noFill();
  stroke(black);
  strokeWeight(2);
  rect(canvasX, canvasY, canvasW, canvasH);
}

// ----- result (screen 6) -----
float avgNonZero(List<Float> v, int from, int to) {
  float sum = 0;
  int n = 0;
  for (int i = max(0, from); i < min(v.size(), to); i++) {
    if (v.get(i) > 0) { sum += v.get(i); n++; }
  }
  return n == 0 ? -1 : sum / n;
}

String startToEnd(List<Float> v) {
  int edge = 20; // ~2 s of frames
  float a = avgNonZero(v, 0, edge);
  float b = avgNonZero(v, v.size() - edge, v.size());
  String sa = a < 0 ? "--" : str(round(a));
  String sb = b < 0 ? "--" : str(round(b));
  return sa + " -> " + sb;
}

void drawResultLine(List<Float> v, float maxVal, color c) {
  if (v.size() < 2) return;
  float yTop = 100, yBottom = 400;
  stroke(c);
  strokeWeight(4);
  noFill();
  beginShape();
  for (int i = 0; i < v.size(); i++) {
    vertex(map(i, 0, v.size() - 1, 0, width), map(constrain(v.get(i), 0, maxVal), 0, maxVal, yBottom, yTop));
  }
  endShape();
}

void drawResult() {
  drawTopBar(1, "Stress Mode", clockTime(), true, true, true);

  float yTop = 100, yBottom = 400;
  stroke(gray);
  strokeWeight(2);
  for (int i = 0; i <= 5; i++) {
    float y = map(i, 0, 5, yTop, yBottom);
    line(0, y, width, y);
  }
  stroke(black);
  line(0, 430, width, 430);

  textFont(mainFont);
  textSize(18);
  fill(red);
  textAlign(LEFT, CENTER);
  text("200 BPM", 8, navHeight + 18);
  text("0 BPM", 8, 415);
  fill(blue);
  textAlign(RIGHT, CENTER);
  text("60 RPM", width - 8, navHeight + 18);
  text("0 RPM", width - 8, 415);

  drawResultLine(activityHr, 200, red);
  drawResultLine(activityRr, 60, blue);

  // start -> end
  textFont(mainFont);
  textSize(28);
  textAlign(LEFT, CENTER);
  fill(red);
  text("Heart Rate (BPM):", 150, 510);
  fill(blue);
  text("Respiratory Rate (RPM):", 150, 560);
  fill(black);
  textAlign(CENTER, CENTER);
  text(startToEnd(activityHr), 600, 510);
  text(startToEnd(activityRr), 600, 560);

  drawBox(doneBoxX, doneBoxY, doneBoxX + doneBoxW, doneBoxY + doneBoxH, green, "DONE", 36);
}

// ----- meditate (screen 7) -----
void resetMeditate() {
  meditateBreaths = 0;
  meditateLastExhale = latest("exhaleTime");
}

void drawOrb(float cx, float cy, float d) {
  noStroke();
  color edge = color(130, 206, 242), core = color(205, 245, 255);
  int steps = 24;
  for (int i = 0; i < steps; i++) {
    float t = i / float(steps - 1);
    fill(lerpColor(edge, core, t));
    ellipse(cx, cy, d * (1 - 0.75 * t), d * (1 - 0.75 * t));
  }
}

// 0..1 chest position from the last 15 s of the filtered FSR
float breathPosition() {
  List<Float> times = series.get("time");
  List<Float> vals = series.get("fsrFiltered");
  if (times.isEmpty()) return 0.5;
  float cutoff = times.get(times.size() - 1) - 15000;
  float lo = Float.MAX_VALUE, hi = -Float.MAX_VALUE;
  for (int i = times.size() - 1; i >= 0 && times.get(i) >= cutoff; i--) {
    lo = min(lo, vals.get(i));
    hi = max(hi, vals.get(i));
  }
  if (hi - lo < 2) return 0.5;
  return (vals.get(vals.size() - 1) - lo) / (hi - lo);
}

void drawMeditate() {
  drawTopBar(1, "Meditate Mode", clockTime(), true, true, true);

  float targetRatio = ratioOptions[ratioChoice];
  float inhale = latest("inhaleTime");
  float exhale = latest("exhaleTime");
  boolean haveBreath = latest("respRate") > 0 && inhale > 0 && exhale > 0;

  // exhaleTime changes when a breath completes
  if (exhale != meditateLastExhale) {
    meditateLastExhale = exhale;
    meditateBreaths++;
  }
  boolean grace = meditateBreaths < graceBreaths;

  fill(black);
  textFont(headerFont);
  textSize(40);
  textAlign(CENTER, CENTER);
  text("Inhale = " + ratioLabels[ratioChoice] + " your exhale", width/2, 110);

  color c = gray;
  String message = "Waiting for a breath...";
  if (grace) {
    message = "Settle in... " + meditateBreaths + "/" + graceBreaths;
  }
  else if (haveBreath) {
    float ratio = inhale / exhale;
    if (ratio > targetRatio * (1 + ratioTolerance)) { c = red; message = "Inhale too long"; }
    else if (ratio < targetRatio * (1 - ratioTolerance)) { c = red; message = "Exhale too long"; }
    else { c = green; message = "Good breathing"; }
  }
  drawBox(width/2 - 130, 145, width/2 + 130, 195, c, message, 26);

  // circle follows your chest
  noFill();
  stroke(black);
  strokeWeight(2);
  ellipse(width/2, 380, 300, 300);
  drawOrb(width/2, 380, lerp(60, 270, breathPosition()));

  textFont(mainFont);
  textSize(26);
  fill(black);
  textAlign(CENTER, CENTER);
  if (haveBreath && !grace) {
    text("Inhale " + nf(inhale, 0, 1) + "s   Exhale " + nf(exhale, 0, 1) + "s   (" + nf(inhale / exhale, 0, 2) + "x)", width/2, 580);
  }

  textSize(20);
  fill(gray);
  text("Inhale compared with exhale:", width/2, 645);
  for (int i = 0; i < ratioOptions.length; i++) {
    float x = fracBoxX0 + i * (fracBoxW + fracBoxGap);
    drawBox(x, fracBoxY, x + fracBoxW, fracBoxY + fracBoxH,
            i == ratioChoice ? green : lightGray, ratioLabels[i], 26);
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
  else if (currentScreen == 4 && key >= '1' && key <= '4') {
    answerElevating(key - '1');
  }
}

void mouseDragged() {
  if (currentScreen == 5 && painting) paintLine(pmouseX, pmouseY, mouseX, mouseY);
}

void mouseReleased() {
  painting = false;
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
        if (currentScreen == 2) resetFitnessStats();
        if (currentScreen == 7) resetMeditate();
      }
    }
  }
  else if (currentScreen == 3) {
    if (mouseX > stressBoxX && mouseX < stressBoxX + stressBoxW) {
      if (mouseY > calmBoxY && mouseY < calmBoxY + stressBoxH) startCalming();
      else if (mouseY > elevateBoxY && mouseY < elevateBoxY + stressBoxH) startElevating();
      else if (mouseY > autoBoxY && mouseY < autoBoxY + stressBoxH) startAutomatic();
    }
  }
  else if (currentScreen == 7) {
    for (int i = 0; i < ratioOptions.length; i++) {
      float x = fracBoxX0 + i * (fracBoxW + fracBoxGap);
      if (mouseX > x && mouseX < x + fracBoxW && mouseY > fracBoxY && mouseY < fracBoxY + fracBoxH) {
        ratioChoice = i;
      }
    }
  }
  else if (currentScreen == 6) {
    if (mouseX > doneBoxX && mouseX < doneBoxX + doneBoxW &&
        mouseY > doneBoxY && mouseY < doneBoxY + doneBoxH) currentScreen = 1;
  }
  else if (currentScreen == 5) {
    for (int i = 0; i < paletteColors.length; i++) {
      if (dist(mouseX, mouseY, paletteX(i), paletteY) < paletteSize / 2) paletteIndex = i;
    }
    if (inCanvas(mouseX, mouseY)) {
      painting = true;
      paintLine(mouseX, mouseY, mouseX, mouseY);
    }
  }
  else if (currentScreen == 4) {
    for (int i = 0; i < 4; i++) {
      float x = optX0 + (i % 2) * (optW + optGap);
      float y = optY0 + (i / 2) * (optH + optGap);
      if (mouseX > x && mouseX < x + optW && mouseY > y && mouseY < y + optH) {
        answerElevating(i);
        break;
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
     frameRate(10);
     fill(0);
     background(255);
     
     if (port != null) readSerial();
     // fakeSerialData(); // TEMP
     int bpm = round(latest("heartRate"));
     int rpm = round(latest("respRate"));
     if (currentScreen == 4 || currentScreen == 5) {
       activityHr.add(latest("heartRate"));
       activityRr.add(latest("respRate"));
     }
     
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

         if (!restingDone && secondsWaited() >= waitSeconds) {
           restingBpm = averageLast("heartRate", waitSeconds);
           restingRpm = averageLast("respRate", waitSeconds);
           restingDone = true;
         }
         if (restingDone) {
           fill(black);
           textFont(mainFont);
           textSize(24);
           textAlign(CENTER, CENTER);
           text("Resting: " + round(restingBpm) + " BPM, " + round(restingRpm) + " RPM", width/2, 540);
         }
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
         int fitnessZone = 0;
         if (fitnessStrain > 0.9) { fitnessZoneText = "VERY HARD"; zoneColor = red; fitnessZone = 5; }
         else if (fitnessStrain > 0.8) { fitnessZoneText = "HARD"; zoneColor = orange; fitnessZone = 4; }
         else if (fitnessStrain > 0.7) { fitnessZoneText = "MODERATE"; zoneColor = yellow; fitnessZone = 3; }
         else if (fitnessStrain > 0.6) { fitnessZoneText = "LIGHT"; zoneColor = green; fitnessZone = 2; }
         else if (fitnessStrain > 0.5) { fitnessZoneText = "VERY LIGHT"; zoneColor = blue; fitnessZone = 1; }
         float dt = (millis() - lastFrameMs) / 1000.0;
         fitnessZoneTimes[fitnessZone] += dt;
         if (rpm > 0 && latest("inhaleTime") > 0 && latest("exhaleTime") > 0) {
           zoneRpmTime[fitnessZone] += dt;
           zoneRpmSum[fitnessZone] += dt * latest("respRate");
           zoneInhaleSum[fitnessZone] += dt * latest("inhaleTime");
           zoneExhaleSum[fitnessZone] += dt * latest("exhaleTime");
         }
         
         // Left Side
         drawBox(width/2 - 300, height/2 - 275, width/2 - 100, height/2 - 200, zoneColor, fitnessZoneText, 32);
         textFont(mainFont);
         textSize(25);
         textAlign(LEFT, CENTER);
         fill(gray);
         textSize(16);
         text("Time", 150, height - 540);
         text("dRPM", 205, height - 540);
         text("In", 265, height - 540);
         text("Ex", 325, height - 540);
         drawZoneRow("VERY HARD", red, 5, height - 500);
         drawZoneRow("HARD", orange, 4, height - 460);
         drawZoneRow("MODERATE", yellow, 3, height - 420);
         drawZoneRow("LIGHT", green, 2, height - 380);
         drawZoneRow("VERY LIGHT", blue, 1, height - 340);
         drawZoneRow("NO EFFORT", gray, 0, height - 300);
         
         drawBox(width/2 - 325, height/2 + 200, width/2 - 200, height/2 + 250, gray, Integer.toString(bpm) + " BPM", 20);
         drawBox(width/2 - 175, height/2 + 200, width/2 - 50, height/2 + 250, gray, Integer.toString(rpm) + " RPM", 20);
         drawBox(width/2 - 325, height/2 + 270, width/2 - 200, height/2 + 320, gray, "Rest " + round(restingBpm) + " BPM", 20);
         drawBox(width/2 - 175, height/2 + 270, width/2 - 50, height/2 + 320, gray, "Rest " + round(restingRpm) + " RPM", 20);
         
         // Right
         fill(255);
         rect(width/2, 60, width/2, height-60);
         fill(0);
         rect(width/2 - 1, 60, 2, height-60);
         float panelH = (height - navHeight) / 2.0;
         rect(width/2 - 1, navHeight + panelH - 1, width/2, 2);
         drawFitnessGraph("heartRate", "BPM", "BPM", 0, 200, 50, navHeight, navHeight + panelH);
         drawFitnessGraph("respRate", "RPM", "RPM", 0, 45, 15, navHeight + panelH, height);
         break;
     
      // stress mode menu
      case 3:
         drawTopBar(1, "Stress Mode", clockTime(), true, true, true);
         fill(black);
         textFont(headerFont);
         textSize(55);
         textAlign(CENTER, CENTER);
         text("Test your stress! Select", width/2, 170);
         text("a mode:", width/2, 250);
         textFont(mainFont);
         textSize(20);
         fill(gray);
         text("Activity takes ~30 seconds", width/2, 750);

         drawBox(stressBoxX, calmBoxY, stressBoxX + stressBoxW, calmBoxY + stressBoxH, blue, "Calming", 40);
         drawBox(stressBoxX, elevateBoxY, stressBoxX + stressBoxW, elevateBoxY + stressBoxH, orange, "Elevating", 40);
         drawBox(stressBoxX, autoBoxY, stressBoxX + stressBoxW, autoBoxY + stressBoxH, green, "Automatic", 40);
         break;

      // stress mode - elevating
      case 4:
         drawElevating();
         break;

      // stress mode - calming
      case 5:
         drawCalming();
         break;

      // meditate mode
      case 7:
         drawMeditate();
         break;

      // stress mode - result
      case 6:
         drawResult();
         break;
     }
     lastFrameMs = millis();
}
