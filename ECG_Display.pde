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
import processing.sound.*;
import java.util.Locale;

// ----- SERIAL ------
// DATA,time,ecgRaw,ecgFiltered,fsrRaw,fsrFiltered,heartRate,respRate,inhaleTime,exhaleTime

String[] dataFields = {
  "time",
  "ecgRaw",
  "ecgFiltered",
  "fsrRaw",
  "fsrFiltered",
  "heartRate",
  "respRate",
  "inhaleTime",
  "exhaleTime"
};

int serialPortIndex = 0;
int maxSeriesLength = 3000;

Serial port;

Map<String, List<Float>> series =
  new HashMap<>();


// ======================================================
// CONSTS
// ======================================================

String[] screens = {
  "Input + Wait",
  "Main Page",
  "Fitness Mode",
  "Stress Mode - Menu",
  "Stress Mode - Elevating",
  "Stress Mode - Calming",
  "Stress Mode - Result",
  "Meditate Mode",
  "Study Tracker",
  "(unused)",
  "History"
};

int currentScreen = 0;

color[] zoneColors =
  new color[6];

float[] fitnessZoneTimes =
  {0, 0, 0, 0, 0, 0};

float[] zoneRpmTime =
  new float[6];

float[] zoneRpmSum =
  new float[6];

float[] zoneInhaleSum =
  new float[6];

float[] zoneExhaleSum =
  new float[6];

int lastFrameMs = 0;


int screenWidth = 800;
int screenHeight = 800;

int gridOffset = 0;

int historyTimeframe = 30;


PFont headerFont;
PFont mainFont;


// ======================================================
// COLORS
// ======================================================

color black =
  color(0, 0, 0);

color gray =
  color(172, 172, 172);

color lightGray =
  color(236, 236, 236);

color purple =
  color(176, 38, 240);

color darkPurple =
  color(110, 20, 150);

color red =
  color(232, 54, 95);

color orange =
  color(249, 108, 8);

color yellow =
  color(249, 201, 8);

color green =
  color(57, 230, 13);

color blue =
  color(8, 185, 249);


int time = 0;


// ======================================================
// TOP BAR
// ======================================================

int navHeight = 60;

int backX1 = 30;
int backY1 = 10;

int backX2 = 140;
int backY2 = 50;

boolean navBackActive = false;

int navBackTarget = 0;


// ======================================================
// SCREEN 0
// ======================================================

String ageText = "";

int age = 21;

boolean ageFocused = false;

int ageBoxW = 145;
int ageBoxH = 55;

int ageBoxX =
  screenWidth/2 + 20;

int ageBoxY =
  screenHeight/2 -
  ageBoxH/2;


int continueBoxW = 340;
int continueBoxH = 52;

int continueBoxX =
  screenWidth/2 -
  continueBoxW/2;

int continueBoxY = 620;


int waitSeconds = 30;

float restingBpm = 0;

float restingRpm = 0;

boolean restingDone = false;


// ======================================================
// SCREEN 1 - MAIN MENU
// ======================================================

String[] menuLabels = {
  "Fitness",
  "Stress",
  "Meditate",
  "Study Tracker"
};

color[] menuColors = {

  color(239, 188, 116),

  color(172, 244, 118),

  color(130, 206, 242),

  color(245, 220, 120)
};

int[] menuTargets = {
  2,
  3,
  7,
  8
};

int menuX1 = 437;
int menuX2 = 760;

int menuY = 228;

int menuH = 84;

int menuGap = 22;


// ======================================================
// SCREEN 3 - STRESS MENU
// ======================================================

int stressBoxW = 250;
int stressBoxH = 100;

int stressBoxX =
  screenWidth/2 -
  stressBoxW/2;

int calmBoxY = 330;

int elevateBoxY = 460;

int autoBoxY = 590;


// ======================================================
// SCREEN 4 - ELEVATING
// ======================================================

int elevateSeconds = 30;

int elevateStartMs = 0;

int elevateScore = 0;

String elevatePrompt = "";

String elevateQuestion = "";

String[] elevateOptions =
  new String[4];

int elevateAnswer = 0;

int optW = 300;

int optH = 90;

int optGap = 30;

int optX0 =
  screenWidth/2 -
  optW -
  optGap/2;

int optY0 = 480;


String[] wordBank = {

  "HEART",
  "BREATH",
  "PULSE",
  "ENERGY",
  "FOCUS",
  "RHYTHM",
  "MUSCLE",
  "CARDIO",
  "SPRINT",
  "STRESS",
  "BRAIN",
  "SIGNAL",
  "NERVES",
  "OXYGEN"
};


// ======================================================
// SCREEN 5 - CALMING
// ======================================================

int calmSeconds = 30;

int calmStartMs = 0;
SoundFile calmMusic;
PGraphics paint;

int canvasX = 40;

int canvasY = 180;

int canvasW = 720;

int canvasH = 580;

color[] paletteColors;

int paletteIndex = 5;

int paletteSize = 44;

int paletteGap = 16;

int paletteY = 135;

int brushSize = 16;

boolean painting = false;


String[] calmWordBank = {

  "TREE",
  "HOUSE",
  "CAT",
  "DOG",
  "APPLE",
  "BANANA",
  "FLOWER",
  "CAR",
  "COMPUTER",
  "MOUNTAIN"
};

String drawWord = "";


// ======================================================
// SCREEN 6 - RESULT
// ======================================================

List<Float> activityHr =
  new ArrayList<Float>();

List<Float> activityRr =
  new ArrayList<Float>();

int doneBoxW = 220;

int doneBoxH = 80;

int doneBoxX =
  screenWidth/2 -
  doneBoxW/2;

int doneBoxY = 640;


// ======================================================
// SCREEN 7 - MEDITATE
// ======================================================

String[] ratioLabels = {

  "2x",
  "1x",
  "1/2x",
  "1/3x",
  "1/4x"
};


float[] ratioOptions = {

  2,
  1,
  0.5,
  1.0 / 3,
  0.25
};


int ratioChoice = 3;

int fracBoxW = 80;

int fracBoxH = 50;

int fracBoxGap = 15;

int fracBoxY = 670;

int fracBoxX0 =
  screenWidth/2 -
  (
    5 * fracBoxW +
    4 * fracBoxGap
  ) / 2;


float ratioTolerance = 0.5;

int graceBreaths = 3;

int meditateBreaths = 0;

float meditateLastExhale = 0;


// ======================================================
// SCREEN 8 - STUDY TRACKER
// ======================================================

// Alert when HR increases > 15%
float focusHrTolerance = 0.15;

// Alert when RR increases > 20%
float focusRrTolerance = 0.20;


// Time at which abnormal state began
int focusBadStart = -1;


// Must remain elevated for 8 seconds
int focusWarningDelay = 8000;


boolean focusWarning = false;


// Focus score 0 - 100
float focusScore = 100.0;


// ======================================================
// FITNESS
// ======================================================

int graphMode = 0;


// ======================================================
// SETTINGS
// ======================================================

void settings() {

  size(
    screenWidth,
    screenHeight
  );
}


// ======================================================
// SETUP
// ======================================================

