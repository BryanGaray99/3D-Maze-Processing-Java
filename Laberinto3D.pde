// -------------------
// Laberinto3D.pde
// -------------------
boolean hasWon = false;

void setup() {
  size(600, 600, P3D);
  noSmooth();

  // Generar laberinto
  setupMaze();

  // IMPORTANTE: Inicializa la posición del jugador 
  // después de generar el laberinto, para que no sea null:
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
