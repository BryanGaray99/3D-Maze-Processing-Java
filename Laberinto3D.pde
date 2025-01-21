// -------------------
// Laberinto3D.pde
// -------------------
PImage wallImg;
boolean hasWon = false;

void setup() {
  size(600, 600, P3D);
  wallImg = loadImage("wall1.jpg");
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

// -------------------
// Maze.pde
// -------------------
int mazeRows = 15;   // Ajusta según necesites
int mazeCols = 15;   // Ajusta según necesites
int cellSize = 40;

// La matriz que representa el laberinto
int[][] maze;

// Coordenadas de la entrada y la salida
int entranceRow = 0;
int entranceCol = 1;
int exitRow;
int exitCol;

void setupMaze() {
  println("Generando y validando el laberinto...");

  boolean valid = false;
  while (!valid) {
    generateMaze();

    // Fuerza la entrada y la salida como celdas abiertas (0)
    maze[entranceRow][entranceCol] = 0;
    maze[exitRow][exitCol] = 0;

    // Valida conectividad
    valid = isConnectedBFS(entranceRow, entranceCol, exitRow, exitCol);
    if (!valid) {
      println("El Maze generado NO tiene camino de entrada a salida. Regenerando...");
    }
  }

  println("¡Maze válido encontrado!");
  println("Imprimiendo la matriz final (1=Pared, 0=Libre):");
  for (int r = 0; r < mazeRows; r++) {
    // Imprime cada fila en una sola línea
    for (int c = 0; c < mazeCols; c++) {
      print(maze[r][c] + " ");
    }
    println(); // Salto de línea al terminar cada fila
  }
  println("-----------------------------------------");
}

void generateMaze() {
  // 1) Llenar todo de paredes
  maze = new int[mazeRows][mazeCols];
  for (int r = 0; r < mazeRows; r++) {
    for (int c = 0; c < mazeCols; c++) {
      maze[r][c] = 1;
    }
  }

  // 2) Determina la salida en la última fila, con columna aleatoria
  exitRow = mazeRows - 1;
  exitCol = (int) random(1, mazeCols - 1);

  // 3) Iniciar "tallado" de pasillos con DFS en (1,1)
  //    (para no arrancar pegado a la frontera)
  int startRow = 1;
  int startCol = 1;
  maze[startRow][startCol] = 0; // abre la celda inicial

  dfsCarve(startRow, startCol);
}

// DFS para "cavar" pasillos en la matriz
void dfsCarve(int row, int col) {
  int[] directions = {0, 1, 2, 3}; // 0=UP,1=RIGHT,2=DOWN,3=LEFT
  shuffleArray(directions);

  for (int i = 0; i < directions.length; i++) {
    int dir = directions[i];
    int nr = row;
    int nc = col;

    switch(dir) {
      case 0: nr -= 2; break; // UP
      case 1: nc += 2; break; // RIGHT
      case 2: nr += 2; break; // DOWN
      case 3: nc -= 2; break; // LEFT
    }

    // Verificar límites
    if (nr > 0 && nr < mazeRows - 1 && nc > 0 && nc < mazeCols - 1) {
      // Si es pared, lo abrimos
      if (maze[nr][nc] == 1) {
        maze[nr][nc] = 0;
        maze[(row + nr)/2][(col + nc)/2] = 0; // abrir la pared intermedia
        dfsCarve(nr, nc);
      }
    }
  }
}

// BFS para validar si hay camino (sin diagonales)
boolean isConnectedBFS(int sr, int sc, int er, int ec) {
  if (maze[sr][sc] == 1 || maze[er][ec] == 1) {
    return false;
  }

  boolean[][] visited = new boolean[mazeRows][mazeCols];
  int[] queueR = new int[mazeRows*mazeCols];
  int[] queueC = new int[mazeRows*mazeCols];
  int front = 0;
  int back = 0;

  queueR[back] = sr;
  queueC[back] = sc;
  back++;
  visited[sr][sc] = true;

  int[] dr = {-1, 1, 0, 0};
  int[] dc = {0, 0, -1, 1};

  while (front < back) {
    int rr = queueR[front];
    int cc = queueC[front];
    front++;

    if (rr == er && cc == ec) {
      return true;
    }

    for (int i = 0; i < 4; i++) {
      int r2 = rr + dr[i];
      int c2 = cc + dc[i];

      if (r2 >= 0 && r2 < mazeRows && c2 >= 0 && c2 < mazeCols) {
        if (!visited[r2][c2] && maze[r2][c2] == 0) {
          visited[r2][c2] = true;
          queueR[back] = r2;
          queueC[back] = c2;
          back++;
        }
      }
    }
  }
  return false;
}

// Baraja el array de direcciones aleatoriamente
void shuffleArray(int[] array) {
  for (int i = array.length - 1; i > 0; i--) {
    int index = (int) random(i + 1);
    int temp = array[index];
    array[index] = array[i];
    array[i] = temp;
  }
}

// --------------------------------------------------
// Dibujo del Maze (incluyendo láminas de entrada y salida)
// --------------------------------------------------
void drawMaze() {
  for (int row = 0; row < mazeRows; row++) {
    for (int col = 0; col < mazeCols; col++) {
      pushMatrix();
      float centerX = (col + 0.5) * cellSize;
      float centerZ = (row + 0.5) * cellSize;
      // Centra el objeto en XZ, y en Y a la mitad (para que se pare sobre Y=0)
      translate(centerX, cellSize / 2, centerZ);

      // --- CASO 1: CELDA PARED (1) ---
      if (maze[row][col] == 1) {
        beginShape();
        texture(wallImg);
        
        // Front Face
        beginShape(QUADS);
        vertex(-cellSize/2, -cellSize/2, cellSize/2, 0, 0);
        vertex(cellSize/2, -cellSize/2, cellSize/2, wallImg.width, 0);
        vertex(cellSize/2, cellSize/2, cellSize/2, wallImg.width, wallImg.height);
        vertex(-cellSize/2, cellSize/2, cellSize/2, 0, wallImg.height);
        endShape();
        
        // Back Face
        beginShape(QUADS);
        vertex(cellSize/2, -cellSize/2, -cellSize/2, 0, 0);
        vertex(-cellSize/2, -cellSize/2, -cellSize/2, wallImg.width, 0);
        vertex(-cellSize/2, cellSize/2, -cellSize/2, wallImg.width, wallImg.height);
        vertex(cellSize/2, cellSize/2, -cellSize/2, 0, wallImg.height);
        endShape();
        
        // Right Face
        beginShape(QUADS);
        vertex(cellSize/2, -cellSize/2, cellSize/2, 0, 0);
        vertex(cellSize/2, -cellSize/2, -cellSize/2, wallImg.width, 0);
        vertex(cellSize/2, cellSize/2, -cellSize/2, wallImg.width, wallImg.height);
        vertex(cellSize/2, cellSize/2, cellSize/2, 0, wallImg.height);
        endShape();
        
        // Left Face
        beginShape(QUADS);
        vertex(-cellSize/2, -cellSize/2, -cellSize/2, 0, 0);
        vertex(-cellSize/2, -cellSize/2, cellSize/2, wallImg.width, 0);
        vertex(-cellSize/2, cellSize/2, cellSize/2, wallImg.width, wallImg.height);
        vertex(-cellSize/2, cellSize/2, -cellSize/2, 0, wallImg.height);
        endShape();
        
        // Top Face
        beginShape(QUADS);
        vertex(-cellSize/2, -cellSize/2, cellSize/2, 0, 0);
        vertex(cellSize/2, -cellSize/2, cellSize/2, wallImg.width, 0);
        vertex(cellSize/2, -cellSize/2, -cellSize/2, wallImg.width, wallImg.height);
        vertex(-cellSize/2, -cellSize/2, -cellSize/2, 0, wallImg.height);
        endShape();
        
        // Bottom Face
        beginShape(QUADS);
        vertex(-cellSize/2, cellSize/2, -cellSize/2, 0, 0);
        vertex(cellSize/2, cellSize/2, -cellSize/2, wallImg.width, 0);
        vertex(cellSize/2, cellSize/2, cellSize/2, wallImg.width, wallImg.height);
        vertex(-cellSize/2, cellSize/2, cellSize/2, 0, wallImg.height);
        endShape();

      // --- CASO 2: CELDA ES LA ENTRADA ---
      } else if (row == entranceRow && col == entranceCol) {
        // Lámina roja vertical y delgada, sólida
        fill(255, 0, 0);
        // Para que parezca tapa en el lado externo, la movemos
        // un poco en -Z (o +Z) para que no bloquee dentro.
        pushMatrix();
        // Por ejemplo, la movemos medio cellsize hacia atrás en Z:
        translate(0, 0, -cellSize/2 + 1); 
        box(cellSize, cellSize, 4);  // grosor 4
        popMatrix();

      // --- CASO 3: CELDA ES LA SALIDA ---
      } else if (row == exitRow && col == exitCol) {
        // Lámina verde vertical y delgada, pero atravesable
        fill(0, 255, 0);
        pushMatrix();
        // La movemos medio cellsize adelante en Z
        translate(0, 0, cellSize/2 - 1);
        box(cellSize, cellSize, 4);
        popMatrix();

      // --- CASO 4: CELDA LIBRE ---
      } else {
        // Normalmente, celdas libres (0) no dibujan nada (espacio vacío).
        // O podrías dibujar el suelo si quieres.
      }

      popMatrix();
    }
  }
}

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
    fill(0, 255, 0);
    textSize(48);
    text("¡HAS GANADO!", width / 2, height / 2);
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