void setup() {

  Locale.setDefault(  // makes sure we use US defaults eg. '.' instead of ','
    Locale.US
  );


  frameRate(60);


  zoneColors =
    new color[] {

      gray,
      blue,
      green,
      yellow,
      orange,
      red
    };


  for (
    String f :
    dataFields
    ) {

    series.put(
      f,
      new ArrayList<Float>()
    );
  }


  String[] ports =
    Serial.list();


  printArray(ports);


  if (
    serialPortIndex <
    ports.length
    ) {

    port =
      new Serial(
        this,
        ports[serialPortIndex],
        115200
      );


    port.clear();
  }

  paletteColors = new color[] {red, orange, yellow, green, blue, black, color(255)};
  paint = createGraphics(canvasW, canvasH);

  // fonts
  headerFont = createFont("AveriaSerifLibre-Regular.ttf", 32);
  mainFont  = createFont("ShareTech-Regular.ttf", 20);

  calmMusic = new SoundFile(this, "Calming relaxing music 30 seconds.mp3");
}



// read every complete line waiting on the port
void readSerial() {

  if (
    port == null
    )
    return;


  while (
    port.available() > 0
    ) {


    String line =
      port.readStringUntil('\n');


    if (
      line == null
      )
      return;


    parseLine(
      trim(line)
    );
  }
}


// ======================================================
// RESPIRATORY RATE IN PROCESSING
// ======================================================

float lastInhale = 0;

float lastExhale = 0;

float breathStartMs = -1;

List<Float> recentBreaths =
  new ArrayList<Float>();

int breathsAveraged = 4;

float breathTimeoutMs = 20000;


float computeRespRate(
  float timeMs,
  float inhale,
  float exhale
  ) {


  if (
    inhale != lastInhale
    ) {

    lastInhale =
      inhale;
  }


  if (
    exhale != lastExhale
    ) {


    lastExhale =
      exhale;


    if (
      inhale > 0 &&
      exhale > 0
      ) {


      recentBreaths.add(
        inhale + exhale
      );


      if (
        recentBreaths.size() >
        breathsAveraged
        ) {

        recentBreaths.remove(0);
      }
    }


    breathStartMs =
      timeMs;
  }


  if (
    recentBreaths.isEmpty()
    ||
    breathStartMs < 0
    ) {

    return 0;
  }


  float sum = 0;


  for (
    float b :
    recentBreaths
    ) {

    sum += b;
  }


  float period =
    sum /
    recentBreaths.size();


  float elapsed =
    (
      timeMs -
      breathStartMs
    )
    / 1000.0;


  if (
    elapsed * 1000 >
    breathTimeoutMs
    ) {

    return 0;
  }


  return
    60.0 /
    max(
      period,
      elapsed
    );
}


// ======================================================
// PARSE SERIAL LINE
// ======================================================

void parseLine(
  String line
  ) {


  if (
    !line.startsWith(
      "DATA,"
    )
    ) {

    return;
  }


  String[] parts =
    split(
      line,
      ','
    );


  if (
    parts.length !=
    dataFields.length + 1
    ) {

    return;
  }


  float[] values =
    new float[
      dataFields.length
    ];


  for (
    int i = 0;
    i < dataFields.length;
    i++
    ) {


    try {

      values[i] =
        Float.parseFloat(
          parts[i + 1]
        );

    }

    catch (
      NumberFormatException e
      ) {

      return;
    }
  }


  values[6] =
    computeRespRate(

      values[0],

      values[7],

      values[8]
    );


  for (
    int i = 0;
    i < dataFields.length;
    i++
    ) {


    List<Float> list =
      series.get(
        dataFields[i]
      );


    list.add(
      values[i]
    );


    if (
      list.size() >
      maxSeriesLength
      ) {

      list.remove(0);
    }
  }
}


// ======================================================
// GET LATEST VALUE
// ======================================================

float latest(
  String field
  ) {

  List<Float> list =
    series.get(field);


  return
    list.isEmpty()
    ?
    0
    :
    list.get(
      list.size() - 1
    );
}


// ======================================================
// AVERAGE LAST N SECONDS
// ======================================================

float averageLast(
  String field,
  float seconds
  ) {


  List<Float> times =
    series.get("time");


  List<Float> vals =
    series.get(field);


  if (
    times.isEmpty()
    ) {

    return 0;
  }


  float cutoff =
    times.get(
      times.size() - 1
    )
    -
    seconds * 1000;


  float sum = 0;

  int n = 0;


  for (
    int i =
    times.size() - 1;

    i >= 0 &&
    times.get(i) >= cutoff;

    i--
    ) {


    sum +=
      vals.get(i);


    n++;
  }


  return
    n == 0
    ?
    0
    :
    sum / n;
}


// ======================================================
// DRAW BOX
// ======================================================

void drawBox(
  float x1,
  float y1,
  float x2,
  float y2,
  color c,
  String label,
  float fontSize
  ) {


  float w =
    x2 - x1;


  float h =
    y2 - y1;


  float shadow = 6;

  float inset = 3;


  noStroke();

  fill(
    black,
    128
  );


  rect(
    x1 + shadow,
    y1 + shadow,
    w,
    h
  );


  stroke(black);

  strokeWeight(2);

  fill(255);


  rect(
    x1,
    y1,
    w,
    h
  );


  noStroke();

  fill(c);


  rect(
    x1 + inset,
    y1 + inset,
    w - inset*2,
    h - inset*2
  );


  float lightness =

    0.299 * red(c)
    +
    0.587 * green(c)
    +
    0.114 * blue(c);


  fill(
    lightness > 150
    ?
    black
    :
    color(255)
  );


  textFont(mainFont);

  textSize(fontSize);

  textAlign(
    CENTER,
    CENTER
  );


  text(
    label,
    x1 + w/2,
    y1 + h/2
  );
}


// ======================================================
// DRAW PLAIN BOX
// ======================================================

void drawPlainBox(
  float x1,
  float y1,
  float x2,
  float y2,
  color c,
  String label,
  float fontSize
  ) {


  stroke(black);

  strokeWeight(2);

  fill(c);


  rect(
    x1,
    y1,
    x2 - x1,
    y2 - y1
  );


  fill(black);

  textFont(mainFont);

  textSize(fontSize);

  textAlign(
    CENTER,
    CENTER
  );


  text(
    label,
    (x1 + x2) / 2,
    (y1 + y2) / 2
  );
}


// ======================================================
// TOP BAR
// ======================================================

void drawTopBar(
  int backScreen,
  String title,
  String time,
  boolean showNavbar,
  boolean showBack,
  boolean showTitle
  ) {


  navBackActive =
    showNavbar &&
    showBack;


  navBackTarget =
    backScreen;


  if (
    !showNavbar
    ) {

    return;
  }


  noStroke();

  fill(purple);


  rect(
    0,
    0,
    width,
    navHeight
  );


  if (
    showBack
    ) {


    drawBox(

      backX1,
      backY1,

      backX2,
      backY2,

      red,

      "Back",

      26
    );
  }


  if (
    showTitle
    ) {


    fill(
      darkPurple
    );


    textFont(
      headerFont
    );


    textSize(32);


    textAlign(
      CENTER,
      CENTER
    );


    text(
      title,
      width/2,
      navHeight/2
    );
  }


  fill(255);

  textFont(mainFont);

  textSize(26);

  textAlign(
    RIGHT,
    CENTER
  );


  text(
    time,
    width - 20,
    navHeight/2
  );
}


