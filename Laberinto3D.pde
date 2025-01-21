// Main File: Laberinto3D.pde

void setup() {
  size(600, 600, P3D);
  noSmooth();

  // Inicializar/generar el laberinto dinámicamente
  setupMaze();
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
  resetPlayer();
  hasWon = false;
}

void setupCamera() {
  float fov = PI / 3.0;
  float aspect = float(width) / float(height);
  float nearClip = 10;
  float farClip = 5000;
  perspective(fov, aspect, nearClip, farClip);
}
