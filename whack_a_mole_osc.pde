/*
  Whack-a-Mole, position driven by Python over OSC.

  Python (sensor_to_processing_osc.py) reads the 3 ESP32 sensors, filters
  and calibrates them, and sends the resulting position here as an OSC
  message. This sketch has no serial code at all - it just listens on the
  network and draws the game.

  SETUP:
    1. In Processing: Sketch > Import Library > Add Library... > search
       "oscP5" (by Andreas Schlegel) > Install. One-time setup.
    2. Run sensor_to_processing_osc.py first (or after - order doesn't
       matter, OSC/UDP has no handshake).
    3. Click Run here.

  Controls: press R to reset the score.
*/

import oscP5.*;
import netP5.*;

OscP5 oscP5;

// ---------------- CONFIG ----------------
float PLAY_WIDTH_CM = 150.0;
float PLAY_DEPTH_CM = 140.0;
int OSC_LISTEN_PORT = 9000;   // must match OSC_PORT in the Python script

int SCREEN_W = 800;
int SCREEN_H = 600;
int GRID = 4;

int MOLE_LIFETIME_MS = 1800;
int MOLE_SPAWN_INTERVAL_MS = 1200;
int MAX_ACTIVE_MOLES = 3;

// ---------------- STATE (received from Python) ----------------
float depthCm = 0;
float lateralFrac = 0.5;
float frontRaw = -1, leftRaw = -1, rightRaw = -1;
int lastPacketTime = 0;

float avatarX, avatarY;

Mole[] moles = new Mole[GRID * GRID];
int lastSpawnTime = 0;
int score = 0;


void setup() {
  size(800, 600);
  oscP5 = new OscP5(this, OSC_LISTEN_PORT);

  for (int i = 0; i < moles.length; i++) {
    moles[i] = new Mole(i);
  }

  textFont(createFont("Arial", 20));
}

void oscEvent(OscMessage msg) {
  if (msg.checkAddrPattern("/avatar")) {
    depthCm = msg.get(0).floatValue();
    lateralFrac = msg.get(1).floatValue();
    frontRaw = msg.get(2).floatValue();
    leftRaw = msg.get(3).floatValue();
    rightRaw = msg.get(4).floatValue();
    lastPacketTime = millis();
  }
}

void draw() {
  background(20);

  avatarX = constrain(lateralFrac * SCREEN_W, 20, SCREEN_W - 20);
  avatarY = constrain((depthCm / PLAY_DEPTH_CM) * SCREEN_H, 20, SCREEN_H - 20);

  drawGrid();
  updateMoles();
  drawMoles();
  checkHit();
  drawAvatar();
  drawHUD();
}

void keyPressed() {
  if (key == 'r' || key == 'R') {
    score = 0;
    for (Mole m : moles) m.deactivate();
  }
}


// ------------------------------------------------------------------
// Moles
// ------------------------------------------------------------------
class Mole {
  int index, row, col;
  boolean active = false;
  int activatedAt = 0;

  Mole(int idx) {
    index = idx;
    row = idx / GRID;
    col = idx % GRID;
  }

  float cellW() { return SCREEN_W / (float) GRID; }
  float cellH() { return SCREEN_H / (float) GRID; }
  float centerX() { return col * cellW() + cellW() / 2; }
  float centerY() { return row * cellH() + cellH() / 2; }

  void activate() {
    active = true;
    activatedAt = millis();
  }

  void deactivate() {
    active = false;
  }
}

void updateMoles() {
  int now = millis();

  for (Mole m : moles) {
    if (m.active && now - m.activatedAt > MOLE_LIFETIME_MS) {
      m.deactivate();
    }
  }

  int activeCount = 0;
  for (Mole m : moles) if (m.active) activeCount++;

  if (activeCount < MAX_ACTIVE_MOLES && now - lastSpawnTime > MOLE_SPAWN_INTERVAL_MS) {
    ArrayList<Integer> free = new ArrayList<Integer>();
    for (int i = 0; i < moles.length; i++) {
      if (!moles[i].active) free.add(i);
    }
    if (free.size() > 0) {
      int pick = free.get(int(random(free.size())));
      moles[pick].activate();
      lastSpawnTime = now;
    }
  }
}

void checkHit() {
  float cellW = SCREEN_W / (float) GRID;
  float cellH = SCREEN_H / (float) GRID;
  int col = constrain(int(avatarX / cellW), 0, GRID - 1);
  int row = constrain(int(avatarY / cellH), 0, GRID - 1);
  int idx = row * GRID + col;

  Mole m = moles[idx];
  if (m.active) {
    m.deactivate();
    score++;
  }
}


// ------------------------------------------------------------------
// Drawing
// ------------------------------------------------------------------
void drawGrid() {
  stroke(60);
  strokeWeight(1);
  float cellW = SCREEN_W / (float) GRID;
  float cellH = SCREEN_H / (float) GRID;
  for (int i = 1; i < GRID; i++) {
    line(i * cellW, 0, i * cellW, SCREEN_H);
    line(0, i * cellH, SCREEN_W, i * cellH);
  }
}

void drawMoles() {
  noStroke();
  int now = millis();
  for (Mole m : moles) {
    if (!m.active) continue;
    int elapsed = now - m.activatedAt;
    float popIn = constrain(elapsed / 150.0, 0, 1);
    float remaining = 1.0 - constrain((elapsed - (MOLE_LIFETIME_MS - 150)) / 150.0, 0, 1);
    float scaleAmt = min(popIn, remaining);
    float r = 45 * scaleAmt;
    fill(101, 67, 33); // brown
    ellipse(m.centerX(), m.centerY(), r * 2, r * 2);
  }
}

void drawAvatar() {
  pushMatrix();
  translate(avatarX, avatarY);
  rotate(radians(-30));
  fill(120);
  noStroke();
  rect(-6, -30, 12, 40, 4);   // handle
  fill(190);
  rect(-20, -40, 40, 18, 4);  // hammer head
  popMatrix();
}

void drawHUD() {
  fill(255);
  textSize(24);
  text("Score: " + score, 20, 36);

  textSize(12);
  boolean connected = (millis() - lastPacketTime) < 1000;
  fill(connected ? color(120, 220, 140) : color(220, 90, 90));
  text(connected ? "Python: connected" : "Python: no data - is the script running?", 20, 540);

  fill(200);
  text("front raw: " + nf(frontRaw, 0, 1) + "  depth: " + nf(depthCm, 0, 1) + " / " + int(PLAY_DEPTH_CM), 20, 560);
  text("left raw: " + nf(leftRaw, 0, 1) + "  right raw: " + nf(rightRaw, 0, 1) + "  lateral: " + nf(lateralFrac, 0, 2), 20, 578);
  text("press R to reset score", 20, 596);
}