// ======================================================
// CLOCK
// ======================================================

String clockTime() {

  int h =
    hour() % 12;


  if (
    h == 0
    ) {

    h = 12;
  }


  String ampm =

    hour() < 12
    ?
    "AM"
    :
    "PM";


  return

    h
    + ":"
    + nf(
      minute(),
      2
    )
    + " "
    + ampm;
}


// ======================================================
// AGE BOX
// ======================================================

void drawAgeBox() {

  stroke(black);

  strokeWeight(
    ageFocused
    ?
    3
    :
    2
  );


  fill(lightGray);


  rect(
    ageBoxX,
    ageBoxY,
    ageBoxW,
    ageBoxH
  );


  fill(black);


  textAlign(
    LEFT,
    CENTER
  );


  String shown =
    ageText;


  if (
    ageFocused &&
    (millis() / 500) % 2 == 0
    ) {

    shown += "|";
  }


  text(
    shown,
    ageBoxX + 12,
    ageBoxY + ageBoxH/2
  );
}


int secondsWaited() {

  return
    min(
      millis() / 1000,
      waitSeconds
    );
}


boolean canContinue() {

  return

    secondsWaited()
    >= waitSeconds

    &&

    ageText.length()
    > 0;
}


void drawConfirmationBox() {

  String label =
    "Continue";


  if (
    secondsWaited() <
    waitSeconds
    ) {


    label =

      "Continue (Wait "
      +
      secondsWaited()
      +
      "/"
      +
      waitSeconds
      +
      "s)";
  }


  if (
    canContinue()
    ) {


    drawBox(

      continueBoxX,
      continueBoxY,

      continueBoxX +
      continueBoxW,

      continueBoxY +
      continueBoxH,

      lightGray,

      label,

      28
    );
  }

  else {


    stroke(gray);

    strokeWeight(2);

    fill(lightGray);


    rect(

      continueBoxX,

      continueBoxY,

      continueBoxW,

      continueBoxH
    );


    fill(gray);

    textFont(mainFont);

    textSize(28);

    textAlign(
      CENTER,
      CENTER
    );


    text(

      label,

      continueBoxX +
      continueBoxW/2,

      continueBoxY +
      continueBoxH/2
    );
  }
}


// ======================================================
// MAIN MENU
// ======================================================

void drawMainMenu() {

  for (
    int i = 0;
    i < menuLabels.length;
    i++
    ) {


    float y =

      menuY
      +
      i *
      (
        menuH +
        menuGap
      );


    drawPlainBox(

      menuX1,
      y,

      menuX2,
      y + menuH,

      menuColors[i],

      menuLabels[i],

      52
    );
  }
}


// ======================================================
// FITNESS ZONES
// ======================================================

int zoneOf(
  float bpm
  ) {


  float strain =
    bpm /
    float(
      220 - age
    );


  if (
    strain > 0.9
    )
    return 5;


  if (
    strain > 0.8
    )
    return 4;


  if (
    strain > 0.7
    )
    return 3;


  if (
    strain > 0.6
    )
    return 2;


  if (
    strain > 0.5
    )
    return 1;


  return 0;
}


void resetFitnessStats() {

  for (
    int z = 0;
    z < 6;
    z++
    ) {


    fitnessZoneTimes[z] = 0;

    zoneRpmTime[z] = 0;

    zoneRpmSum[z] = 0;

    zoneInhaleSum[z] = 0;

    zoneExhaleSum[z] = 0;
  }
}


void drawZoneRow(
  String name,
  color c,
  int zone,
  float y
  ) {


  textFont(mainFont);

  textAlign(
    LEFT,
    CENTER
  );


  textSize(22);

  fill(c);


  text(
    name,
    20,
    y
  );


  fill(black);


  text(

    round(
      fitnessZoneTimes[zone]
    )
    +
    "s",

    150,

    y
  );


  textSize(18);


  float t =
    zoneRpmTime[zone];


  if (
    t <= 0
    ) {


    text(
      "-",
      205,
      y
    );


    text(
      "-",
      265,
      y
    );


    text(
      "-",
      325,
      y
    );


    return;
  }


  float delta =

    zoneRpmSum[zone]
    /
    t
    -
    restingRpm;


  text(

    (
      delta >= 0
      ?
      "+"
      :
      ""
    )
    +
    nf(
      delta,
      0,
      1
    ),

    205,

    y
  );


  text(

    nf(
      zoneInhaleSum[zone] / t,
      0,
      1
    )
    +
    "s",

    265,

    y
  );


  text(

    nf(
      zoneExhaleSum[zone] / t,
      0,
      1
    )
    +
    "s",

    325,

    y
  );
}


// ======================================================
// FITNESS GRAPH
// ======================================================

void drawFitnessGraph(
  String field,
  String name,
  String unit,
  float minVal,
  float maxVal,
  float step,
  float panelTop,
  float panelBottom
  ) {


  float labelW = 44;


  float x1 =
    width/2 +
    labelW;


  float x2 =
    width;


  float yTop =
    panelTop + 28;


  float yBottom =
    panelBottom - 14;


  stroke(black);

  strokeWeight(2);

  fill(gray);


  rect(
    width/2,
    panelTop,
    labelW,
    panelBottom -
    panelTop
  );


  fill(black);

  textFont(mainFont);

  textSize(24);

  textAlign(
    CENTER,
    CENTER
  );


  pushMatrix();


  translate(

    width/2 +
    labelW/2,

    (
      panelTop +
      panelBottom
    ) / 2
  );


  rotate(
    -HALF_PI
  );


  text(
    name,
    0,
    0
  );


  popMatrix();


  textFont(mainFont);

  textSize(20);

  textAlign(
    LEFT,
    BOTTOM
  );


  for (
    float v = minVal;
    v <= maxVal;
    v += step
    ) {


    float y =
      map(
        v,
        minVal,
        maxVal,
        yBottom,
        yTop
      );


    stroke(gray);

    strokeWeight(2);


    line(
      x1,
      y,
      x2,
      y
    );


    fill(gray);


    text(

      round(v)
      +
      (
        unit.equals("")
        ?
        ""
        :
        " " + unit
      ),

      x1 + 6,

      y - 4
    );
  }


  List<Float> values =
    series.get(field);


  List<Float> hrs =
    series.get(
      "heartRate"
    );


  if (
    values.size() < 2
    ) {

    return;
  }


  List<Float> times =
    series.get("time");


  float windowMs =
    historyTimeframe *
    1000.0;


  float windowStart =

    max(

      times.get(0),

      times.get(
        times.size() - 1
      )
      -
      windowMs
    );


  strokeWeight(2);


  clip(

    x1,
    panelTop,

    x2 - x1,

    panelBottom -
    panelTop
  );


  for (
    int i = 1;
    i < values.size();
    i++
    ) {


    if (

      times.get(i - 1)
      <
      windowStart

      ||

      times.get(i)
      <
      times.get(i - 1)

      ) {

      continue;
    }


    float xa =

      map(

        times.get(i - 1),

        windowStart,

        windowStart +
        windowMs,

        x1,
        x2
      );


    float xb =

      map(

        times.get(i),

        windowStart,

        windowStart +
        windowMs,

        x1,
        x2
      );


    float ya =

      map(

        values.get(i - 1),

        minVal,
        maxVal,

        yBottom,
        yTop
      );


    float yb =

      map(

        values.get(i),

        minVal,
        maxVal,

        yBottom,
        yTop
      );


    stroke(

      zoneColors[
        zoneOf(
          hrs.get(i)
        )
      ]
    );


    line(
      xa,
      ya,
      xb,
      yb
    );
  }


  noClip();
}
// ======================================================
// AUTOMATIC STRESS MODE
// ======================================================

