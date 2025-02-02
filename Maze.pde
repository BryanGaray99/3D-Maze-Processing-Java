/**
 * Maze.pde
 *
 * Niveles:
 *   1 => 5x5
 *   2 => 15x15
 *   3 => 25x25
 *
 * Objetivos:
 *   - Cargar SOLO la cantidad de imágenes necesaria (no exceder).
 *   - Mantener BFS optimizado y lógica de sectores para parches.
 *   - Evitar recargar parches si el nivel no ha cambiado.
 *
 * Notas:
 *   - Se asume que en el archivo principal (Laberinto3D.pde) se declaran:
 *       PImage wallImg, portalEntry, portalExit;
 *     y se cargan en setup().
 */

import java.util.ArrayList;
import java.util.LinkedList;
import java.util.Queue;
import java.util.Collections;

// -----------------------------------------------------------------------------
// Parámetros y variables globales
// -----------------------------------------------------------------------------

int mazeRows = 5;
int mazeCols = 5;
int cellSize = 40;

int[][] maze;          // 1 => pared, 0 => libre
int entranceRow = 0;
int entranceCol = 1;
int exitRow;
int exitCol;

/** Para cada pared (r,c) que tenga parche, guarda la imagen. */
PImage[][] patchImages;

/** Matriz de colores (referencia). */
color[][] wallColors;

/** BFS optimizado: matriz global para "visitado". */
boolean[][] visitedBFS;

/** 
 * Pool de imágenes para parches. 
 * Se dimensiona según el nivel elegido (5, 15 o 25).
 */
PImage[] patchPool = null; 

/** Tamaño actual del pool (cuántas imágenes se cargaron). */
int patchPoolSize = 0;

/** Nivel anterior para detectar si cambió el nivel y recargar parches si hace falta. */
int lastLevelLoaded = -1;

/** 
 * PShape de la pared con textura (cubo),
 * para no hacer `beginShape()/endShape()` repetidamente.
 */
PShape wallShape = null;

// -----------------------------------------------------------------------------
// Ajustar tamaño de laberinto según el nivel
// -----------------------------------------------------------------------------

void setMazeSizeFromLevel() {
  switch(selectedLevel) {
    case 1:
      // nivel fácil => 5x5
      mazeRows = 5;
      mazeCols = 5;
      break;
    case 2:
      // nivel medio => 15x15
      mazeRows = 15;
      mazeCols = 15;
      break;
    case 3:
      // nivel difícil => 25x25
      mazeRows = 25;
      mazeCols = 25;
      break;
    default:
      mazeRows = 5;
      mazeCols = 5;
  }
}

// -----------------------------------------------------------------------------
// Función auxiliar: Retorna cuántas imágenes "parche" precargar según el tamaño
// -----------------------------------------------------------------------------

int computePatchPoolSize() {
  // Aquí decides la cantidad justa:
  // - 5x5 => 5 imágenes
  // - 15x15 => 15 imágenes
  // - 25x25 => 25 imágenes
  // Ajusta si deseas un criterio distinto
  if (mazeRows == 5 && mazeCols == 5) return 5;
  if (mazeRows == 15 && mazeCols == 15) return 15;
  if (mazeRows == 25 && mazeCols == 25) return 25;
  return 5; // fallback
}

// -----------------------------------------------------------------------------
// Inicialización del laberinto
// -----------------------------------------------------------------------------

void setupMaze() {
  println("[MAZE] setupMaze() => INICIO en " + millis() + " ms");

  // 1. Ajustar filas y columnas según el nivel
  setMazeSizeFromLevel();

  // 2. Crear visitedBFS antes de BFS (evita NullPointer)
  visitedBFS = new boolean[mazeRows][mazeCols];

  // 3. Generar y validar el laberinto (usa BFS)
  generateAndValidateMaze();

  // 4. Inicializar matrices de colores y parches
  wallColors  = new color[mazeRows][mazeCols];
  patchImages = new PImage[mazeRows][mazeCols];
  for (int r = 0; r < mazeRows; r++) {
    for (int c = 0; c < mazeCols; c++) {
      wallColors[r][c]  = color(0, 0);
      patchImages[r][c] = null;
    }
  }

  // 5. Crear el PShape de pared (una sola vez, si aún no existe)
  if (wallShape == null) {
    wallShape = createWallShape(wallImg, cellSize);
  }

  // 6. Cargar SOLO la cantidad de imágenes necesaria para este nivel
  int needed = computePatchPoolSize();

  // Revisar si ya cargamos las imágenes para este nivel (o sea, si lastLevelLoaded == selectedLevel).
  // Si el nivel cambió, o no hay patchPool, o su tamaño difiere => recargamos.
  if (selectedLevel != lastLevelLoaded || patchPool == null || patchPoolSize != needed) {
    println("[MAZE] -> Se requiere cargar parches para el nivel " + selectedLevel + " ...");
    patchPoolSize = needed;
    patchPool = new PImage[patchPoolSize];
    preloadPatchImages();
    lastLevelLoaded = selectedLevel;
  } else {
    println("[MAZE] -> Ya teníamos parches cargados para este nivel (" + selectedLevel + "); no recargamos.");
  }

  // 7. Detectar paredes y asignar parches
  detectColoredWalls();

  println("[MAZE] setupMaze() => FIN en " + millis() + " ms");
}

