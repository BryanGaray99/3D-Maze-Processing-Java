// -------------------
// Laberinto3D.pde
// -------------------
PImage wallImg;
boolean hasWon = false;

void setup() {
  size(600, 600, P3D);
  wallImg = loadImage("wall-2.jpg");
  noSmooth();

  // Generar laberinto
  setupMaze();
  resetPlayer();
}

void draw() {
  background(50);
  
  setupCamera();
  lights();

  if (!hasWon) {
    updatePlayer();
    checkWinCondition();
  } else {
    displayWinMessage();
  }

  drawMaze();
}

void resetGame() {
  hasWon = false;
  setupMaze(); 
  resetPlayer(); 
}

void setupCamera() {
  float fov = PI / 3.0;
  float aspect = float(width) / float(height);
  float nearClip = 10;
  float farClip = 5000;
  perspective(fov, aspect, nearClip, farClip);
}