float stressThreshold = 0.10;


boolean isStressed() {

  float bpm =
    averageLast(
      "heartRate",
      10
    );


  float rpm =
    averageLast(
      "respRate",
      10
    );


  float rise = 0;

  int signals = 0;


  if (
    bpm > 0 &&
    restingBpm > 0
    ) {


    rise +=
      bpm /
      restingBpm
      -
      1;


    signals++;
  }


  if (
    rpm > 0 &&
    restingRpm > 0
    ) {


    rise +=
      rpm /
      restingRpm
      -
      1;


    signals++;
  }


  if (
    signals == 0
    ) {


    return
      bpm > 90
      ||
      rpm > 20;
  }


  return

    rise /
    signals

    >

    stressThreshold;
}


void startAutomatic() {

  if (
    isStressed()
    ) {

    startCalming();
  }

  else {

    startElevating();
  }
}


// ======================================================
// ELEVATING
// ======================================================

void startElevating() {

  activityHr.clear();

  activityRr.clear();

  elevateScore = 0;

  elevateStartMs =
    millis();

  nextQuestion();

  currentScreen = 4;
}


void setOptions(
  String correct,
  List<String> distractors
  ) {


  List<String> all =
    new ArrayList<String>(
      distractors.subList(
        0,
        3
      )
    );


  all.add(
    correct
  );


  Collections.shuffle(
    all
  );


  for (
    int i = 0;
    i < 4;
    i++
    ) {


    elevateOptions[i] =
      all.get(i);
  }


  elevateAnswer =
    all.indexOf(
      correct
    );
}


List<String> numberDistractors(
  int answer,
  int spread
  ) {


  LinkedHashSet<Integer> set =
    new LinkedHashSet<Integer>();


  while (
    set.size() < 3
    ) {


    int d =

      answer
      +
      int(
        random(
          -spread,
          spread + 1
        )
      );


    if (
      d != answer
      ) {

      set.add(d);
    }
  }


  List<String> out =
    new ArrayList<String>();


  for (
    int d :
    set
    ) {


    out.add(
      str(d)
    );
  }


  return out;
}


void nextQuestion() {

  int type =
    int(
      random(3)
    );


  // ----------------------------------------------------
  // MATH
  // ----------------------------------------------------

  if (
    type == 0
    ) {


    int a =
      int(
        random(
          2,
          13
        )
      );


    int b =
      int(
        random(
          2,
          13
        )
      );


    int op =
      int(
        random(3)
      );


    int answer;


    if (
      op == 0
      ) {


      answer =
        a + b;


      elevateQuestion =

        a
        +
        " + "
        +
        b
        +
        " = ?";
    }


    else if (
      op == 1
      ) {


      answer =
        a - b;


      elevateQuestion =

        a
        +
        " - "
        +
        b
        +
        " = ?";
    }


    else {


      answer =
        a * b;


      elevateQuestion =

        a
        +
        " x "
        +
        b
        +
        " = ?";
    }


    elevatePrompt =
      "Solve it";


    setOptions(

      str(answer),

      numberDistractors(
        answer,
        10
      )
    );
  }


  // ----------------------------------------------------
  // WORD SHUFFLE
  // ----------------------------------------------------

  else if (
    type == 1
    ) {


    String word =

      wordBank[
        int(
          random(
            wordBank.length
          )
        )
      ];


    String scrambled =
      word;


    while (
      scrambled.equals(
        word
      )
      ) {


      List<Character> chars =
        new ArrayList<Character>();


      for (
        char c :
        word.toCharArray()
        ) {


        chars.add(c);
      }


      Collections.shuffle(
        chars
      );


      scrambled = "";


      for (
        char c :
        chars
        ) {


        scrambled += c;
      }
    }


    elevatePrompt =
      "Unscramble the word";


    elevateQuestion =
      scrambled;


    LinkedHashSet<String> others =
      new LinkedHashSet<String>();


    while (
      others.size() < 3
      ) {


      String w =

        wordBank[
          int(
            random(
              wordBank.length
            )
          )
        ];


      if (
        !w.equals(
          word
        )
        ) {


        others.add(w);
      }
    }


    setOptions(

      word,

      new ArrayList<String>(
        others
      )
    );
  }


  // ----------------------------------------------------
  // PATTERN
  // ----------------------------------------------------

  else {


    int start =
      int(
        random(
          1,
          10
        )
      );


    int answer;


    if (
      random(1) <
      0.7
      ) {


      int step =
        int(
          random(
            2,
            10
          )
        );


      elevateQuestion =

        start
        +
        ", "
        +
        (start + step)
        +
        ", "
        +
        (start + 2*step)
        +
        ", "
        +
        (start + 3*step)
        +
        ", ?";


      answer =
        start +
        4*step;
    }


    else {


      elevateQuestion =

        start
        +
        ", "
        +
        (start*2)
        +
        ", "
        +
        (start*4)
        +
        ", "
        +
        (start*8)
        +
        ", ?";


      answer =
        start * 16;
    }


    elevatePrompt =
      "What comes next?";


    setOptions(

      str(answer),

      numberDistractors(
        answer,
        12
      )
    );
  }
}


void answerElevating(
  int choice
  ) {


  if (
    choice ==
    elevateAnswer
    ) {


    elevateScore++;
  }


  nextQuestion();
}