// -----------------------------------------------------------------------------
// Generación y validación del laberinto
// -----------------------------------------------------------------------------

void generateAndValidateMaze() {
  println("[MAZE] generateAndValidateMaze() => INICIO en " + millis() + " ms");

  boolean valid = false;
  int attempts  = 0;
  while (!valid) {
    attempts++;
    generateMaze();

    // Forzamos que entrada y salida sean libres
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

  println("[MAZE] Maze válido tras " + attempts + " intentos. Imprimiendo matriz:");
  for (int r = 0; r < mazeRows; r++) {
    String rowStr = "";
    for (int c = 0; c < mazeCols; c++) {
      rowStr += (maze[r][c] + " ");
    }
    println(rowStr);
  }
  println("--------------------");
  println("[MAZE] generateAndValidateMaze() => FIN en " + millis() + " ms");
}

// Genera todo paredes y "cava" con DFS
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

/**
 * DFS recursivo para "cavar" pasillos.
 */
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
// BFS optimizado con matriz global visitedBFS
// -----------------------------------------------------------------------------

boolean isConnectedBFS(int sr, int sc, int er, int ec) {
  if (maze[sr][sc] == 1 || maze[er][ec] == 1) return false;

  fillVisitedFalse();

  int[] queueR = new int[mazeRows * mazeCols];
  int[] queueC = new int[mazeRows * mazeCols];
  int front = 0;
  int back  = 0;

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
// Precarga de parches (imagenes de picsum), SOLO la cantidad necesaria
// -----------------------------------------------------------------------------

void preloadPatchImages() {
  println("[MAZE] preloadPatchImages() => INICIO en " + millis() + " ms");
  for (int i = 0; i < patchPoolSize; i++) {
    // Añadimos ?seed para forzar imágenes diferentes
    String url = "https://picsum.photos/200.jpg?seed=" + i;
    patchPool[i] = loadImage(url);
    println("[MAZE]   -> patchPool[" + i + "] desde " + url);
  }
  println("[MAZE] preloadPatchImages() => FIN en " + millis() + " ms");
}

// -----------------------------------------------------------------------------
// Deteccion de paredes para parches (lógica de sectores)
// -----------------------------------------------------------------------------

void detectColoredWalls() {
  println("[MAZE] detectColoredWalls() => INICIO en " + millis() + " ms");
  long startTime = millis();

  // Mantén tu lógica de sectores:
  // (ejemplo con 2 sectores si >=15, 3 si >=25, etc. Ajusta a gusto)
  int numSectors = 1;
  if (mazeRows >= 15) numSectors = 2;
  if (mazeRows >= 25) numSectors = 3;

  int sectorHeight = mazeRows / numSectors;
  int sectorWidth  = mazeCols / numSectors;

  // Divisiones internas
  int subDivRows = 2;
  int subDivCols = 4;

  // Direcciones para buscar paredes adyacentes
  int[][] deltas = { {-1, 0}, {1, 0}, {0, -1}, {0, 1} };
  int totalPatchesPlaced = 0;

  // Recorrer cada sector
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

          // 1) Ver si la celda central es libre, y si hay pared adyacente
          if (isInside(centerR, centerC) && maze[centerR][centerC] == 0) {
            for (int d = 0; d < 4; d++) {
              int nr = centerR + deltas[d][0];
              int nc = centerC + deltas[d][1];
              if (isInside(nr, nc) && maze[nr][nc] == 1 && patchImages[nr][nc] == null) {
                patchImages[nr][nc] = getRandomPatchImage();
                totalPatchesPlaced++;
                patchPlaced = true;
                break;
              }
            }
          }

          // 2) Si no se logró, busca en un radio pequeño
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
                      patchImages[xr][xc] = getRandomPatchImage();
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
  println("[MAZE] detectColoredWalls() => Se colocaron " + totalPatchesPlaced + " parches en " + elapsed + " ms");
}

// Retorna una imagen aleatoria de las precargadas
PImage getRandomPatchImage() {
  if (patchPool == null || patchPoolSize <= 0) {
    return null; // fallback, por seguridad
  }
  int idx = int(random(patchPoolSize));
  return patchPool[idx];
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

        // Si hay parche en la cara frontal
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
  long elapsedDraw = millis() - startDraw;
  println("[MAZE] drawMaze() => Completado en " + elapsedDraw + " ms");
}

// -----------------------------------------------------------------------------
// Creación de PShape (cubo con textura) para paredes
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
// Dibujo de portales
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
