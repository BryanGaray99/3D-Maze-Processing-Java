/**
 * Maze.pde
 *
 * Este archivo se encarga de la generación, validación y renderizado del laberinto 3D.
 * Las dimensiones del laberinto se determinan en función del nivel seleccionado:
 *   - Nivel 1: 5x5 celdas.
 *   - Nivel 2: 15x15 celdas.
 *   - Nivel 3: 25x25 celdas.
 *
 * Optimización y funcionamiento:
 *   - La generación del laberinto se realiza mediante un algoritmo DFS (búsqueda en profundidad)
 *     que excava pasillos en un espacio inicialmente lleno de paredes.
 *   - Se emplea un algoritmo BFS optimizado para validar la conectividad entre la entrada y la salida,
 *     utilizando una matriz preasignada (visitedBFS) y arreglos de enteros para la cola.
 *   - El renderizado del laberinto se efectúa en 3D, utilizando un PShape preconstruido para representar
 *     las paredes, reduciendo la sobrecarga de llamadas a beginShape()/endShape().
 *   - La asignación de "parches" (imágenes) a las paredes se organiza mediante una lógica de sectores.
 *     De las 25 imágenes precargadas globalmente (en patchPoolGlobal, cargadas en un hilo secundario
 *     en Laberinto3D.pde), se utiliza un subconjunto: las primeras 5 para un laberinto de 5x5, las primeras
 *     15 para un laberinto de 15x15, o las 25 para un laberinto de 25x25.
 *   - Estas optimizaciones permiten que, tras finalizar una partida y reiniciar, el laberinto se
 *     genere y se renderice de forma rápida, evitando recargas innecesarias de imágenes.
 *
 * Se espera que las siguientes variables globales se declaren en el archivo principal:
 *   - PImage wallImg, portalEntry, portalExit
 * Además, se utiliza la variable global patchPoolGlobal[] y la bandera patchLoadComplete, las cuales
 * se inicializan en Laberinto3D.pde al arrancar la aplicación.
 */

import java.util.ArrayList;
import java.util.LinkedList;
import java.util.Queue;
import java.util.Collections;

// -----------------------------------------------------------------------------
// Parámetros y variables locales para Maze
// -----------------------------------------------------------------------------

int mazeRows = 5;
int mazeCols = 5;
int cellSize = 40;

int[][] maze;          // 1 => pared, 0 => libre
int entranceRow = 0;
int entranceCol = 1;
int exitRow;
int exitCol;

// Matriz de colores y parches
color[][] wallColors;
PImage[][] patchImages;

// BFS optimizado
boolean[][] visitedBFS;

// PShape de la pared con textura
PShape wallShape = null;

// -----------------------------------------------------------------------------
// Ajustar tamaño de laberinto según el nivel
// -----------------------------------------------------------------------------

void setMazeSizeFromLevel() {
  // Se asume: 1 => 5x5, 2 => 15x15, 3 => 25x25
  switch(selectedLevel) {
    case 1: 
      mazeRows = 5; 
      mazeCols = 5;
      break;
    case 2:
      mazeRows = 15; 
      mazeCols = 15;
      break;
    case 3:
      mazeRows = 25; 
      mazeCols = 25;
      break;
    default:
      mazeRows = 5; 
      mazeCols = 5;
  }
}

// -----------------------------------------------------------------------------
// Inicializar Maze
// -----------------------------------------------------------------------------

void setupMaze() {
  println("[MAZE] setupMaze() => INICIO en " + millis() + " ms");

  // 1. Ajustar tamaño
  setMazeSizeFromLevel();

  // 2. Preparar la matriz visitedBFS antes de BFS
  visitedBFS = new boolean[mazeRows][mazeCols];

  // 3. Generar y validar
  generateAndValidateMaze();

  // 4. Inicializar wallColors y patchImages
  wallColors  = new color[mazeRows][mazeCols];
  patchImages = new PImage[mazeRows][mazeCols];
  for (int r = 0; r < mazeRows; r++) {
    for (int c = 0; c < mazeCols; c++) {
      wallColors[r][c]  = color(0, 0);
      patchImages[r][c] = null;
    }
  }

  // 5. PShape de pared (solo una vez)
  if (wallShape == null) {
    wallShape = createWallShape(wallImg, cellSize);
  }

  int needed = 5; 
  if (mazeRows == 15) needed = 15;
  if (mazeRows == 25) needed = 25;
  println("[MAZE] -> usaremos " + needed + " de las 25 imágenes globales.");

  // 7. Llamar a detectColoredWalls (que pondrá parches en patchImages[][])
  detectColoredWalls(needed);

  println("[MAZE] setupMaze() => FIN en " + millis() + " ms");
}

