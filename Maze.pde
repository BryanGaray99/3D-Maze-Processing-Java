// -------------------
// Maze.pde
// -------------------
import java.util.ArrayList;
import java.util.LinkedList;
import java.util.Queue;
import java.util.Collections;

int mazeRows = 16;
int mazeCols = 16;
int cellSize = 40;

// 1 = Pared, 0 = Libre
int[][] maze;

int entranceRow = 0;
int entranceCol = 1;
int exitRow;
int exitCol;

// Matriz de color para "parches"
color[][] wallColors;

/** Ajusta mazeRows/mazeCols según selectedLevel. 
    Llamada al generar el laberinto. */
void setMazeSizeFromLevel() {
  switch(selectedLevel) {
    case 1:
      mazeRows = 15; mazeCols = 15;
      break;
    case 2:
      mazeRows = 25; mazeCols = 25;
      break;
    case 3:
      mazeRows = 35; mazeCols = 35;
      break;
    default:
      mazeRows = 15; mazeCols = 15;
  }
}

/** Genera y valida el laberinto, luego coloca los parches de color */
void setupMaze() {
  println("[MAZE] setupMaze() => Empezar generacion");
  
  // Ajustar tamaño según el nivel
  setMazeSizeFromLevel();
  
  generateAndValidateMaze();
  
  detectColoredWalls();
}

/** Retorna true si (rr,cc) está dentro de la matriz */
boolean isInside(int rr, int cc) {
  return (rr >= 0 && rr < mazeRows && cc >= 0 && cc < mazeCols);
}

void generateAndValidateMaze() {
  boolean valid = false;
  while (!valid) {
    generateMaze();
    // Forzar entrada y salida
    maze[entranceRow][entranceCol] = 0;
    maze[exitRow][exitCol] = 0;
    valid = isConnectedBFS(entranceRow, entranceCol, exitRow, exitCol);
    if (!valid) {
      println("[MAZE] BFS => no hay camino, regenerando...");
    }
  }
  println("[MAZE] Maze válido! Imprimiendo matriz:");
  for (int r = 0; r < mazeRows; r++) {
    String rowStr = "";
    for (int c = 0; c < mazeCols; c++) {
      rowStr += (maze[r][c] + " ");
    }
    println(rowStr);
  }
  println("--------------------");
}

void generateMaze() {
  println("[MAZE] Generar Maze de " + mazeRows + " x " + mazeCols);
  maze = new int[mazeRows][mazeCols];
  for (int r = 0; r < mazeRows; r++) {
    for (int c = 0; c < mazeCols; c++) {
      maze[r][c] = 1;  // inicialmente, todo son paredes
    }
  }
  exitRow = mazeRows - 1;
  exitCol = int(random(1, mazeCols - 1));
  
  maze[1][1] = 0;
  dfsCarve(1, 1);
}

void dfsCarve(int row, int col) {
  int[] dirs = {0, 1, 2, 3};
  shuffleArray(dirs);
  for (int d : dirs) {
    int nr = row, nc = col;
    switch(d) {
      case 0: nr -= 2; break; // arriba
      case 1: nc += 2; break; // derecha
      case 2: nr += 2; break; // abajo
      case 3: nc -= 2; break; // izquierda
    }
    if (nr > 0 && nr < mazeRows - 1 && nc > 0 && nc < mazeCols - 1) {
      if (maze[nr][nc] == 1) {
        maze[nr][nc] = 0;
        maze[(row + nr) / 2][(col + nc) / 2] = 0;
        dfsCarve(nr, nc);
      }
    }
  }
}

