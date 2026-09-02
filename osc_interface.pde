import oscP5.*;
import netP5.*;

OscP5 oscP5;

int OSC_LISTEN_PORT = 9000;
float PLAY_DEPTH_CM = 140.0;
float SAFETY_WARNING_CM = 50.0;

int SCREEN_W = 800;
int SCREEN_H = 600;

int GRID_ROWS = 3;
int GRID_COLS = 3;
int HOLE_MARGIN_X = 130;
int HOLE_MARGIN_Y = 220;
int HOLE_BOTTOM_MARGIN = 60;

int HOLE_RADIUS = 50;
int MOLE_RADIUS = 42;

int ROUND_LENGTH_S = 60;
float MOLE_LIFETIME_S = 2.0;
int MOLE_SPAWN_MS = 150;
int MOLE_HIT_MS = 650;
int MOLE_MISS_MS = 700;
int MOLE_SQUASH_MS = 140;

color skyTop, skyBottom, groundTop, groundBottom, hillFar, hillNear;
color holeRim, holeRimDark, holeDark, holeCenter, grassTuft;
color moleBase, moleLight, moleDark, moleHitBase, moleHitLight, moleHitDark;
color cursorColor, textColor, textSoft, panelColor, panelBorder;
color starColor, starDark, popupColor, warningColor, timerGood, timerWarn, timerBad;

float[][] holePositions;
float[][][] tuftData;

float depthCm = 0;
float lateralFrac = 0.5;
float frontRaw = -1, leftRaw = -1, rightRaw = -1;
int lastPacketTime = 0;

float avatarX, avatarY;

final int STAGE_TITLE = 0, STAGE_PLAYING = 1, STAGE_GAMEOVER = 2;
int stage = STAGE_TITLE;

int score = 0;
int combo = 0;
int roundStartTime = 0;

Mole mole;
ArrayList<FloatPopup> popups = new ArrayList<FloatPopup>();

int jumpFlashUntil = 0;
int shakeUntil = 0;
int shakeStrength = 0;

PFont fontMain, fontSmall, fontBig, fontTitle, fontPopup;


void setup() {
  size(800, 600);
  oscP5 = new OscP5(this, OSC_LISTEN_PORT);

  setupColors();
  setupHolePositions();
  setupTufts();

  fontMain = createFont("Arial", 24);
  fontSmall = createFont("Arial", 16);
  fontBig = createFont("Arial Bold", 40);
  fontTitle = createFont("Arial Bold", 38);
  fontPopup = createFont("Arial Bold", 22);

  mole = new Mole();
}

void setupColors() {
  skyTop = color(120, 195, 250);
  skyBottom = color(210, 238, 255);
  hillFar = color(163, 205, 150);
  hillNear = color(132, 190, 110);
  groundTop = color(150, 214, 100);
  groundBottom = color(98, 165, 63);

  holeRim = color(94, 68, 42);
  holeRimDark = color(70, 50, 30);
  holeDark = color(40, 28, 20);
  holeCenter = color(20, 14, 10);
  grassTuft = color(86, 156, 60);

  moleBase = color(156, 110, 71);
  moleLight = color(196, 152, 112);
  moleDark = color(118, 80, 49);
  moleHitBase = color(232, 96, 96);
  moleHitLight = color(250, 150, 140);
  moleHitDark = color(185, 60, 60);

  cursorColor = color(220, 30, 30);
  textColor = color(40, 34, 28);
  textSoft = color(90, 80, 70);
  panelColor = color(255, 253, 248);
  panelBorder = color(215, 197, 168);
  starColor = color(255, 215, 60);
  starDark = color(235, 170, 30);
  popupColor = color(255, 200, 40);
  warningColor = color(175, 25, 25);
  timerGood = color(95, 190, 110);
  timerWarn = color(235, 180, 60);
  timerBad = color(210, 70, 60);
}

void setupHolePositions() {
  holePositions = new float[GRID_ROWS * GRID_COLS][2];
  float spacingX = (SCREEN_W - 2 * HOLE_MARGIN_X) / (float)(GRID_COLS - 1);
  float spacingY = (SCREEN_H - HOLE_MARGIN_Y - HOLE_BOTTOM_MARGIN) / (float)(GRID_ROWS - 1);
  int idx = 0;
  for (int row = 0; row < GRID_ROWS; row++) {
    for (int col = 0; col < GRID_COLS; col++) {
      holePositions[idx][0] = HOLE_MARGIN_X + col * spacingX;
      holePositions[idx][1] = HOLE_MARGIN_Y + row * spacingY;
      idx++;
    }
  }
}

