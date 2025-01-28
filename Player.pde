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
  if (playerPos == null) return;

  PVector oldPos = playerPos.copy();

  // Rotación Q/E
  if (turnLeft)  playerAngle -= 0.03;
  if (turnRight) playerAngle += 0.03;

  float dirX = sin(playerAngle);
  float dirZ = cos(playerAngle);
  float perpX= cos(playerAngle);
  float perpZ= -sin(playerAngle);

  // Movimiento
  if (up)          { playerPos.x += dirX * playerSpeed;   playerPos.z += dirZ * playerSpeed; }
  if (down)        { playerPos.x -= dirX * playerSpeed;   playerPos.z -= dirZ * playerSpeed; }
  if (strafeLeft)  { playerPos.x += perpX * playerSpeed;  playerPos.z += perpZ * playerSpeed; }
  if (strafeRight) { playerPos.x -= perpX * playerSpeed;  playerPos.z -= perpZ * playerSpeed; }

  // Colisiones
  if (checkCollision()) {
    playerPos = oldPos;
  }

  // Cámara
  camera(playerPos.x, playerPos.y, playerPos.z,
         playerPos.x + dirX * 50, playerPos.y, playerPos.z + dirZ * 50,
         0, 1, 0);
}

void resetPlayer() {
  // Según tu código original, se pone en (1.5 * cellSize, 25, 1 * cellSize)
  // => col=1 +0.5 => X, row=1 => Z
  playerPos = new PVector((1 + 0.5) * cellSize, 25, (1) * cellSize);
  playerAngle = 0;
  lastPlayerPos.set(playerPos);
}

void checkWinCondition() {
  if (playerPos == null) return;
  
  int col = floor(playerPos.x / cellSize);
  int row = floor(playerPos.z / cellSize);

  if (!playerPos.equals(lastPlayerPos)) {
    lastPlayerPos = playerPos.copy();
  }
  // Salida
  if (row == exitRow && col == exitCol) {
    hasWon = true;
    winStartTime = millis();
  }
}

void displayWinMessage() {
  int elapsed = millis() - winStartTime;
  if (elapsed < winDuration) {
    hint(DISABLE_DEPTH_TEST);
    camera(); 
    textAlign(CENTER, CENTER);

    pushStyle();
    fill(0, 255, 0);
    textSize(48);
    text("¡HAS GANADO!", width/2, height/2);
    popStyle();

    hint(ENABLE_DEPTH_TEST);
  } else {
    resetGame();
  }
}

boolean checkCollision() {
  int col = floor(playerPos.x / cellSize);
  int row = floor(playerPos.z / cellSize);

  // Fuera limites
  if (row<0||row>=mazeRows||col<0||col>=mazeCols) {
    return true;
  }

  // Bloquear la celda de la ENTRADA
  if (row==entranceRow && col==entranceCol) {
    return true; 
  }

  // Si es la SALIDA => no colision
  for (int r=row-1; r<=row+1; r++) {
    for (int c=col-1; c<=col+1; c++) {
      if (r<0||r>=mazeRows||c<0||c>=mazeCols) continue;
      if (maze[r][c]==1) {
        float leftEdge=   c*cellSize;
        float rightEdge=  (c+1)*cellSize;
        float topEdge=    r*cellSize;
        float bottomEdge= (r+1)*cellSize;

        float closestX=constrain(playerPos.x, leftEdge,rightEdge);
        float closestZ=constrain(playerPos.z, topEdge,bottomEdge);
        float distX=playerPos.x-closestX;
        float distZ=playerPos.z-closestZ;
        float distSq=distX*distX + distZ*distZ;

        if(distSq < playerRadius*playerRadius) {
          return true;
        }
      }
    }
  }
  return false;
}
