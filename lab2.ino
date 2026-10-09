/*
  BME/CS 479 - Lab 2
  Heart Rate + Respiratory Rate Chest Strap

  AD8232 ECG:
    OUTPUT -> A0
    LO+    -> D10
    LO-    -> D11

  FSR voltage divider:
    Output -> A1

  Serial output:
  DATA,time,ecgRaw,ecgFiltered,fsrRaw,fsrFiltered,
       heartRate,respRate,inhaleTime,exhaleTime
*/

#include <math.h>

// ======================================================
// PINS
// ======================================================

const int ECG_PIN = A0;
const int FSR_PIN = A1;

const int LO_PLUS_PIN  = 10;
const int LO_MINUS_PIN = 11;


// ======================================================
// SAMPLING
// ======================================================

// 10 samples per second
const unsigned long SAMPLE_PERIOD = 100;

unsigned long lastSampleTime = 0;


// ======================================================
// ECG VARIABLES
// ======================================================

float ecgBaseline = 0.0;
float ecgFiltered = 0.0;

float ecgEnvelope = 0.0;

float previousECGAbs = 0.0;
float previousPreviousECGAbs = 0.0;

unsigned long lastBeatTime = 0;

float heartRate = 0.0;


// Prevent detecting the same R peak more than once
const unsigned long ECG_REFRACTORY = 500;


// ======================================================
// RESPIRATION VARIABLES
// ======================================================

float fsrFiltered = 0.0;
float respirationBaseline = 0.0;
float respirationAmplitude = 0.0;

float respiratoryRate = 0.0;

float inhaleTime = 0.0;
float exhaleTime = 0.0;


// If your FSR signal moves in the opposite direction
// during inhalation, change this to false.
const bool FSR_INCREASES_ON_INHALE = true;


// 0 = waiting / negative respiratory phase
// 1 = positive respiratory phase
int respirationState = 0;

// Extremes of the respiration signal within the current phase
float respirationPeak = 0.0;
float respirationValley = 0.0;

unsigned long inhaleStart = 0;
unsigned long exhaleStart = 0;

unsigned long lastBreathTime = 0;


// ======================================================
// SETUP
// ======================================================

void setup() {

  Serial.begin(115200);

  pinMode(LO_PLUS_PIN, INPUT);
  pinMode(LO_MINUS_PIN, INPUT);

  delay(1000);

  // Initialize filters using first measurements
  ecgBaseline = analogRead(ECG_PIN);

  fsrFiltered = analogRead(FSR_PIN);
  respirationBaseline = fsrFiltered;

  Serial.println("Lab 2 - ECG + Respiration Monitor");
}


// ======================================================
// MAIN LOOP
// ======================================================

void loop() {

  unsigned long now = millis();

  if (now - lastSampleTime >= SAMPLE_PERIOD) {

    lastSampleTime = now;

    // ------------------------------------------
    // READ SENSORS
    // ------------------------------------------

    int ecgRaw = analogRead(ECG_PIN);
    int fsrRaw = analogRead(FSR_PIN);


    // ------------------------------------------
    // CHECK ECG ELECTRODES
    // ------------------------------------------

    bool leadsOff =
      digitalRead(LO_PLUS_PIN) ||
      digitalRead(LO_MINUS_PIN);


    // ------------------------------------------
    // ECG PROCESSING
    // ------------------------------------------

    if (!leadsOff) {

      processECG(ecgRaw, now);

    } else {

      heartRate = 0;
    }


    // ------------------------------------------
    // RESPIRATION PROCESSING
    // ------------------------------------------

    processRespiration(fsrRaw, now);


    // ------------------------------------------
    // SEND DATA TO PROCESSING
    // ------------------------------------------

    char ecgF[12], fsrF[12], hr[10], rr[10], inh[10], exh[10], line[96];

    dtostrf(ecgFiltered, 1, 2, ecgF);
    dtostrf(fsrFiltered, 1, 2, fsrF);
    dtostrf(heartRate, 1, 1, hr);
    dtostrf(respiratoryRate, 1, 1, rr);
    dtostrf(inhaleTime, 1, 2, inh);
    dtostrf(exhaleTime, 1, 2, exh);

    snprintf(line, sizeof(line), "DATA,%lu,%d,%s,%d,%s,%s,%s,%s,%s\n",
             now, ecgRaw, ecgF, fsrRaw, fsrF, hr, rr, inh, exh);

    Serial.write((const uint8_t *)line, strlen(line));
  }
}


// ======================================================
// ECG PROCESSING
// ======================================================