void setupTufts() {
  randomSeed(1234);
  tuftData = new float[holePositions.length][6][3];
  for (int h = 0; h < holePositions.length; h++) {
    for (int t = 0; t < 6; t++) {
      tuftData[h][t][0] = random(-1, 1) * (HOLE_RADIUS + 12);
      tuftData[h][t][1] = random(0.2, 0.5) * HOLE_RADIUS;
      tuftData[h][t][2] = random(10, 16);
    }
  }
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
  int now = millis();

  avatarX = constrain(lateralFrac * SCREEN_W, 20, SCREEN_W - 20);
  avatarY = constrain((depthCm / PLAY_DEPTH_CM) * SCREEN_H, 20, SCREEN_H - 20);

  if (stage == STAGE_TITLE) {
    drawTitleScreen(now);
  } else if (stage == STAGE_PLAYING) {
    drawPlaying(now);
  } else {
    drawGameOver(now);
  }
}

void keyPressed() {
  if (key == ' ') {
    if (stage == STAGE_TITLE) {
      startRound();
    } else if (stage == STAGE_PLAYING) {
      trySpaceWhack();
    }
  }
  if ((key == 'r' || key == 'R') && stage == STAGE_GAMEOVER) {
    stage = STAGE_TITLE;
  }
}

void startRound() {
  stage = STAGE_PLAYING;
  roundStartTime = millis();
  score = 0;
  combo = 0;
  mole = new Mole();
  popups.clear();
}

void trySpaceWhack() {
  int now = millis();
  jumpFlashUntil = now + 150;
  if (mole.contains(avatarX, avatarY)) {
    mole.registerHit(now);
    combo++;
    int gained = 1 + (combo >= 5 ? 1 : 0);
    score += gained;
    popups.add(new FloatPopup(mole.x, mole.y, "+" + gained));
    shakeUntil = now + 120;
    shakeStrength = 5;
  }
}

void drawPlaying(int now) {
  float elapsed = (now - roundStartTime) / 1000.0;
  float timeRemaining = ROUND_LENGTH_S - elapsed;

  if (timeRemaining <= 0) {
    stage = STAGE_GAMEOVER;
    return;
  }

  int oldState = mole.state;
  mole.update(now);
  if (oldState != mole.MISSED && mole.state == mole.MISSED) {
    combo = 0;
  }
  if (mole.shouldRemove()) {
    mole = new Mole();
  }

  for (int i = popups.size() - 1; i >= 0; i--) {
    if (popups.get(i).isDead(now)) popups.remove(i);
  }

  pushMatrix();
  if (now < shakeUntil) {
    translate(random(-shakeStrength, shakeStrength), random(-shakeStrength, shakeStrength));
  }

  drawBackground(now);
  drawHoles();
  mole.display(now);
  for (FloatPopup p : popups) p.display(now);

  boolean jumpFlash = now < jumpFlashUntil;
  drawCursor(avatarX, avatarY, jumpFlash);
  drawHUD(timeRemaining);

  if (depthCm > 0 && depthCm < SAFETY_WARNING_CM) {
    drawSafetyWarning();
  }
  popMatrix();

  drawConnectionStatus(now);
}

class Mole {
  final int SPAWNING = 0, IDLE = 1, HIT = 2, MISSED = 3, HIDDEN = 4;
  float x, y;
  int state;
  int spawnTime, stateTime;
  float blinkSeed;
  String missLine;
  String[] missLines = {"Missed me!", "Too slow!", "Ha! Nice try", "Nyeh heh heh"};

  Mole() {
    int idx = int(random(holePositions.length));
    x = holePositions[idx][0];
    y = holePositions[idx][1];
    spawnTime = millis();
    stateTime = spawnTime;
    state = SPAWNING;
    blinkSeed = random(1000);
    missLine = missLines[int(random(missLines.length))];
  }

  float elapsedTotalS(int now) { return (now - spawnTime) / 1000.0; }

  void update(int now) {
    if (state == SPAWNING && now - stateTime >= MOLE_SPAWN_MS) {
      state = IDLE; stateTime = now;
    } else if (state == IDLE && elapsedTotalS(now) >= MOLE_LIFETIME_S) {
      state = MISSED; stateTime = now;
    } else if (state == HIT && now - stateTime >= MOLE_HIT_MS) {
      state = HIDDEN;
    } else if (state == MISSED && now - stateTime >= MOLE_MISS_MS) {
      state = HIDDEN;
    }
  }