void drawElevating() {

  float elapsed =

    (
      millis()
      -
      elevateStartMs
    )
    /
    1000.0;


  float left =

    elevateSeconds
    -
    elapsed;


  if (
    left <= 0
    ) {


    currentScreen = 6;

    return;
  }


  float redAmt =

    constrain(

      map(

        elapsed,

        elevateSeconds * 0.5,

        elevateSeconds,

        0,

        1
      ),

      0,

      1
    );


  noStroke();


  fill(
    255,
    0,
    0,
    redAmt * 70
  );


  rect(
    0,
    0,
    width,
    height
  );


  drawTopBar(

    3,

    "Elevating",

    clockTime(),

    true,

    true,

    true
  );


  textFont(mainFont);

  textSize(30);

  fill(black);

  textAlign(
    LEFT,
    CENTER
  );


  text(

    "Score: "
    +
    elevateScore,

    20,

    navHeight + 30
  );


  fill(

    left <= 10
    ?
    red
    :
    black
  );


  textAlign(
    RIGHT,
    CENTER
  );


  text(

    ceil(left)
    +
    "s",

    width - 20,

    navHeight + 30
  );


  fill(gray);

  textFont(mainFont);

  textSize(26);

  textAlign(
    CENTER,
    CENTER
  );


  text(

    elevatePrompt,

    width/2,

    220
  );


  fill(black);

  textFont(headerFont);

  textSize(64);


  text(

    elevateQuestion,

    width/2,

    320
  );


  for (
    int i = 0;
    i < 4;
    i++
    ) {


    float x =

      optX0
      +
      (i % 2)
      *
      (
        optW +
        optGap
      );


    float y =

      optY0
      +
      (i / 2)
      *
      (
        optH +
        optGap
      );


    drawBox(

      x,
      y,

      x + optW,

      y + optH,

      lightGray,

      elevateOptions[i],

      36
    );
  }
}


// ======================================================
// CALMING
// ======================================================

void startCalming() {

  activityHr.clear();

  activityRr.clear();


  paint.beginDraw();

  paint.background(255);

  paint.endDraw();


  paletteIndex = 5;

  painting = false;
  calmStartMs = millis();
  calmMusic.play();
  currentScreen = 5;


  drawWord =

    calmWordBank[
      int(
        random(
          calmWordBank.length
        )
      )
    ];
}


float paletteX(
  int i
  ) {


  float total =

    paletteColors.length
    *
    paletteSize

    +

    (
      paletteColors.length
      -
      1
    )
    *
    paletteGap;


  return

    (
      width -
      total
    )
    / 2

    +

    paletteSize / 2

    +

    i
    *
    (
      paletteSize +
      paletteGap
    );
}


boolean inCanvas(
  float x,
  float y
  ) {


  return

    x > canvasX

    &&

    x <
    canvasX +
    canvasW

    &&

    y > canvasY

    &&

    y <
    canvasY +
    canvasH;
}


void paintLine(
  float x1,
  float y1,
  float x2,
  float y2
  ) {


  paint.beginDraw();


  paint.stroke(
    paletteColors[
      paletteIndex
    ]
  );


  paint.strokeWeight(
    brushSize
  );


  paint.strokeCap(
    ROUND
  );


  paint.line(

    x1 - canvasX,

    y1 - canvasY,

    x2 - canvasX,

    y2 - canvasY
  );


  paint.endDraw();
}


void drawCalming() {

  float left =

    calmSeconds

    -

    (
      millis()
      -
      calmStartMs
    )
    /
    1000.0;


  if (
    left <= 0
    ) {


    currentScreen = 6;

    return;
  }


  drawTopBar(

    3,

    "Calming",

    clockTime(),

    true,

    true,

    true
  );


  fill(black);

  textFont(headerFont);

  textAlign(
    CENTER,
    CENTER
  );


  text(

    "Draw a "
    +
    drawWord,

    width/2,

    navHeight + 30
  );


  for (
    int i = 0;
    i < paletteColors.length;
    i++
    ) {


    stroke(black);


    strokeWeight(

      i == paletteIndex
      ?
      5
      :
      2
    );


    fill(
      paletteColors[i]
    );


    ellipse(

      paletteX(i),

      paletteY,

      paletteSize,

      paletteSize
    );
  }


  image(

    paint,

    canvasX,

    canvasY
  );


  noFill();

  stroke(black);

  strokeWeight(2);


  rect(

    canvasX,

    canvasY,

    canvasW,

    canvasH
  );
}


// ======================================================
// RESULT
// ======================================================

float avgNonZero(
  List<Float> v,
  int from,
  int to
  ) {


  float sum = 0;

  int n = 0;


  for (

    int i =
    max(
      0,
      from
    );

    i <
    min(
      v.size(),
      to
    );

    i++
    ) {


    if (
      v.get(i) > 0
      ) {


      sum +=
        v.get(i);


      n++;
    }
  }


  return

    n == 0
    ?
    -1
    :
    sum / n;
}


String startToEnd(
  List<Float> v
  ) {


  int edge = 20;


  float a =

    avgNonZero(
      v,
      0,
      edge
    );


  float b =

    avgNonZero(
      v,

      v.size() -
      edge,

      v.size()
    );


  String sa =

    a < 0
    ?
    "--"
    :
    str(
      round(a)
    );


  String sb =

    b < 0
    ?
    "--"
    :
    str(
      round(b)
    );


  return

    sa
    +
    " -> "
    +
    sb;
}


void drawResultLine(
  List<Float> v,
  float maxVal,
  color c
  ) {


  if (
    v.size() < 2
    ) {

    return;
  }


  float yTop = 100;

  float yBottom = 400;


  stroke(c);

  strokeWeight(4);

  noFill();


  beginShape();


  for (
    int i = 0;
    i < v.size();
    i++
    ) {


    vertex(

      map(

        i,

        0,

        v.size() - 1,

        0,

        width
      ),

      map(

        constrain(
          v.get(i),
          0,
          maxVal
        ),

        0,

        maxVal,

        yBottom,

        yTop
      )
    );
  }


  endShape();
}


void drawResult() {

  drawTopBar(

    1,

    "Stress Mode",

    clockTime(),

    true,

    true,

    true
  );


  float yTop = 100;

  float yBottom = 400;


  stroke(gray);

  strokeWeight(2);


  for (
    int i = 0;
    i <= 5;
    i++
    ) {


    float y =

      map(
        i,
        0,
        5,
        yTop,
        yBottom
      );


    line(
      0,
      y,
      width,
      y
    );
  }


  stroke(black);


  line(
    0,
    430,
    width,
    430
  );


  textFont(mainFont);

  textSize(18);


  fill(red);


  textAlign(
    LEFT,
    CENTER
  );


  text(
    "200 BPM",
    8,
    navHeight + 18
  );


  text(
    "0 BPM",
    8,
    415
  );


  fill(blue);


  textAlign(
    RIGHT,
    CENTER
  );


  text(
    "60 RPM",
    width - 8,
    navHeight + 18
  );


  text(
    "0 RPM",
    width - 8,
    415
  );


  drawResultLine(
    activityHr,
    200,
    red
  );


  drawResultLine(
    activityRr,
    60,
    blue
  );


  textFont(mainFont);

  textSize(28);

  textAlign(
    LEFT,
    CENTER
  );


  fill(red);


  text(
    "Heart Rate (BPM):",
    150,
    510
  );


  fill(blue);


  text(
    "Respiratory Rate (RPM):",
    150,
    560
  );


  fill(black);


  textAlign(
    CENTER,
    CENTER
  );


  text(

    startToEnd(
      activityHr
    ),

    600,

    510
  );


  text(

    startToEnd(
      activityRr
    ),

    600,

    560
  );


  drawBox(

    doneBoxX,

    doneBoxY,

    doneBoxX +
    doneBoxW,

    doneBoxY +
    doneBoxH,

    green,

    "DONE",

    36
  );
}


// ======================================================
// MEDITATE
// ======================================================