void processECG(int rawECG, unsigned long now) {

  /*
     STEP 1
     Slowly estimate the ECG baseline.

     This removes slow DC drift and movement of
     the signal around its center.
  */

  const float BASELINE_ALPHA = 0.01;

  ecgBaseline =
    ecgBaseline +
    BASELINE_ALPHA * (rawECG - ecgBaseline);


  /*
     STEP 2
     Remove baseline.
  */

  float ecgHighPass =
    rawECG - ecgBaseline;


  /*
     STEP 3
     Low-pass smoothing.

     Reduces high-frequency noise.
  */

  const float ECG_ALPHA = 0.25;

  ecgFiltered =
    ecgFiltered +
    ECG_ALPHA * (ecgHighPass - ecgFiltered);


  /*
     R peaks may be positive or negative depending
     on electrode orientation.

     Using absolute value allows detection in
     either orientation.
  */

  float ecgAbs = fabs(ecgFiltered);


  /*
     Adaptive envelope used to determine
     the peak detection threshold.
  */

  const float ENVELOPE_ALPHA = 0.02;

  ecgEnvelope =
    ecgEnvelope +
    ENVELOPE_ALPHA * (ecgAbs - ecgEnvelope);


  float threshold = ecgEnvelope * 1.8;

  if (threshold < 8.0)
    threshold = 8.0;


  /*
     Detect a local maximum.

          previous ECG
              /\
             /  \

     The center sample must be larger than
     the samples before and after it.
  */

  bool localPeak =
    (previousECGAbs > previousPreviousECGAbs) &&
    (previousECGAbs > ecgAbs) &&
    (previousECGAbs > threshold);


  if (localPeak) {

    if (now - lastBeatTime > ECG_REFRACTORY) {

      if (lastBeatTime != 0) {

        unsigned long beatInterval =
          now - lastBeatTime;

        /*
          Reject impossible intervals.

          300 ms ≈ 200 BPM
          1500 ms ≈ 40 BPM
        */

        if (beatInterval >= 300 &&
            beatInterval <= 1500) {

          float newHR =
            60000.0 / beatInterval;


          // Smooth HR slightly
          if (heartRate == 0) {

            heartRate = newHR;

          } else {

            heartRate =
              0.8 * heartRate +
              0.2 * newHR;
          }
        }
      }

      lastBeatTime = now;
    }
  }


  previousPreviousECGAbs =
    previousECGAbs;

  previousECGAbs =
    ecgAbs;
}


// ======================================================
// RESPIRATION PROCESSING
// ======================================================

void processRespiration(int rawFSR,
                        unsigned long now) {

  /*
     STEP 1
     Smooth FSR signal.

     Respiration is very slow compared with ECG,
     therefore strong smoothing is acceptable.
  */

  const float FSR_ALPHA = 0.08;

  fsrFiltered =
    fsrFiltered +
    FSR_ALPHA * (rawFSR - fsrFiltered);


  /*
     STEP 2
     Estimate slow baseline.
  */

  const float RESP_BASELINE_ALPHA = 0.001;

  respirationBaseline =
    respirationBaseline +
    RESP_BASELINE_ALPHA *
    (fsrFiltered - respirationBaseline);


  /*
     Remove baseline.
  */

  float respirationSignal =
    fsrFiltered - respirationBaseline;


  /*
     Reverse signal if inhalation causes the
     FSR value to decrease instead of increase.
  */

  if (!FSR_INCREASES_ON_INHALE) {

    respirationSignal =
      -respirationSignal;
  }


  /*
     STEP 3
     Estimate respiratory signal amplitude.

     Used to create an adaptive threshold.
  */

  const float AMP_ALPHA = 0.01;

  respirationAmplitude =
    respirationAmplitude +
    AMP_ALPHA *
    (fabs(respirationSignal)
     - respirationAmplitude);


  float threshold =
    respirationAmplitude * 0.8;

  if (threshold < 2.0)
    threshold = 2.0;


  // ====================================================
  // INHALATION START
  // ====================================================

  if (respirationState == 0) {
    respirationValley = min(respirationValley, respirationSignal);
  } else {
    respirationPeak = max(respirationPeak, respirationSignal);
  }

  if (respirationState == 0 &&
      respirationSignal > respirationValley + threshold) {

    respirationState = 1;
    respirationPeak = respirationSignal;

    inhaleStart = now;


    /*
       Previous exhalation ends here.
    */

    if (exhaleStart != 0) {

      exhaleTime =
        (now - exhaleStart) / 1000.0;
    }


    /*
       A new inhalation marks the beginning
       of another breathing cycle.
    */

    if (lastBreathTime != 0) {

      unsigned long breathPeriod =
        now - lastBreathTime;


      /*
         Accept respiratory rates roughly
         between 5 and 40 breaths/min.
      */

      if (breathPeriod >= 1500 &&
          breathPeriod <= 12000) {

        float newRespRate =
          60000.0 / breathPeriod;


        if (respiratoryRate == 0) {

          respiratoryRate =
            newRespRate;

        } else {

          respiratoryRate =
            0.8 * respiratoryRate +
            0.2 * newRespRate;
        }
      }
    }

    lastBreathTime = now;
  }


  // ====================================================
  // EXHALATION START
  // ====================================================

  if (respirationState == 1 &&
      respirationSignal < respirationPeak - threshold) {

    respirationState = 0;
    respirationValley = respirationSignal;

    exhaleStart = now;


    if (inhaleStart != 0) {

      inhaleTime =
        (now - inhaleStart) / 1000.0;
    }
  }
}