  boolean shouldRemove() { return state == HIDDEN; }

  boolean contains(float px, float py) {
    if (state != SPAWNING && state != IDLE) return false;
    return dist(px, py, x, y) <= MOLE_RADIUS;
  }

  void registerHit(int now) {
    state = HIT;
    stateTime = now;
  }

  void display(int now) {
    if (state == HIDDEN) return;

    float rise = 1.0, squashX = 1.0, squashY = 1.0, shakeX = 0;
    color base = moleBase, light = moleLight, dark = moleDark;
    String face = "happy";

    if (state == SPAWNING) {
      float t = constrain((now - stateTime) / (float) MOLE_SPAWN_MS, 0, 1);
      rise = easeOutBack(t);
    } else if (state == IDLE) {
      rise = 1.0;
    } else if (state == HIT) {
      base = moleHitBase; light = moleHitLight; dark = moleHitDark;
      face = "dizzy";
      if (now - stateTime < MOLE_SQUASH_MS) {
        float sp = constrain((now - stateTime) / (float) MOLE_SQUASH_MS, 0, 1);
        squashX = lerp(1.0, 1.35, sin(sp * PI));
        squashY = lerp(1.0, 0.65, sin(sp * PI));
      } else {
        float st = constrain((now - stateTime - MOLE_SQUASH_MS) / (float)(MOLE_HIT_MS - MOLE_SQUASH_MS), 0, 1);
        rise = lerp(1.0, 0.0, easeInQuad(st));
      }
    } else if (state == MISSED) {
      float t = constrain((now - stateTime) / (float) MOLE_MISS_MS, 0, 1);
      face = "taunt";
      if (t < 0.65) {
        float tt = t / 0.65;
        shakeX = sin(tt * 30) * 2.2;
      } else {
        float st = (t - 0.65) / 0.35;
        rise = lerp(1.0, 0.0, easeInQuad(st));
      }
    }

    float bobY = (state == IDLE) ? sin((now - spawnTime) / 260.0) * 2 : 0;
    float bodyY = y - 10 - 15 * rise + bobY;
    float rx = MOLE_RADIUS * squashX;
    float ry = MOLE_RADIUS * squashY;
    float cx = x + shakeX;

    float clipBottom = y + HOLE_RADIUS / 2.0 - 4;
    clip(0, 0, SCREEN_W, clipBottom);

    if (rise > 0.4) {
      float pawY = bodyY + ry * 0.6;
      noStroke();
      fill(base);
      ellipse(cx - rx * 0.7, pawY, 22 * squashX, 16 * squashY);
      ellipse(cx + rx * 0.7, pawY, 22 * squashX, 16 * squashY);
    }

    drawShadedEllipse(cx, bodyY, rx * 2, ry * 2, base, light, dark);

    for (int side = -1; side <= 1; side += 2) {
      float earX = cx + side * rx * 0.55;
      float earY = bodyY - ry * 0.85;
      noStroke();
      fill(base);
      ellipse(earX, earY, rx * 0.4, ry * 0.4);
      fill(205, 150, 140);
      ellipse(earX, earY, rx * 0.18, ry * 0.18);
    }

    drawMoleFace(cx, bodyY, rx, ry, face, now);
    noClip();
  }

  void drawMoleFace(float cx, float bodyY, float rx, float ry, String mode, int now) {
    noFill();
    if (mode.equals("happy")) {
      noStroke();
      fill(60, 40, 30);
      ellipse(cx, bodyY + 12, 12, 12);
      boolean blink = sin((now + blinkSeed) / 900.0) > 0.94;
      stroke(30, 20, 15);
      strokeWeight(2);
      if (blink) {
        line(cx - 26, bodyY - 12, cx - 12, bodyY - 12);
        line(cx + 12, bodyY - 12, cx + 26, bodyY - 12);
      } else {
        noFill();
        arc(cx - 18, bodyY - 12, 16, 12, 0.3, 2.8);
        arc(cx + 18, bodyY - 12, 16, 12, 0.3, 2.8);
      }
    } else if (mode.equals("dizzy")) {
      stroke(60, 20, 20);
      strokeWeight(2);
      for (int side = -1; side <= 1; side += 2) {
        float ex = cx + side * 16, ey = bodyY - 12;
        line(ex - 5, ey - 5, ex + 5, ey + 5);
        line(ex - 5, ey + 5, ex + 5, ey - 5);
      }
      noFill();
      arc(cx, bodyY + 10, 20, 12, 0.3, 2.8);
    } else if (mode.equals("taunt")) {
      noStroke();
      for (int side = -1; side <= 1; side += 2) {
        float ex = cx + side * 15, ey = bodyY - 14;
        fill(255);
        ellipse(ex, ey, 14, 14);
        fill(25, 20, 15);
        ellipse(ex + side * 2, ey + 1, 8, 8);
      }
      stroke(30, 20, 15);
      strokeWeight(2);
      line(cx - 24, bodyY - 24, cx - 8, bodyY - 27);
      line(cx + 8, bodyY - 27, cx + 24, bodyY - 24);
      noStroke();
      fill(60, 40, 30);
      ellipse(cx, bodyY + 10, 12, 12);
      float wag = sin(now / 60.0) * 3;
      fill(220, 90, 110);
      ellipse(cx + wag, bodyY + 22, 16, 14);
    }
    strokeWeight(1);
  }
}