boolean isConnectedBFS(int sr, int sc, int er, int ec) {
  if (maze[sr][sc] == 1 || maze[er][ec] == 1) return false;
  boolean[][] visited = new boolean[mazeRows][mazeCols];
  int[] queueR = new int[mazeRows * mazeCols];
  int[] queueC = new int[mazeRows * mazeCols];
  int front = 0, back = 0;
  
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
    if (rr == er && cc == ec) return true;
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

void shuffleArray(int[] arr) {
  for (int i = arr.length - 1; i > 0; i--) {
    int idx = (int)random(i + 1);
    int temp = arr[idx];
    arr[idx] = arr[i];
    arr[i] = temp;
  }
}

/**
 * Detecta y coloca los parches de color de forma estratégica.
 * La estrategia consiste en dividir el laberinto en sectores según su tamaño y
 * en cada sector ubicar, preferentemente cerca del centro, un parche en una pared adyacente a una celda libre.
 */
void detectColoredWalls() {
  println("[MAZE] detectColoredWalls() => Estrategia de sectorización 2x4 por sector (8 parches por sector)");
  
  // Inicializar la matriz de colores sin parches.
  wallColors = new color[mazeRows][mazeCols];
  for (int r = 0; r < mazeRows; r++) {
    for (int c = 0; c < mazeCols; c++) {
      wallColors[r][c] = color(0, 0); // Sin color
    }
  }
  
  // Determinar el número de sectores según el tamaño del laberinto.
  // Por ejemplo: para 15x15 se usan 2, para 25x25: 3, para 35x35: 4 sectores por dimensión.
  int numSectors = 2;
  if (mazeRows >= 25) numSectors = 3;
  if (mazeRows >= 35) numSectors = 4;
  
  int sectorHeight = mazeRows / numSectors;
  int sectorWidth  = mazeCols / numSectors;
  
  // Definir la subdivisión interna: para 8 parches por sector, usamos 2 filas y 4 columnas.
  int subDivRows = 2;
  int subDivCols = 4;
  
  // Predefinir desplazamientos para vecinos (arriba, abajo, izquierda, derecha).
  int[][] deltas = { {-1, 0}, {1, 0}, {0, -1}, {0, 1} };
  
  int totalPatchesPlaced = 0;
  
  // Iterar por cada sector.
  for (int i = 0; i < numSectors; i++) {
    for (int j = 0; j < numSectors; j++) {
      int sector_r_min = i * sectorHeight;
      int sector_r_max = (i == numSectors - 1) ? mazeRows - 1 : (i + 1) * sectorHeight - 1;
      int sector_c_min = j * sectorWidth;
      int sector_c_max = (j == numSectors - 1) ? mazeCols - 1 : (j + 1) * sectorWidth - 1;
      
      // Dividir cada sector en subDivRows x subDivCols sub-sectores.
      int subSectorHeight = max(1, (sector_r_max - sector_r_min + 1) / subDivRows);
      int subSectorWidth  = max(1, (sector_c_max - sector_c_min + 1) / subDivCols);
      
      // Iterar en cada sub-sector (total subDivRows * subDivCols = 8 por sector).
      for (int subRow = 0; subRow < subDivRows; subRow++) {
        for (int subCol = 0; subCol < subDivCols; subCol++) {
          int sub_r_min = sector_r_min + subRow * subSectorHeight;
          int sub_r_max = (subRow == subDivRows - 1) ? sector_r_max : sub_r_min + subSectorHeight - 1;
          int sub_c_min = sector_c_min + subCol * subSectorWidth;
          int sub_c_max = (subCol == subDivCols - 1) ? sector_c_max : sub_c_min + subSectorWidth - 1;
          
          int centerR = (sub_r_min + sub_r_max) / 2;
          int centerC = (sub_c_min + sub_c_max) / 2;
          
          boolean patchPlaced = false;
          
          // Intentar colocar un parche usando la celda central del sub-sector si es libre.
          if (maze[centerR][centerC] == 0) {
            for (int d = 0; d < 4; d++) {
              int nr = centerR + deltas[d][0];
              int nc = centerC + deltas[d][1];
              if (isInside(nr, nc) && maze[nr][nc] == 1 && wallColors[nr][nc] == color(0, 0)) {
                wallColors[nr][nc] = color(random(255), random(255), random(255));
                totalPatchesPlaced++;
                patchPlaced = true;
                break;
              }
            }
          }
          
          // Si no se pudo colocar en el centro, buscar en un radio pequeño alrededor.
          if (!patchPlaced) {
            int radius = 2;
            outer:
            for (int r = max(sub_r_min, centerR - radius); r <= min(sub_r_max, centerR + radius); r++) {
              for (int c = max(sub_c_min, centerC - radius); c <= min(sub_c_max, centerC + radius); c++) {
                if (maze[r][c] == 0) {
                  for (int d = 0; d < 4; d++) {
                    int nr = r + deltas[d][0];
                    int nc = c + deltas[d][1];
                    if (isInside(nr, nc) && maze[nr][nc] == 1 && wallColors[nr][nc] == color(0, 0)) {
                      wallColors[nr][nc] = color(random(255), random(255), random(255));
                      totalPatchesPlaced++;
                      patchPlaced = true;
                      break outer;
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  println("[MAZE] placed=" + totalPatchesPlaced + " patches.");
}



/** Dibuja el laberinto y, en caso de entrada/salida, añade animación */
void drawMaze() {
  for (int r = 0; r < mazeRows; r++) {
    for (int c = 0; c < mazeCols; c++) {
      pushMatrix();
      float cx = (c + 0.5) * cellSize;
      float cz = (r + 0.5) * cellSize;
      translate(cx, cellSize/2, cz);

      if (maze[r][c] == 1) {
        // PARED
        pushStyle();
        texturedBox(cellSize, wallImg);
        popStyle();

        // Parche de color
        if (wallColors[r][c] != color(0, 0)) {
          pushMatrix();
          pushStyle();
          translate(0, 0, -cellSize/2 - 0.1);
          fill(wallColors[r][c]);
          noStroke();
          float sz = cellSize * 0.3;
          beginShape(QUADS);
            vertex(-sz/2, -sz/2, 0);
            vertex( sz/2, -sz/2, 0);
            vertex( sz/2,  sz/2, 0);
            vertex(-sz/2,  sz/2, 0);
          endShape();
          popStyle();
          popMatrix();
        }
      }
      else {
        // CELDA LIBRE: ¿Es entrada/salida?
        if (r == entranceRow && c == entranceCol) {
          drawPortal(false);
        }
        else if (r == exitRow && c == exitCol) {
          drawPortal(true);
        }
      }
      popMatrix();
    }
  }
}

/** Dibuja una pared/caja con textura */
void texturedBox(float size, PImage tex) {
  float half = size / 2;
  noFill();
  noStroke();
  // Cara frontal
  beginShape();
    texture(tex);
    vertex(-half, -half,  half, 0, 0);
    vertex( half, -half,  half, tex.width, 0);
    vertex( half,  half,  half, tex.width, tex.height);
    vertex(-half,  half,  half, 0, tex.height);
  endShape(CLOSE);

  // Cara trasera
  beginShape();
    texture(tex);
    vertex( half, -half, -half, 0, 0);
    vertex(-half, -half, -half, tex.width, 0);
    vertex(-half,  half, -half, tex.width, tex.height);
    vertex( half,  half, -half, 0, tex.height);
  endShape(CLOSE);

  // Cara izquierda
  beginShape();
    texture(tex);
    vertex(-half, -half, -half, 0, 0);
    vertex(-half, -half,  half, tex.width, 0);
    vertex(-half,  half,  half, tex.width, tex.height);
    vertex(-half,  half, -half, 0, tex.height);
  endShape(CLOSE);

  // Cara derecha
  beginShape();
    texture(tex);
    vertex( half, -half,  half, 0, 0);
    vertex( half, -half, -half, tex.width, 0);
    vertex( half,  half, -half, tex.width, tex.height);
    vertex( half,  half,  half, 0, tex.height);
  endShape(CLOSE);

  // Cara superior
  beginShape();
    texture(tex);
    vertex(-half, -half, -half, 0, 0);
    vertex( half, -half, -half, tex.width, 0);
    vertex( half, -half,  half, tex.width, tex.height);
    vertex(-half, -half,  half, 0, tex.height);
  endShape(CLOSE);

  // Cara inferior
  beginShape();
    texture(tex);
    vertex(-half, half,  half, 0, 0);
    vertex( half, half,  half, tex.width, 0);
    vertex( half, half, -half, tex.width, tex.height);
    vertex(-half, half, -half, 0, tex.height);
  endShape(CLOSE);
}

/** Dibuja la entrada/salida con su textura y una animación "tipo portal". */
void drawPortal(boolean isExit) {
  pushStyle();
  pushMatrix();
  
  if (!isExit) {
    // Entrada => hacia -Z
    translate(0, 0, -cellSize/2 + 1);
    texturedBox(cellSize, portalEntry);
    translate(0, 0, -0.5);
  } else {
    // Salida => hacia +Z
    translate(0, 0, cellSize/2 - 1);
    texturedBox(cellSize, portalExit);
    translate(0, 0, 0.5);
  }

  // Efecto de pulso
  float t = millis() * 0.01;
  float scaleAmt = 1 + 0.3 * sin(t);
  float rad = cellSize * 0.6 * scaleAmt;

  // Rotamos para dibujar el portal “mirando” al jugador (en Y)
  rotateX(HALF_PI);

  noFill();
  strokeWeight(3);
  stroke(isExit ? color(255, 100, 100) : color(100, 255, 100));
  ellipse(0, 0, rad, rad);

  popMatrix();
  popStyle();
}
