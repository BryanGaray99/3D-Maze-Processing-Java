/**
 * Player.pde gestiona la logica de control del jugador dentro del laberinto.
 * Almacena la posicion, angulo y radio de colision del jugador, asi como la velocidad de
 * desplazamiento. Tambien maneja la deteccion de colisiones, la actualizacion de la
 * camara, la verificacion de victoria y el reinicio de la posicion del jugador.
 */

// -----------------------------------------------------------------------------
// Variables clave para la gestion y estado del jugador
// -----------------------------------------------------------------------------

/** Ubicacion actual del jugador en el espacio 3D (x, y, z). */
PVector playerPos;
/** Almacena la ultima posicion conocida del jugador para comparaciones. */
PVector lastPlayerPos = new PVector();
/** Almacena el angulo de orientacion del jugador en radianes. */
float playerAngle = 0;
/** Velocidad de desplazamiento en celdas/pixeles por fotograma. */
float playerSpeed = 2.5;
/** Radio de colision usado para deteccion con paredes. */
float playerRadius = 10;

/** Instante en milisegundos en el que el jugador gana. */
int winStartTime = 0;
/** Duracion en milisegundos para mostrar el mensaje de victoria. */
int winDuration = 5000;

/**
 * Actualizamos la posicion del jugador en funcion de las teclas de movimiento
 * (adelante, atras, strafe, giros). Comprueba las colisiones con paredes
 * y reajusta la camara para que siga al jugador. Si hay colision,
 * restaura la posicion anterior.
 */
void updatePlayer() {
  if (playerPos == null) return;

  PVector oldPos = playerPos.copy();

  // Ajustes de angulo con teclas Q/E
  if (turnLeft)  playerAngle -= 0.03;
  if (turnRight) playerAngle += 0.03;

  float dirX = sin(playerAngle);
  float dirZ = cos(playerAngle);
  float perpX = cos(playerAngle);
  float perpZ = -sin(playerAngle);

  // Movimientos basicos (adelante, atras, strafe)
  if (up)          { playerPos.x += dirX * playerSpeed;   playerPos.z += dirZ * playerSpeed; }
  if (down)        { playerPos.x -= dirX * playerSpeed;   playerPos.z -= dirZ * playerSpeed; }
  if (strafeLeft)  { playerPos.x += perpX * playerSpeed;  playerPos.z += perpZ * playerSpeed; }
  if (strafeRight) { playerPos.x -= perpX * playerSpeed;  playerPos.z -= perpZ * playerSpeed; }

  // Chequeo de colisiones con paredes
  if (checkCollision()) {
    playerPos = oldPos;
  }

  // Ajusta la camara para enfocarse en el jugador
  camera(playerPos.x, playerPos.y, playerPos.z,
         playerPos.x + dirX * 50, playerPos.y, playerPos.z + dirZ * 50,
         0, 1, 0);
}

/**
 * Reposicionamos al jugador en las coordenadas de inicio (col=1, row=1) y
 * restablece el angulo de orientacion y la ultima posicion conocida.
 */
void resetPlayer() {
  // Por defecto, la posicion se situa en (1.5 * cellSize, 25, 1 * cellSize)
  playerPos = new PVector((1 + 0.5) * cellSize, 25, (1) * cellSize);
  playerAngle = 0;
  lastPlayerPos.set(playerPos);
}

/**
 * Verificamos si la posicion actual del jugador coincide con la celda de salida
 * (exitRow, exitCol), en cuyo caso establece la bandera hasWon y registra
 * el tiempo de victoria en winStartTime.
 */
void checkWinCondition() {
  if (playerPos == null) return;

  int col = floor(playerPos.x / cellSize);
  int row = floor(playerPos.z / cellSize);

  if (!playerPos.equals(lastPlayerPos)) {
    lastPlayerPos = playerPos.copy();
  }
  // Deteccion de celda de salida
  if (row == exitRow && col == exitCol) {
    hasWon = true;
    winStartTime = millis();
  }
}

/**
 * Mostramos en pantalla un mensaje de felicitacion ("HAS GANADO!") durante
 * un lapso (winDuration). Una vez transcurrido, se reinicia el juego.
 */
void displayWinMessage() {
  int elapsed = millis() - winStartTime;
  if (elapsed < winDuration) {
    hint(DISABLE_DEPTH_TEST);
    camera(); 
    textAlign(CENTER, CENTER);

    pushStyle();
    fill(0, 255, 0);
    textSize(48);
    text("HAS GANADO!", width/2, height/2);
    popStyle();

    hint(ENABLE_DEPTH_TEST);
  } else {
    resetGame();
  }
}

/**
 * Determinamos si existe colision entre el jugador y las paredes o si se sale del limite.
 * Bloquea ademas la celda de entrada, impidiendo que el jugador retroceda a ella.
 *
 * @return true si se ha producido una colision o esta fuera de limites
 */
boolean checkCollision() {
  int col = floor(playerPos.x / cellSize);
  int row = floor(playerPos.z / cellSize);

  // Fuera de limites
  if (row < 0 || row >= mazeRows || col < 0 || col >= mazeCols) {
    return true;
  }

  // Celda de entrada bloqueada para el jugador
  if (row == entranceRow && col == entranceCol) {
    return true;
  }

  // Salida no se considera colision
  for (int r = row - 1; r <= row + 1; r++) {
    for (int c = col - 1; c <= col + 1; c++) {
      if (r < 0 || r >= mazeRows || c < 0 || c >= mazeCols) continue;
      if (maze[r][c] == 1) {
        float leftEdge =   c * cellSize;
        float rightEdge =  (c + 1) * cellSize;
        float topEdge =    r * cellSize;
        float bottomEdge = (r + 1) * cellSize;

        float closestX = constrain(playerPos.x, leftEdge, rightEdge);
        float closestZ = constrain(playerPos.z, topEdge, bottomEdge);
        float distX = playerPos.x - closestX;
        float distZ = playerPos.z - closestZ;
        float distSq = distX * distX + distZ * distZ;

        // Verifica si el circulo de colision del jugador toca la pared
        if (distSq < playerRadius * playerRadius) {
          return true;
        }
      }
    }
  }
  return false;
}