class FloatPopup {
  float x, y;
  String txt;
  int start;
  int lifeMs = 650;
  float rise = 40;

  FloatPopup(float x_, float y_, String t) {
    x = x_; y = y_; txt = t;
    start = millis();
  }

  boolean isDead(int now) { return (now - start) >= lifeMs; }

  void display(int now) {
    float t = constrain((now - start) / (float) lifeMs, 0, 1);
    float yOff = -rise * t;
    int alpha = int(255 * (1 - t));
    textFont(fontPopup);
    fill(red(popupColor), green(popupColor), blue(popupColor), alpha);
    textAlign(CENTER, CENTER);
    text(txt, x, y + yOff);
  }
}

void drawShadedEllipse(float cx, float cy, float w, float h, color base, color light, color dark) {
  noStroke();
  fill(base);
  ellipse(cx, cy, w, h);
  fill(red(dark), green(dark), blue(dark), 80);
  ellipse(cx + w * 0.12, cy + h * 0.14, w * 0.85, h * 0.85);
  fill(red(light), green(light), blue(light), 110);
  ellipse(cx - w * 0.18, cy - h * 0.2, w * 0.5, h * 0.4);
}

float easeOutBack(float t) {
  t = constrain(t, 0, 1);
  float c1 = 1.70158, c3 = c1 + 1;
  return 1 + c3 * pow(t - 1, 3) + c1 * pow(t - 1, 2);
}

float easeInQuad(float t) {
  t = constrain(t, 0, 1);
  return t * t;
}

void drawBackground(int now) {
  int skyHeight = HOLE_MARGIN_Y - 90;
  for (int i = 0; i < skyHeight; i++) {
    float t = i / (float) skyHeight;
    stroke(lerpColor(skyTop, skyBottom, t));
    line(0, i, SCREEN_W, i);
  }

  noStroke();
  for (int i = 6; i > 0; i--) {
    float t = i / 6.0;
    fill(255, 244, 200, (int)(70 * (1 - t) + 6));
    ellipse(SCREEN_W - 90, 100, 85 * 2 * t, 85 * 2 * t);
  }
  fill(255, 236, 160);
  ellipse(SCREEN_W - 90, 100, 84, 84);

  float drift = (now / 40.0) % (SCREEN_W + 200);
  float[] cxs = {150, 400, 620};
  float[] cys = {90, 60, 120};
  fill(255);
  for (int i = 0; i < cxs.length; i++) {
    float cloudX = ((cxs[i] + drift) % (SCREEN_W + 200)) - 100;
    ellipse(cloudX - 20, cys[i] + 5, 36, 36);
    ellipse(cloudX, cys[i] - 5, 44, 44);
    ellipse(cloudX + 22, cys[i] + 5, 36, 36);
  }

  drawHillBand(skyHeight - 6, 10, hillFar, 0.6);
  drawHillBand(skyHeight + 8, 14, hillNear, 2.1);

  int groundH = SCREEN_H - skyHeight;
  for (int i = 0; i < groundH; i++) {
    float t = i / (float) groundH;
    stroke(lerpColor(groundTop, groundBottom, t));
    line(0, skyHeight + i, SCREEN_W, skyHeight + i);
  }
}

void drawHillBand(float baseY, float amplitude, color c, float phase) {
  noStroke();
  fill(c);
  beginShape();
  vertex(0, baseY + 60);
  for (int px = 0; px <= SCREEN_W; px += 30) {
    float py = baseY + sin((px / 140.0) + phase) * amplitude;
    vertex(px, py);
  }
  vertex(SCREEN_W, baseY + 60);
  endShape(CLOSE);
}