void resetMeditate() {

  meditateBreaths = 0;


  meditateLastExhale =
    latest(
      "exhaleTime"
    );
}


void drawOrb(
  float cx,
  float cy,
  float d
  ) {


  noStroke();


  color edge =
    color(
      130,
      206,
      242
    );


  color core =
    color(
      205,
      245,
      255
    );


  int steps = 24;


  for (
    int i = 0;
    i < steps;
    i++
    ) {


    float t =

      i
      /
      float(
        steps - 1
      );


    fill(

      lerpColor(
        edge,
        core,
        t
      )
    );


    ellipse(

      cx,

      cy,

      d
      *
      (
        1 -
        0.75 * t
      ),

      d
      *
      (
        1 -
        0.75 * t
      )
    );
  }
}


float breathPosition() {

  List<Float> times =
    series.get(
      "time"
    );


  List<Float> vals =
    series.get(
      "fsrFiltered"
    );


  if (
    times.isEmpty()
    ) {

    return 0.5;
  }


  float cutoff =

    times.get(
      times.size() - 1
    )
    -
    15000;


  float lo =
    Float.MAX_VALUE;


  float hi =
    -Float.MAX_VALUE;


  for (

    int i =
    times.size() - 1;

    i >= 0
    &&
    times.get(i)
    >= cutoff;

    i--
    ) {


    lo =
      min(
        lo,
        vals.get(i)
      );


    hi =
      max(
        hi,
        vals.get(i)
      );
  }


  if (
    hi - lo < 2
    ) {

    return 0.5;
  }


  return

    (
      vals.get(
        vals.size() - 1
      )
      -
      lo
    )

    /

    (
      hi -
      lo
    );
}


void drawMeditate() {

  drawTopBar(

    1,

    "Meditate Mode",

    clockTime(),

    true,

    true,

    true
  );


  float targetRatio =
    ratioOptions[
      ratioChoice
    ];


  float inhale =
    latest(
      "inhaleTime"
    );


  float exhale =
    latest(
      "exhaleTime"
    );


  boolean haveBreath =

    latest(
      "respRate"
    )
    > 0

    &&

    inhale > 0

    &&

    exhale > 0;


  if (
    exhale !=
    meditateLastExhale
    ) {


    meditateLastExhale =
      exhale;


    meditateBreaths++;
  }


  boolean grace =

    meditateBreaths <
    graceBreaths;


  fill(black);

  textFont(headerFont);

  textSize(40);

  textAlign(
    CENTER,
    CENTER
  );


  text(

    "Inhale = "
    +
    ratioLabels[
      ratioChoice
    ]
    +
    " your exhale",

    width/2,

    110
  );


  color c = gray;


  String message =
    "Waiting for a breath...";


  if (
    grace
    ) {


    message =

      "Settle in... "
      +
      meditateBreaths
      +
      "/"
      +
      graceBreaths;
  }


  else if (
    haveBreath
    ) {


    float ratio =
      inhale /
      exhale;


    if (
      ratio >
      targetRatio *
      (
        1 +
        ratioTolerance
      )
      ) {


      c = red;

      message =
        "Inhale too long";
    }


    else if (
      ratio <
      targetRatio *
      (
        1 -
        ratioTolerance
      )
      ) {


      c = red;

      message =
        "Exhale too long";
    }


    else {


      c = green;

      message =
        "Good breathing";
    }
  }


  drawBox(

    width/2 - 130,

    145,

    width/2 + 130,

    195,

    c,

    message,

    26
  );


  noFill();

  stroke(black);

  strokeWeight(2);


  ellipse(

    width/2,

    380,

    300,

    300
  );


  drawOrb(

    width/2,

    380,

    lerp(
      60,
      270,
      breathPosition()
    )
  );


  textFont(mainFont);

  textSize(26);

  fill(black);

  textAlign(
    CENTER,
    CENTER
  );


  if (
    haveBreath &&
    !grace
    ) {


    text(

      "Inhale "
      +
      nf(
        inhale,
        0,
        1
      )
      +
      "s   Exhale "
      +
      nf(
        exhale,
        0,
        1
      )
      +
      "s   ("
      +
      nf(
        inhale / exhale,
        0,
        2
      )
      +
      "x)",

      width/2,

      580
    );
  }


  textSize(20);

  fill(gray);


  text(

    "Inhale compared with exhale:",

    width/2,

    645
  );


  for (
    int i = 0;
    i < ratioOptions.length;
    i++
    ) {


    float x =

      fracBoxX0

      +

      i
      *
      (
        fracBoxW +
        fracBoxGap
      );


    drawBox(

      x,

      fracBoxY,

      x +
      fracBoxW,

      fracBoxY +
      fracBoxH,

      i == ratioChoice
      ?
      green
      :
      lightGray,

      ratioLabels[i],

      26
    );
  }
}
// ======================================================
// STUDY TRACKER
// ======================================================

void resetStudyTracker() {

  focusBadStart = -1;

  focusWarning = false;

  focusScore = 100.0;
}


// ======================================================
// UPDATE STUDY TRACKER
// ======================================================

void updateFocusState() {

  // Average HR over last 10 s
  float hr =
    averageLast(
      "heartRate",
      10
    );


  // Average RR over last 10 s
  float rr =
    averageLast(
      "respRate",
      10
    );


  // Need valid data
  if (
    restingBpm <= 0
    ||
    restingRpm <= 0
    ||
    hr <= 0
    ||
    rr <= 0
    ) {


    focusWarning = false;

    focusBadStart = -1;

    focusScore = 0;

    return;
  }


  // ====================================================
  // SIGNED CHANGE FROM BASELINE
  // ====================================================

  // Example:
  // resting = 70
  // current = 84
  //
  // (84 - 70) / 70 = +0.20 = +20%

  float hrChange =

    (
      hr -
      restingBpm
    )

    /

    restingBpm;


  float rrChange =

    (
      rr -
      restingRpm
    )

    /

    restingRpm;


  // ====================================================
  // PENALTY
  // ====================================================

  float hrPenalty = 0;

  float rrPenalty = 0;


  // IMPORTANT:
  // LOWER HR DOES NOT REDUCE FOCUS SCORE
  //
  // Only HR increases are penalized.

  if (
    hrChange > 0
    ) {


    hrPenalty =

      constrain(

        hrChange
        /
        focusHrTolerance,

        0,

        2
      );
  }


  // LOWER RR ALSO DOES NOT REDUCE SCORE

  if (
    rrChange > 0
    ) {


    rrPenalty =

      constrain(

        rrChange
        /
        focusRrTolerance,

        0,

        2
      );
  }


  // ====================================================
  // FOCUS SCORE
  // ====================================================

  float physiologicalDeviation =

    (
      hrPenalty
      +
      rrPenalty
    )

    /

    2.0;


  focusScore =

    constrain(

      100.0
      -
      physiologicalDeviation
      *
      50.0,

      0,

      100
    );


  // ====================================================
  // ALERT CONDITIONS
  // ====================================================

  // HR must be MORE than 15% above baseline

  boolean hrTooHigh =

    hrChange >
    focusHrTolerance;


  // RR must be MORE than 20% above baseline

  boolean rrTooHigh =

    rrChange >
    focusRrTolerance;


  // Either condition can start the warning timer

  boolean outsideFocusRange =

    hrTooHigh

    ||

    rrTooHigh;


  // ====================================================
  // WARNING TIMER
  // ====================================================

  if (
    outsideFocusRange
    ) {


    if (
      focusBadStart == -1
      ) {


      focusBadStart =
        millis();
    }


    // Alert only if elevated for 8 seconds

    if (

      millis()
      -
      focusBadStart

      >=

      focusWarningDelay

      ) {


      focusWarning =
        true;
    }
  }


  else {


    focusBadStart = -1;

    focusWarning = false;
  }
}


