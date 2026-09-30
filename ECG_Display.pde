/******************************************************************************
BME/CS 479 Group 7 - Lab 2 (ECG) - Dominic, Atulya, Luka, Bhumika
******************************************************************************/

// ----- CONSTS ------
String[] screens = {"Input + Wait", "Main Page", "Fitness Mode", "Stress Mode - Menu", "Stress Mode - Elevating", "Stress Mode - Calming", "Stress Mode - Result", "Meditate Mode - Menu", "Meditate Mode - Game", "Meditate Mode - Result"};
int currentScreen = 0;

int screenWidth = 800, screenHeight = 800;

PFont headerFont;
PFont mainFont;

// colors
color black = color(0, 0, 0);
color gray = color(172, 172, 172);
color lightGray = color(236, 236, 236);

int time = 0;

// screen 1
String ageText = "";
boolean ageFocused = false;
int ageBoxW = 145, ageBoxH = 55;
int ageBoxX = screenWidth/2 + 20, ageBoxY = screenHeight/2 - ageBoxH/2;

int continueBoxW = 340, continueBoxH = 52;
int continueBoxX = screenWidth/2 - continueBoxW/2, continueBoxY = 620;
int waitSeconds = 30;


void settings() {
    size(screenWidth, screenHeight);  
}

void setup () {
  frameRate(10);
  
  // fonts
  headerFont = createFont("AveriaSerifLibre-Regular.ttf", 32);
  mainFont  = createFont("ShareTech-Regular.ttf", 20);
}



// draw box style
void drawBox(float x1, float y1, float x2, float y2, color c, String label, float fontSize) {
  float w = x2 - x1;
  float h = y2 - y1;
  float shadow = 6;
  float inset = 3;

  // drop shadow
  noStroke();
  fill(gray);
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
  if (currentScreen == 0) {
    ageFocused = mouseX > ageBoxX && mouseX < ageBoxX + ageBoxW &&
                 mouseY > ageBoxY && mouseY < ageBoxY + ageBoxH;

    boolean onContinue = mouseX > continueBoxX && mouseX < continueBoxX + continueBoxW &&
                         mouseY > continueBoxY && mouseY < continueBoxY + continueBoxH;

    if (onContinue && canContinue()) {
      currentScreen = 1;
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
  for (int y = 0; y <= height; y += 50) {
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

  stroke(0);
}



void draw () {
     fill(0);
     background(255);
     
     int bpm = int(random(0, 101));
     int resp = int(random(0, 101));
     int spo2 = int(random(0, 101));
     drawGrid();
     
     switch(currentScreen) {
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
         
     }
}