void drawHoles() {
  for (int h = 0; h < holePositions.length; h++) {
    float x = holePositions[h][0];
    float y = holePositions[h][1];

    noStroke();
    fill(20, 30, 10, 55);
    ellipse(x, y + 10, HOLE_RADIUS * 2 + 30, HOLE_RADIUS + 30);

    drawShadedEllipse(x, y, HOLE_RADIUS * 2 + 8, HOLE_RADIUS + 6, holeRim, color(170, 130, 90), holeRimDark);

    fill(holeDark);
    ellipse(x, y, HOLE_RADIUS * 2, HOLE_RADIUS);
    fill(holeCenter);
    ellipse(x, y, HOLE_RADIUS * 1.1, HOLE_RADIUS * 0.55);

    stroke(grassTuft);
    strokeWeight(2);
    for (int t = 0; t < 6; t++) {
      float tx = tuftData[h][t][0];
      float ty = tuftData[h][t][1];
      float sz = tuftData[h][t][2];
      float gx = x + tx, gy = y + ty + HOLE_RADIUS / 2.0;
      for (int blade = -1; blade <= 1; blade++) {
        line(gx + blade * 3, gy, gx + blade * 5, gy - sz);
      }
    }
    noStroke();
  }
}

void drawCursor(float px, float py, boolean jumpFlash) {
  float r = 10 + (jumpFlash ? 6 : 0);
  noStroke();
  for (int i = 3; i > 0; i--) {
    float t = i / 3.0;
    fill(red(cursorColor), green(cursorColor), blue(cursorColor), (int)(60 * (1 - t) + 6));
    ellipse(px, py, (r + 10) * 2 * t, (r + 10) * 2 * t);
  }
  fill(cursorColor);
  ellipse(px, py, r * 2, r * 2);
  stroke(255);
  strokeWeight(2);
  noFill();
  ellipse(px, py, r * 2, r * 2);
  noStroke();
}

void drawGlassPanel(float x, float y, float w, float h) {
  noStroke();
  fill(20, 20, 25, 45);
  rect(x - 4, y + 4, w, h, 14);
  fill(255, 253, 248, 235);
  rect(x, y, w, h, 14);
  stroke(panelBorder);
  strokeWeight(2);
  noFill();
  rect(x, y, w, h, 14);
  noStroke();
}

void drawStarIcon(float cx, float cy, float size, color c, color outlineC) {
  fill(c);
  stroke(outlineC);
  strokeWeight(1);
  beginShape();
  for (int i = 0; i < 10; i++) {
    float r = (i % 2 == 0) ? size : size * 0.45;
    float a = radians(-90 + i * 36);
    vertex(cx + r * cos(a), cy + r * sin(a));
  }
  endShape(CLOSE);
  noStroke();
}

void drawHUD(float timeRemaining) {
  float panelY = 20;
  float panelH = 50;
  float sideW = 170;
  float centerW = 340;

  drawGlassPanel(20, panelY, sideW, panelH);
  drawGlassPanel(SCREEN_W / 2.0 - centerW / 2, panelY, centerW, panelH);
  drawGlassPanel(SCREEN_W - sideW - 20, panelY, sideW, panelH);

  drawStarIcon(20 + 26, panelY + panelH / 2, 12, starColor, starDark);
  textFont(fontMain);
  fill(textColor);
  textAlign(LEFT, CENTER);
  text(score, 20 + 44, panelY + panelH / 2);

  textFont(fontSmall);
  textAlign(CENTER, CENTER);
  if (combo >= 2) {
    fill(200, 60, 40);
    text("Combo x" + combo + "!", SCREEN_W / 2.0, panelY + panelH / 2);
  } else {
    fill(textColor);
    text("SPACE to whack (sensor jump TBD)", SCREEN_W / 2.0, panelY + panelH / 2);
  }

  textFont(fontMain);
  fill(textColor);
  textAlign(LEFT, CENTER);
  text(max(0, int(timeRemaining)) + "s", SCREEN_W - sideW - 20 + 40, panelY + panelH / 2);

  float frac = constrain(timeRemaining / (float) ROUND_LENGTH_S, 0, 1);
  float barX = SCREEN_W - sideW - 20 + 14;
  float barY = panelY + panelH - 10;
  float barW = sideW - 28;
  noStroke();
  fill(0, 0, 0, 30);
  rect(barX, barY, barW, 6, 3);
  color barColor = (frac > 0.5) ? lerpColor(timerWarn, timerGood, (frac - 0.5) * 2) : lerpColor(timerBad, timerWarn, frac * 2);
  fill(barColor);
  rect(barX, barY, barW * frac, 6, 3);
}

