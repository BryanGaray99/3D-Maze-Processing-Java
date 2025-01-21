// File: Player.pde

PVector playerPos = new PVector((1 + 0.5) * cellSize, 25, 0);
PVector lastPlayerPos = new PVector();
float playerAngle = 0;
float playerSpeed = 2.5;
float playerRadius = 10;
boolean hasWon = false;
int winStartTime = 0;
int winDuration = 5000;

// -----------------------------------------------------------------
void updatePlayer() {
  PVector oldPos = playerPos.copy();

  // Rotación de la cámara con Q/E
  if (turnLeft)  playerAngle -= 0.03;
  if (turnRight) playerAngle += 0.03;

  float dirX = sin(playerAngle);
  float dirZ = cos(playerAngle);
  float perpX = cos(playerAngle);
  float perpZ = -sin(playerAngle);

  // Movimiento
  if (up)          { playerPos.x += dirX * playerSpeed;    playerPos.z += dirZ * playerSpeed; }
  if (down)        { playerPos.x -= dirX * playerSpeed;    playerPos.z -= dirZ * playerSpeed; }
  if (strafeLeft)  { playerPos.x += perpX * playerSpeed;   playerPos.z += perpZ * playerSpeed; }
  if (strafeRight) { playerPos.x -= perpX * playerSpeed;   playerPos.z -= perpZ * playerSpeed; }

  // Colisiones
  if (checkCollision()) {
    playerPos = oldPos;
  }

  // Cámara
  camera(playerPos.x, playerPos.y, playerPos.z,
         playerPos.x + dirX * 50, playerPos.y, playerPos.z + dirZ * 50,
         0, 1, 0);
}

// -----------------------------------------------------------------
void resetPlayer() {
  playerPos = new PVector((1 + 0.5) * cellSize, 25, 0);
  playerAngle = 0;
}

// -----------------------------------------------------------------
void checkWinCondition() {
  int col = floor(playerPos.x / cellSize);
  int row = floor(playerPos.z / cellSize);

  if (!playerPos.equals(lastPlayerPos)) {
    // println("Fila="+row+", Col="+col);
    lastPlayerPos = playerPos.copy();
  }

  // Ejemplo: se considera ganar en (row=8, col=9)
  if (row == 8 && col == 9) {
    hasWon = true;
    winStartTime = millis();
  }
}

// -----------------------------------------------------------------
void displayWinMessage() {
  int elapsed = millis() - winStartTime;
  if (elapsed < winDuration) {
    hint(DISABLE_DEPTH_TEST);
    camera(); // Restaurar cámara por defecto para texto 2D
    textAlign(CENTER, CENTER);
    fill(0, 255, 0);
    textSize(48);
    text("¡HAS GANADO!", width / 2, height / 2);
    hint(ENABLE_DEPTH_TEST);
  } else {
    resetGame();
  }
}

// -----------------------------------------------------------------
boolean checkCollision() {
  int col = floor(playerPos.x / cellSize);
  int row = floor(playerPos.z / cellSize);

  // Verifica límites del laberinto
  if (row < 0 || row >= mazeRows || col < 0 || col >= mazeCols) {
    return true; // colisión contra "fuera de rango"
  }

  // Revisa celdas vecinas
  for (int r = row - 1; r <= row + 1; r++) {
    for (int c = col - 1; c <= col + 1; c++) {
      if (r < 0 || r >= mazeRows || c < 0 || c >= mazeCols) continue;
      // Si la celda es pared (1), revisa colisión circular
      if (maze[r][c] == 1) {
        float leftEdge   = c * cellSize;
        float rightEdge  = (c + 1) * cellSize;
        float topEdge    = r * cellSize;
        float bottomEdge = (r + 1) * cellSize;

        float closestX = constrain(playerPos.x, leftEdge, rightEdge);
        float closestZ = constrain(playerPos.z, topEdge, bottomEdge);

        float distX = playerPos.x - closestX;
        float distZ = playerPos.z - closestZ;
        float distSq = distX*distX + distZ*distZ;

        if (distSq < playerRadius * playerRadius) {
          return true;
        }
      }
    }
  }
  return false;
}
