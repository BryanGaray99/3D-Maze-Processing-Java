// -------------------
// Player.pde
// -------------------
PVector playerPos;
PVector lastPlayerPos = new PVector();
float playerAngle = 0;
float playerSpeed = 2.5;
float playerRadius = 10;

int winStartTime = 0;
int winDuration = 5000;

void updatePlayer() {
  // Si playerPos está null por alguna razón, salir antes de hacer nada:
  if (playerPos == null) return;

  PVector oldPos = playerPos.copy();

  // Rotación de la cámara con Q/E
  if (turnLeft)  playerAngle -= 0.03;
  if (turnRight) playerAngle += 0.03;

  float dirX = sin(playerAngle);
  float dirZ = cos(playerAngle);
  float perpX = cos(playerAngle);
  float perpZ = -sin(playerAngle);

  // Movimiento
  if (up)          { playerPos.x += dirX * playerSpeed;   playerPos.z += dirZ * playerSpeed; }
  if (down)        { playerPos.x -= dirX * playerSpeed;   playerPos.z -= dirZ * playerSpeed; }
  if (strafeLeft)  { playerPos.x += perpX * playerSpeed;  playerPos.z += perpZ * playerSpeed; }
  if (strafeRight) { playerPos.x -= perpX * playerSpeed;  playerPos.z -= perpZ * playerSpeed; }

  // Colisiones
  if (checkCollision()) {
    // Si colisiona, deshacemos el movimiento
    playerPos = oldPos;
  }

  // Cámara
  camera(playerPos.x, playerPos.y, playerPos.z,
         playerPos.x + dirX * 50, playerPos.y, playerPos.z + dirZ * 50,
         0, 1, 0);
}

void resetPlayer() {
  // Coloca al jugador justo en la entrada, un poco levantado en Y
  playerPos = new PVector((1 + 0.5) * cellSize, 25, (1) * cellSize);
  playerAngle = 0;
  lastPlayerPos.set(playerPos);
}

void checkWinCondition() {
  if (playerPos == null) return; // Evita NullPointer

  int col = floor(playerPos.x / cellSize);
  int row = floor(playerPos.z / cellSize);

  if (!playerPos.equals(lastPlayerPos)) {
    // Debug
    // println("Fila="+row+", Col="+col);
    lastPlayerPos = playerPos.copy();
  }

  // Comprueba si estamos en la salida
  if (row == exitRow && col == exitCol) {
    hasWon = true;
    winStartTime = millis();
  }
}

void displayWinMessage() {
  int elapsed = millis() - winStartTime;
  if (elapsed < winDuration) {
    hint(DISABLE_DEPTH_TEST);
    camera(); // Restaurar cámara por defecto para texto 2D
    textAlign(CENTER, CENTER);

    pushStyle(); // Aislar configuraciones gráficas
    fill(0, 255, 0); // Color verde para el texto
    textSize(48);
    text("¡HAS GANADO!", width / 2, height / 2);
    popStyle(); // Restaurar configuraciones anteriores

    hint(ENABLE_DEPTH_TEST);
  } else {
    resetGame();
  }
}

boolean checkCollision() {
  int col = floor(playerPos.x / cellSize);
  int row = floor(playerPos.z / cellSize);

  // Verifica si está fuera de límites
  if (row < 0 || row >= mazeRows || col < 0 || col >= mazeCols) {
    return true;
  }

  // 1) Si estamos en la celda de la ENTRADA, colisionamos
  //    (para simular la lámina roja maciza).
  //    El BFS la ve como 0 (libre) para "explotar" caminos,
  //    pero el jugador, físicamente, no puede entrar/salir por ahí.
  if (row == entranceRow && col == entranceCol) {
    return true;  // Bloque total
  }

  // 2) Si estamos en la celda de la SALIDA, NO colisionamos, 
  //    pues es atravesable. (Igual tu checkWinCondition detecta si se llegó).
  //    => no hacemos nada especial aquí.

  // 3) Revisa celdas vecinas para paredes con colisión circular
  for (int r = row - 1; r <= row + 1; r++) {
    for (int c = col - 1; c <= col + 1; c++) {
      if (r < 0 || r >= mazeRows || c < 0 || c >= mazeCols) continue;
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