void drawSafetyWarning() {
  noStroke();
  fill(190, 40, 40, 55);
  rect(0, 0, SCREEN_W, SCREEN_H);

  float pw = 620, ph = 110;
  drawGlassPanel(SCREEN_W / 2.0 - pw / 2, SCREEN_H / 2.0 - ph / 2, pw, ph);
  textFont(fontMain);
  fill(warningColor);
  textAlign(CENTER, CENTER);
  text("WARNING - MOVE AWAY FROM THE SCREEN", SCREEN_W / 2.0, SCREEN_H / 2.0);
}

void drawConnectionStatus(int now) {
  textFont(fontSmall);
  textAlign(LEFT, BASELINE);
  boolean connected = (now - lastPacketTime) < 1000;
  fill(connected ? color(40, 140, 60) : color(180, 40, 40));
  text(connected ? "Python: connected" : "Python: no data - is the script running?", 16, SCREEN_H - 40);
  fill(90, 80, 70);
  text("depth: " + nf(depthCm, 0, 1) + "cm  lateral: " + nf(lateralFrac, 0, 2)
    + "  front/left/right raw: " + nf(frontRaw, 0, 1) + " / " + nf(leftRaw, 0, 1) + " / " + nf(rightRaw, 0, 1),
    16, SCREEN_H - 20);
}

void drawTitleScreen(int now) {
  drawBackground(now);
  drawHoles();

  noStroke();
  fill(255, 255, 255, 70);
  rect(0, 0, SCREEN_W, SCREEN_H);

  float bob = sin(now / 350.0) * 6;
  float midX = SCREEN_W / 2.0;
  float midY = HOLE_MARGIN_Y + (SCREEN_H - HOLE_MARGIN_Y - HOLE_BOTTOM_MARGIN) / (float)(GRID_ROWS - 1) + bob;
  drawShadedEllipse(midX, midY - 20, 62 * 2, 58 * 2, moleBase, moleLight, moleDark);
  fill(60, 40, 30);
  ellipse(midX, midY - 6, 14, 14);
  noFill();
  stroke(30, 20, 15);
  strokeWeight(2);
  arc(midX - 20, midY - 24, 20, 15, 0.3, 2.8);
  arc(midX + 20, midY - 24, 20, 15, 0.3, 2.8);
  noStroke();

  float pw = 480, ph = 100;
  drawGlassPanel(SCREEN_W / 2.0 - pw / 2, 90, pw, ph);
  textFont(fontTitle);
  fill(60, 42, 28);
  textAlign(CENTER, CENTER);
  text("WHACK-A-MOLE", SCREEN_W / 2.0, 90 + ph / 2 - 16);
  textFont(fontSmall);
  fill(textSoft);
  text("ENGG3000 prototype interface", SCREEN_W / 2.0, 90 + ph / 2 + 20);

  int promptAlpha = (int)(150 + 105 * sin(now / 300.0));
  fill(textColor, promptAlpha);
  text("Press SPACE to start", SCREEN_W / 2.0, SCREEN_H - 70);
}

void drawGameOver(int now) {
  drawBackground(now);
  noStroke();
  fill(15, 15, 25, 130);
  rect(0, 0, SCREEN_W, SCREEN_H);

  float pw = 460, ph = 260, px = SCREEN_W / 2.0 - pw / 2, py = 170;
  drawGlassPanel(px, py, pw, ph);

  textFont(fontBig);
  fill(textColor);
  textAlign(CENTER, CENTER);
  text("Time's Up!", SCREEN_W / 2.0, py + 45);

  textFont(fontSmall);
  text("Final Score: " + score, SCREEN_W / 2.0, py + 95);

  int[] thresholds = {8, 18, 30};
  int starsEarned = 0;
  for (int t : thresholds) if (score >= t) starsEarned++;
  for (int i = 0; i < 3; i++) {
    float cx = SCREEN_W / 2.0 - 50 + i * 50;
    float cy = py + 150;
    if (i < starsEarned) drawStarIcon(cx, cy, 20, starColor, starDark);
    else drawStarIcon(cx, cy, 20, color(215, 210, 200), color(180, 175, 165));
  }

  fill(textSoft);
  text("Press R to play again", SCREEN_W / 2.0, py + 210);
}interface