// ======================================================
// DRAW STUDY TRACKER
// ======================================================

void drawStudyTracker() {

  updateFocusState();


  drawTopBar(

    1,

    "Study Tracker",

    clockTime(),

    true,

    true,

    true
  );


  float hr =

    averageLast(
      "heartRate",
      10
    );


  float rr =

    averageLast(
      "respRate",
      10
    );


  // ====================================================
  // TITLE
  // ====================================================

  fill(black);

  textFont(headerFont);

  textSize(42);

  textAlign(
    CENTER,
    CENTER
  );


  text(

    "Study Tracker",

    width/2,

    115
  );


  fill(gray);

  textFont(mainFont);

  textSize(18);


  text(

    "Physiological focus estimate based on HR and breathing",

    width/2,

    155
  );


  // ====================================================
  // HR BOX
  // ====================================================

  drawBox(

    95,

    195,

    385,

    275,

    lightGray,

    "HR  "
    +
    nf(
      hr,
      0,
      1
    )
    +
    " BPM",

    26
  );


  // ====================================================
  // RR BOX
  // ====================================================

  drawBox(

    415,

    195,

    705,

    275,

    lightGray,

    "RR  "
    +
    nf(
      rr,
      0,
      1
    )
    +
    " RPM",

    26
  );


  // ====================================================
  // BASELINE
  // ====================================================

  fill(gray);

  textFont(mainFont);

  textSize(19);

  textAlign(
    CENTER,
    CENTER
  );


  text(

    "Baseline: "
    +
    nf(
      restingBpm,
      0,
      1
    )
    +
    " BPM   |   "
    +
    nf(
      restingRpm,
      0,
      1
    )
    +
    " RPM",

    width/2,

    315
  );


  // ====================================================
  // FOCUS TITLE
  // ====================================================

  fill(black);

  textFont(headerFont);

  textSize(30);


  text(

    "Focus Estimate",

    width/2,

    365
  );


  // ====================================================
  // FOCUS BAR
  // ====================================================

  float barX = 120;

  float barY = 405;

  float barW = 560;

  float barH = 48;


  stroke(black);

  strokeWeight(2);

  fill(lightGray);


  rect(

    barX,

    barY,

    barW,

    barH
  );


  // ====================================================
  // COLOR
  // ====================================================

  color scoreColor;


  if (
    focusScore >= 70
    ) {


    scoreColor =
      green;
  }


  else if (
    focusScore >= 40
    ) {


    scoreColor =
      yellow;
  }


  else {


    scoreColor =
      red;
  }


  // ====================================================
  // SCORE BAR FILL
  // ====================================================

  noStroke();

  fill(
    scoreColor
  );


  rect(

    barX,

    barY,

    map(

      focusScore,

      0,

      100,

      0,

      barW
    ),

    barH
  );


  // ====================================================
  // SCORE NUMBER
  // ====================================================

  fill(black);

  textFont(mainFont);

  textSize(23);

  textAlign(
    CENTER,
    CENTER
  );


  text(

    round(
      focusScore
    )
    +
    "%",

    width/2,

    barY +
    barH/2
  );


  // ====================================================
  // WAITING FOR VALID DATA
  // ====================================================

  if (

    restingBpm <= 0

    ||

    restingRpm <= 0

    ||

    hr <= 0

    ||

    rr <= 0

    ) {


    drawBox(

      150,

      510,

      650,

      590,

      gray,

      "WAITING FOR VALID DATA",

      28
    );


    fill(gray);

    textSize(20);


    text(

      "HR, RR and the resting baseline are required.",

      width/2,

      635
    );
  }


  // ====================================================
  // WARNING
  // ====================================================

  else if (
    focusWarning
    ) {


    // Red pulse effect

    if (

      (millis() / 700)
      %
      2

      == 0

      ) {


      noStroke();


      fill(
        255,
        0,
        0,
        25
      );


      rect(

        0,

        navHeight,

        width,

        height -
        navHeight
      );
    }


    drawBox(

      150,

      500,

      650,

      590,

      red,

      "POSSIBLY OUT OF FOCUS",

      29
    );


    fill(red);

    textFont(mainFont);

    textSize(21);

    textAlign(
      CENTER,
      CENTER
    );


    text(

      "Take a short reset: look away and take 3 slow breaths.",

      width/2,

      635
    );


    fill(gray);

    textSize(17);


    text(

      "HR or RR has remained elevated for more than 8 seconds.",

      width/2,

      675
    );
  }


  // ====================================================
  // STABLE
  // ====================================================

  else {


    drawBox(

      150,

      500,

      650,

      590,

      green,

      "FOCUS STATE STABLE",

      31
    );


    fill(gray);

    textFont(mainFont);

    textSize(20);

    textAlign(
      CENTER,
      CENTER
    );


    text(

      "Heart rate and breathing are not excessively elevated.",

      width/2,

      635
    );
  }


  // ====================================================
  // INFO
  // ====================================================

  fill(gray);

  textFont(mainFont);

  textSize(16);

  textAlign(
    CENTER,
    CENTER
  );


  text(

    "Alert limits: HR +15%   |   RR +20%   |   persistence 8 s",

    width/2,

    735
  );
}


// ======================================================
// KEYBOARD
// ======================================================

void keyPressed() {

  if (
    currentScreen == 0
    ) {


    if (
      !ageFocused
      ) {

      return;
    }


    if (

      (
        key == BACKSPACE
        ||
        key == DELETE
      )

      &&

      ageText.length() > 0

      ) {


      ageText =

        ageText.substring(

          0,

          ageText.length() - 1
        );
    }


    else if (

      key >= '0'

      &&

      key <= '9'

      &&

      ageText.length() < 3

      ) {


      ageText += key;
    }
  }


  else if (

    currentScreen == 4

    &&

    key >= '1'

    &&

    key <= '4'

    ) {


    answerElevating(
      key - '1'
    );
  }
}


// ======================================================
// MOUSE DRAG
// ======================================================

void mouseDragged() {

  if (

    currentScreen == 5

    &&

    painting

    ) {


    paintLine(

      pmouseX,

      pmouseY,

      mouseX,

      mouseY
    );
  }
}


void mouseReleased() {

  painting = false;
}


// ======================================================
// MOUSE PRESSED
// ======================================================