// -----------------------------------------------------------------------------
// Generación y Validación
// -----------------------------------------------------------------------------

void generateAndValidateMaze() {
  println("[MAZE] generateAndValidateMaze() => INICIO en " + millis() + " ms");

  boolean valid = false;
  int attempts = 0;
  while (!valid) {
    attempts++;
    generateMaze();

    // Forzar entrada y salida libres
    maze[entranceRow][entranceCol] = 0;
    maze[exitRow][exitCol] = 0;

    println("[MAZE] Intento #" + attempts + ": Comprobando conectividad BFS...");
    long startBFS = millis();
    valid = isConnectedBFS(entranceRow, entranceCol, exitRow, exitCol);
    long endBFS   = millis();
    println("[MAZE] BFS finalizado en " + (endBFS - startBFS) + " ms, valid=" + valid);

    if (!valid) {
      println("[MAZE] => no hay camino, se regenerará...");
    }
  }

  println("[MAZE] Maze valido tras " + attempts + " intentos:");
  for (int r = 0; r < mazeRows; r++) {
    String rowStr = "";
    for (int c = 0; c < mazeCols; c++) {
      rowStr += maze[r][c] + " ";
    }
    println(rowStr);
  }
  println("--------------------");
  println("[MAZE] generateAndValidateMaze() => FIN en " + millis() + " ms");
}

void generateMaze() {
  println("[MAZE] generateMaze() => INICIO en " + millis() + " ms");

  maze = new int[mazeRows][mazeCols];
  for (int r = 0; r < mazeRows; r++) {
    for (int c = 0; c < mazeCols; c++) {
      maze[r][c] = 1; // pared
    }
  }

  exitRow = mazeRows - 1;
  exitCol = int(random(1, mazeCols - 1));

  // Iniciar DFS en [1,1]
  maze[1][1] = 0;
  dfsCarve(1, 1);

  println("[MAZE] generateMaze() => FIN en " + millis() + " ms");
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
        // Abre el muro intermedio
        maze[(row + nr)/2][(col + nc)/2] = 0;
        dfsCarve(nr, nc);
      }
    }
  }
}

// -----------------------------------------------------------------------------
// BFS optimizado
// -----------------------------------------------------------------------------

boolean isConnectedBFS(int sr, int sc, int er, int ec) {
  if (maze[sr][sc] == 1 || maze[er][ec] == 1) return false;

  fillVisitedFalse();

  int[] queueR = new int[mazeRows * mazeCols];
  int[] queueC = new int[mazeRows * mazeCols];
  int front = 0;
  int back  = 0;

  // Encolar inicio
  queueR[back] = sr;
  queueC[back] = sc;
  back++;
  visitedBFS[sr][sc] = true;

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
        if (!visitedBFS[r2][c2] && maze[r2][c2] == 0) {
          visitedBFS[r2][c2] = true;
          queueR[back] = r2;
          queueC[back] = c2;
          back++;
        }
      }
    }
  }
  return false;
}

void fillVisitedFalse() {
  for (int r = 0; r < mazeRows; r++) {
    for (int c = 0; c < mazeCols; c++) {
      visitedBFS[r][c] = false;
    }
  }
}

void shuffleArray(int[] arr) {
  for (int i = arr.length - 1; i > 0; i--) {
    int idx = (int) random(i + 1);
    int temp = arr[idx];
    arr[idx] = arr[i];
    arr[i] = temp;
  }
}

// -----------------------------------------------------------------------------
// Detección de Paredes y Asignación de Parches
// -----------------------------------------------------------------------------

/**
 * Este método asigna imágenes (parches) a las paredes del laberinto utilizando una
 * estrategia de particionamiento en sectores y subsectores. De las 25 imágenes precargadas
 * globalmente (patchPoolGlobal), se utiliza un subconjunto determinado por el parámetro
 * 'needed' (5 para 5x5, 15 para 15x15 o 25 para 25x25).
 *
 * @param needed Número de imágenes globales a considerar para asignar parches.
 */