void mousePressed() {


  // ----------------------------------------------------
  // BACK BUTTON
  // ----------------------------------------------------

  if (

    navBackActive

    &&

    mouseX > backX1

    &&

    mouseX < backX2

    &&

    mouseY > backY1

    &&

    mouseY < backY2

    ) {


    currentScreen =
      navBackTarget;


    return;
  }


  // ----------------------------------------------------
  // SCREEN 0
  // ----------------------------------------------------

  if (
    currentScreen == 0
    ) {


    ageFocused =

      mouseX > ageBoxX

      &&

      mouseX <
      ageBoxX +
      ageBoxW

      &&

      mouseY > ageBoxY

      &&

      mouseY <
      ageBoxY +
      ageBoxH;


    boolean onContinue =

      mouseX >
      continueBoxX

      &&

      mouseX <
      continueBoxX +
      continueBoxW

      &&

      mouseY >
      continueBoxY

      &&

      mouseY <
      continueBoxY +
      continueBoxH;


    if (

      onContinue

      &&

      canContinue()

      ) {


      currentScreen = 1;


      age =
        Integer.parseInt(
          ageText
        );
    }
  }


  // ----------------------------------------------------
  // MAIN MENU
  // ----------------------------------------------------

  else if (
    currentScreen == 1
    ) {


    for (
      int i = 0;
      i < menuLabels.length;
      i++
      ) {


      float y =

        menuY

        +

        i
        *
        (
          menuH +
          menuGap
        );


      if (

        mouseX > menuX1

        &&

        mouseX < menuX2

        &&

        mouseY > y

        &&

        mouseY <
        y + menuH

        ) {


        currentScreen =
          menuTargets[i];


        if (
          currentScreen == 2
          ) {


          resetFitnessStats();
        }


        if (
          currentScreen == 7
          ) {


          resetMeditate();
        }


        if (
          currentScreen == 8
          ) {


          resetStudyTracker();
        }
      }
    }
  }


  // ----------------------------------------------------
  // STRESS MENU
  // ----------------------------------------------------

  else if (
    currentScreen == 3
    ) {


    if (

      mouseX >
      stressBoxX

      &&

      mouseX <
      stressBoxX +
      stressBoxW

      ) {


      if (

        mouseY >
        calmBoxY

        &&

        mouseY <
        calmBoxY +
        stressBoxH

        ) {


        startCalming();
      }


      else if (

        mouseY >
        elevateBoxY

        &&

        mouseY <
        elevateBoxY +
        stressBoxH

        ) {


        startElevating();
      }


      else if (

        mouseY >
        autoBoxY

        &&

        mouseY <
        autoBoxY +
        stressBoxH

        ) {


        startAutomatic();
      }
    }
  }


  // ----------------------------------------------------
  // MEDITATE
  // ----------------------------------------------------

  else if (
    currentScreen == 7
    ) {


    for (
      int i = 0;
      i < ratioOptions.length;
      i++
      ) {


      float x =

        fracBoxX0

        +

        i
        *
        (
          fracBoxW +
          fracBoxGap
        );


      if (

        mouseX > x

        &&

        mouseX <
        x + fracBoxW

        &&

        mouseY >
        fracBoxY

        &&

        mouseY <
        fracBoxY +
        fracBoxH

        ) {


        ratioChoice = i;
      }
    }
  }


  // ----------------------------------------------------
  // RESULT DONE BUTTON
  // ----------------------------------------------------

  else if (
    currentScreen == 6
    ) {


    if (

      mouseX >
      doneBoxX

      &&

      mouseX <
      doneBoxX +
      doneBoxW

      &&

      mouseY >
      doneBoxY

      &&

      mouseY <
      doneBoxY +
      doneBoxH

      ) {


      currentScreen = 1;
    }
  }


  // ----------------------------------------------------
  // CALMING PAINT
  // ----------------------------------------------------

  else if (
    currentScreen == 5
    ) {


    for (
      int i = 0;
      i < paletteColors.length;
      i++
      ) {


      if (

        dist(

          mouseX,

          mouseY,

          paletteX(i),

          paletteY
        )

        <

        paletteSize / 2

        ) {


        paletteIndex = i;
      }
    }


    if (
      inCanvas(
        mouseX,
        mouseY
      )
      ) {


      painting = true;


      paintLine(

        mouseX,

        mouseY,

        mouseX,

        mouseY
      );
    }
  }


  // ----------------------------------------------------
  // ELEVATING OPTIONS
  // ----------------------------------------------------

  else if (
    currentScreen == 4
    ) {


    for (
      int i = 0;
      i < 4;
      i++
      ) {


      float x =

        optX0

        +

        (i % 2)
        *
        (
          optW +
          optGap
        );


      float y =

        optY0

        +

        (i / 2)
        *
        (
          optH +
          optGap
        );


      if (

        mouseX > x

        &&

        mouseX <
        x + optW

        &&

        mouseY > y

        &&

        mouseY <
        y + optH

        ) {


        answerElevating(i);

        break;
      }
    }
  }
}


// ======================================================
// GRID
// ======================================================

void drawGrid() {


  stroke(245);

  strokeWeight(2);


  for (
    int x = 0;
    x <= width;
    x += 50
    ) {


    line(
      x,
      0,
      x,
      height
    );
  }


  for (

    int y =
    gridOffset;

    y <= height;

    y += 50
    ) {


    line(
      0,
      y,
      width,
      y
    );
  }


  strokeWeight(1);


  int fadeStart =
    height / 2;


  for (

    int y =
    fadeStart;

    y < height;

    y++
    ) {


    float alpha =

      map(

        y,

        fadeStart,

        height,

        0,

        255
      );


    stroke(
      255,
      alpha
    );


    line(
      0,
      y,
      width,
      y
    );
  }


  gridOffset =

    (
      gridOffset +
      1
    )
    %
    50;


  stroke(0);
}


// ======================================================
// DRAW
// ======================================================

void draw () {
     frameRate(10);
     if (currentScreen != 5 && calmMusic.isPlaying()) calmMusic.stop();
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
         float panelH = (height - navHeight) / 3.0;
         rect(width/2 - 1, navHeight + panelH - 1, width/2, 2);
         rect(width/2 - 1, navHeight + panelH * 2 - 1, width/2, 2);
         drawFitnessGraph("ecgFiltered", "ECG", "", -200, 200, 200, navHeight, navHeight + panelH);
         drawFitnessGraph("heartRate", "BPM", "BPM", 0, 200, 100, navHeight + panelH, navHeight + panelH * 2);
         drawFitnessGraph("respRate", "RPM", "RPM", 0, 45, 15, navHeight + panelH * 2, height);
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


    // ==================================================
    // ELEVATING
    // ==================================================

    case 4:

      drawElevating();

      break;


    // ==================================================
    // CALMING
    // ==================================================

    case 5:

      drawCalming();

      break;


    // ==================================================
    // RESULT
    // ==================================================

    case 6:

      drawResult();

      break;


    // ==================================================
    // MEDITATE
    // ==================================================

    case 7:

      drawMeditate();

      break;


    // ==================================================
    // STUDY TRACKER
    // ==================================================

    case 8:

      drawStudyTracker();

      break;
  }


  lastFrameMs =
    millis();
}