void detectColoredWalls(int needed) {
  println("[MAZE] detectColoredWalls() => INICIO en " + millis() + " ms");
  long startTime = millis();

  // Lógica de sectores (2 si >=15, 3 si >=25, etc.)
  int numSectors = 1;
  if (mazeRows >= 15) numSectors = 2;
  if (mazeRows >= 25) numSectors = 3;

  int sectorHeight = mazeRows / numSectors;
  int sectorWidth  = mazeCols / numSectors;

  int subDivRows = 2;
  int subDivCols = 4;

  int[][] deltas = { {-1, 0}, {1, 0}, {0, -1}, {0, 1} };
  int totalPatchesPlaced = 0;

  for (int i = 0; i < numSectors; i++) {
    for (int j = 0; j < numSectors; j++) {
      int sector_r_min = i * sectorHeight;
      int sector_r_max = (i == numSectors - 1) ? (mazeRows - 1) : (i+1)*sectorHeight - 1;
      int sector_c_min = j * sectorWidth;
      int sector_c_max = (j == numSectors - 1) ? (mazeCols - 1) : (j+1)*sectorWidth - 1;

      int subSectorHeight = max(1, (sector_r_max - sector_r_min + 1) / subDivRows);
      int subSectorWidth  = max(1, (sector_c_max - sector_c_min + 1) / subDivCols);

      for (int subRow = 0; subRow < subDivRows; subRow++) {
        for (int subCol = 0; subCol < subDivCols; subCol++) {
          int sub_r_min = sector_r_min + subRow * subSectorHeight;
          int sub_r_max = (subRow == subDivRows - 1) ? sector_r_max : sub_r_min + subSectorHeight - 1;
          int sub_c_min = sector_c_min + subCol * subSectorWidth;
          int sub_c_max = (subCol == subDivCols - 1) ? sector_c_max : sub_c_min + subSectorWidth - 1;

          int centerR = (sub_r_min + sub_r_max) / 2;
          int centerC = (sub_c_min + sub_c_max) / 2;

          boolean patchPlaced = false;

          // 1) Celda central libre => mirar paredes vecinas
          if (isInside(centerR, centerC) && maze[centerR][centerC] == 0) {
            for (int d = 0; d < 4; d++) {
              int nr = centerR + deltas[d][0];
              int nc = centerC + deltas[d][1];
              if (isInside(nr, nc) && maze[nr][nc] == 1 && patchImages[nr][nc] == null) {
                patchImages[nr][nc] = getRandomPatchFromGlobal(needed);
                totalPatchesPlaced++;
                patchPlaced = true;
                break;
              }
            }
          }

          // 2) Radio pequeño si no se pudo
          if (!patchPlaced) {
            int radius = 2;
            outer:
            for (int rr = max(sub_r_min, centerR - radius); rr <= min(sub_r_max, centerR + radius); rr++) {
              for (int cc = max(sub_c_min, centerC - radius); cc <= min(sub_c_max, centerC + radius); cc++) {
                if (isInside(rr, cc) && maze[rr][cc] == 0) {
                  for (int d = 0; d < 4; d++) {
                    int xr = rr + deltas[d][0];
                    int xc = cc + deltas[d][1];
                    if (isInside(xr, xc) && maze[xr][xc] == 1 && patchImages[xr][xc] == null) {
                      patchImages[xr][xc] = getRandomPatchFromGlobal(needed);
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

  long elapsed = millis() - startTime;
  println("[MAZE] detectColoredWalls() => Se colocaron " + totalPatchesPlaced + " parches. Tiempo: " + elapsed + " ms");
}

/**
 * Selecciona aleatoriamente una imagen del subconjunto de las 'needed' primeras imágenes
 * del pool global (patchPoolGlobal). Se garantiza que 'needed' se encuentra entre 1 y 25.
 *
 * @param needed Número de imágenes del pool global a considerar.
 * @return Una imagen seleccionada aleatoriamente o null si no están disponibles.
 */
PImage getRandomPatchFromGlobal(int needed) {
  if (!patchLoadComplete) {
    // Si el hilo no terminó, devolvemos null o un fallback
    println("[MAZE] WARNING: Los parches globales no están listos. Devolviendo null.");
    return null;
  }
  if (needed < 1) needed = 1; // seguridad
  if (needed > 25) needed = 25;

  int idx = int(random(needed)); // 0 .. needed-1
  return patchPoolGlobal[idx];
}

boolean isInside(int rr, int cc) {
  return (rr >= 0 && rr < mazeRows && cc >= 0 && cc < mazeCols);
}

// -----------------------------------------------------------------------------
// Dibujo del Laberinto en 3D
// -----------------------------------------------------------------------------

void drawMaze() {
  long startDraw = millis();
  pushMatrix();

  for (int r = 0; r < mazeRows; r++) {
    for (int c = 0; c < mazeCols; c++) {
      float cx = (c + 0.5) * cellSize;
      float cz = (r + 0.5) * cellSize;

      pushMatrix();
      translate(cx, cellSize / 2, cz);

      if (maze[r][c] == 1) {
        // Pared
        shape(wallShape);

        // Poner parche si existe
        if (patchImages[r][c] != null) {
          pushMatrix();
          translate(0, 0, -cellSize / 2 - 0.1);
          noStroke();
          float sz = cellSize * 0.3;
          beginShape(QUADS);
            texture(patchImages[r][c]);
            vertex(-sz/2, -sz/2, 0, 0, 0);
            vertex( sz/2, -sz/2, 0, patchImages[r][c].width, 0);
            vertex( sz/2,  sz/2, 0, patchImages[r][c].width, patchImages[r][c].height);
            vertex(-sz/2,  sz/2, 0, 0, patchImages[r][c].height);
          endShape();
          popMatrix();
        }
      } else {
        // Celda libre => checar si es la entrada o salida
        if (r == entranceRow && c == entranceCol) {
          drawPortal(false);
        } else if (r == exitRow && c == exitCol) {
          drawPortal(true);
        }
      }
      popMatrix();
    }
  }

  popMatrix();
}

// -----------------------------------------------------------------------------
// Crear un PShape (cubo con textura) para las paredes
// -----------------------------------------------------------------------------

PShape createWallShape(PImage tex, float size) {
  PShape s = createShape();
  float half = size / 2;

  s.beginShape(QUADS);
  s.texture(tex);

  // Cara frontal
  s.vertex(-half, -half,  half, 0, 0);
  s.vertex( half, -half,  half, tex.width, 0);
  s.vertex( half,  half,  half, tex.width, tex.height);
  s.vertex(-half,  half,  half, 0, tex.height);

  // Cara trasera
  s.vertex( half, -half, -half, 0, 0);
  s.vertex(-half, -half, -half, tex.width, 0);
  s.vertex(-half,  half, -half, tex.width, tex.height);
  s.vertex( half,  half, -half, 0, tex.height);

  // Cara izquierda
  s.vertex(-half, -half, -half, 0, 0);
  s.vertex(-half, -half,  half, tex.width, 0);
  s.vertex(-half,  half,  half, tex.width, tex.height);
  s.vertex(-half,  half, -half, 0, tex.height);

  // Cara derecha
  s.vertex( half, -half,  half, 0, 0);
  s.vertex( half, -half, -half, tex.width, 0);
  s.vertex( half,  half, -half, tex.width, tex.height);
  s.vertex( half,  half,  half, 0, tex.height);

  // Cara superior
  s.vertex(-half, -half, -half, 0, 0);
  s.vertex( half, -half, -half, tex.width, 0);
  s.vertex( half, -half,  half, tex.width, tex.height);
  s.vertex(-half, -half,  half, 0, tex.height);

  // Cara inferior
  s.vertex(-half,  half,  half, 0, 0);
  s.vertex( half,  half,  half, tex.width, 0);
  s.vertex( half,  half, -half, tex.width, tex.height);
  s.vertex(-half,  half, -half, 0, tex.height);

  s.endShape();
  return s;
}

// -----------------------------------------------------------------------------
// Dibujo del portal
// -----------------------------------------------------------------------------

void drawPortal(boolean isExit) {
  pushMatrix();

  if (!isExit) {
    // Entrada => orientada hacia -Z
    translate(0, 0, -cellSize/2 + 1);
    shape(createWallShape(portalEntry, cellSize));
    translate(0, 0, -0.5);
  } else {
    // Salida => orientada hacia +Z
    translate(0, 0, cellSize/2 - 1);
    shape(createWallShape(portalExit, cellSize));
    translate(0, 0, 0.5);
  }

  float t = millis() * 0.01;
  float scaleAmt = 1 + 0.3 * sin(t);
  float rad = cellSize * 0.6 * scaleAmt;

  rotateX(HALF_PI);
  noFill();
  strokeWeight(3);
  if (isExit) {
    stroke(255, 100, 100); // color rojizo
  } else {
    stroke(100, 255, 100); // color verdoso
  }
  ellipse(0, 0, rad, rad);

  popMatrix();
}
