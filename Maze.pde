/**
 * Maze.pde administra la generacion, validacion y dibujo del laberinto
 * en 3D. Define las dimensiones segun el nivel seleccionado, genera el trazado de
 * celdas libres y paredes, y situa un portal de entrada y otro de salida.
 *
 * Tambien introduce un sistema de "parches" que se traducen en imagenes random
 * obtenidas de https://picsum.photos/200.jpg, las cuales se ubican en paredes
 * seleccionadas mediante un algoritmo de sectorizado, el fin de estos parches
 * es dar pistas al usuario de su ubicación en el laberinto.
 */
import java.util.ArrayList;
import java.util.LinkedList;
import java.util.Queue;
import java.util.Collections;

/** Numero de filas que tendra el laberinto. */
int mazeRows = 16;
/** Numero de columnas que tendra el laberinto. */
int mazeCols = 16;
/** Tamano en pixeles que representara cada celda del laberinto. */
int cellSize = 40;

/** Matriz que almacena 1 para paredes y 0 para celdas libres. */
int[][] maze;

/** Fila que marca la entrada del laberinto. */
int entranceRow = 0;
/** Columna que marca la entrada del laberinto. */
int entranceCol = 1;
/** Fila que marca la salida del laberinto. */
int exitRow;
/** Columna que marca la salida del laberinto. */
int exitCol;

/** Matriz para guardar la imagen de cada "parche" cuando corresponde a una pared. */
PImage[][] patchImages;

/** Matriz de colores para asignaciones antiguas (se deja como referencia). */
color[][] wallColors;

/**
 * Ajustamos la cantidad de filas y columnas del laberinto
 * segun el nivel seleccionado. Se invoca antes de generar el laberinto.
 */
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

/**
 * Invocamos al comenzar una partida o al reiniciar el juego. Configura las dimensiones
 * segun el nivel, genera el laberinto y prepara tanto la matriz de colores como
 * la de imagenes. Finalmente llama a detectColoredWalls() para situar los "parches".
 */
void setupMaze() {
  println("[MAZE] setupMaze() => Empezar generacion");

  // Ajuste del tamano del laberinto en funcion del nivel
  setMazeSizeFromLevel();

  // Generacion del trazado y posterior validacion
  generateAndValidateMaze();

  // Inicializa ambas matrices: wallColors y patchImages
  wallColors = new color[mazeRows][mazeCols];
  patchImages = new PImage[mazeRows][mazeCols];
  for (int r = 0; r < mazeRows; r++) {
    for (int c = 0; c < mazeCols; c++) {
      wallColors[r][c] = color(0, 0);
      patchImages[r][c] = null;
    }
  }

  // Llama al metodo que localiza y coloca parches de imagen
  detectColoredWalls();
}

/**
 * Verificamos si las coordenadas (rr, cc) se encuentran dentro de los limites del laberinto.
 *
 * @param rr indice de fila
 * @param cc indice de columna
 * @return true si rr, cc se ubican dentro de la matriz
 */
boolean isInside(int rr, int cc) {
  return (rr >= 0 && rr < mazeRows && cc >= 0 && cc < mazeCols);
}

/**
 * Generamos el laberinto y comprueba que exista un camino entre
 * la entrada y la salida. Repite la generacion hasta que sea valido.
 */
void generateAndValidateMaze() {
  boolean valid = false;
  while (!valid) {
    generateMaze();
    // Fuerza que entrada y salida sean celdas libres
    maze[entranceRow][entranceCol] = 0;
    maze[exitRow][exitCol] = 0;
    valid = isConnectedBFS(entranceRow, entranceCol, exitRow, exitCol);
    if (!valid) {
      println("[MAZE] BFS => no hay camino, regenerando...");
    }
  }
  println("[MAZE] Maze valido! Imprimiendo matriz:");
  for (int r = 0; r < mazeRows; r++) {
    String rowStr = "";
    for (int c = 0; c < mazeCols; c++) {
      rowStr += (maze[r][c] + " ");
    }
    println(rowStr);
  }
  println("--------------------");
}

/**
 * Generamos la matriz del laberinto, inicializando todas las celdas como paredes (1),
 * y luego ejecuta un proceso DFS para cavar senderos en celdas libres (0).
 * Tambien asigna aleatoriamente la ubicacion de la salida en la ultima fila.
 */
void generateMaze() {
  println("[MAZE] Generar Maze de " + mazeRows + " x " + mazeCols);
  maze = new int[mazeRows][mazeCols];
  for (int r = 0; r < mazeRows; r++) {
    for (int c = 0; c < mazeCols; c++) {
      maze[r][c] = 1;  // Comienza con todo paredes
    }
  }
  exitRow = mazeRows - 1;
  exitCol = int(random(1, mazeCols - 1));

  // Punto de partida para el DFS
  maze[1][1] = 0;
  dfsCarve(1, 1);
}

/**
 * Realizamos el tallado del laberinto mediante un DFS recursivo.
 * En cada paso, elige un orden aleatorio de direcciones y abre camino
 * si la nueva celda es pared, creando pasillos.
 *
 * @param row fila actual
 * @param col columna actual
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
        // Se abre el muro intermedio entre (row, col) y (nr, nc)
        maze[(row + nr) / 2][(col + nc) / 2] = 0;
        dfsCarve(nr, nc);
      }
    }
  }
}

/**
 * Empleamos un recorrido BFS para verificar si hay conexion entre la posicion
 * de entrada (sr, sc) y la de salida (er, ec).
 *
 * @param sr fila de inicio
 * @param sc columna de inicio
 * @param er fila de destino
 * @param ec columna de destino
 * @return true si se encuentra un camino libre entre entrada y salida
 */
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

/**
 * Mezclamos aleatoriamente los elementos de un arreglo de enteros,
 * utilizando swaps sobre indices aleatorios, para lograr variedad
 * en la direccion del tallado DFS.
 *
 * @param arr arreglo de direcciones que se va a reordenar
 */
void shuffleArray(int[] arr) {
  for (int i = arr.length - 1; i > 0; i--) {
    int idx = (int)random(i + 1);
    int temp = arr[idx];
    arr[idx] = arr[i];
    arr[i] = temp;
  }
}

/**
 * Exploramos el laberinto para ubicar posibles paredes donde colocar
 * imagenes aleatorias (en lugar de un parche de color). Aplica
 * una estrategia de sectorizado para distribuir dichas imagenes.
 */
void detectColoredWalls() {
  println("[MAZE] detectColoredWalls() => Estrategia sectorizada para colocar imagenes aleatorias");

  int numSectors = 2;
  if (mazeRows >= 25) numSectors = 3;
  if (mazeRows >= 35) numSectors = 4;

  int sectorHeight = mazeRows / numSectors;
  int sectorWidth  = mazeCols / numSectors;

  int subDivRows = 2;
  int subDivCols = 4;

  // Direcciones de vecindad vertical/horizontal
  int[][] deltas = { {-1, 0}, {1, 0}, {0, -1}, {0, 1} };

  int totalPatchesPlaced = 0;

  for (int i = 0; i < numSectors; i++) {
    for (int j = 0; j < numSectors; j++) {
      int sector_r_min = i * sectorHeight;
      int sector_r_max = (i == numSectors - 1) ? mazeRows - 1 : (i + 1) * sectorHeight - 1;
      int sector_c_min = j * sectorWidth;
      int sector_c_max = (j == numSectors - 1) ? mazeCols - 1 : (j + 1) * sectorWidth - 1;

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

          // Primero se intenta colocar alrededor de la celda central si es libre
          if (maze[centerR][centerC] == 0) {
            for (int d = 0; d < 4; d++) {
              int nr = centerR + deltas[d][0];
              int nc = centerC + deltas[d][1];
              if (isInside(nr, nc) && maze[nr][nc] == 1 && patchImages[nr][nc] == null) {
                patchImages[nr][nc] = loadImage("https://picsum.photos/200.jpg");
                totalPatchesPlaced++;
                patchPlaced = true;
                break;
              }
            }
          }

          // Si no se logro colocar en la celda central, se busca en un radio cercano
          if (!patchPlaced) {
            int radius = 2;
            outer:
            for (int r = max(sub_r_min, centerR - radius); r <= min(sub_r_max, centerR + radius); r++) {
              for (int c = max(sub_c_min, centerC - radius); c <= min(sub_c_max, centerC + radius); c++) {
                if (maze[r][c] == 0) {
                  for (int d = 0; d < 4; d++) {
                    int nr = r + deltas[d][0];
                    int nc = c + deltas[d][1];
                    if (isInside(nr, nc) && maze[nr][nc] == 1 && patchImages[nr][nc] == null) {
                      patchImages[nr][nc] = loadImage("https://picsum.photos/200.jpg");
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
  println("[MAZE] placed=" + totalPatchesPlaced + " random-image patches.");
}

/**
 * Dibujamos todas las celdas del laberinto en 3D. Las que son paredes
 * se pintan con la textura correspondiente; las celdas libres verifican
 * si son la entrada o la salida, dibujando un portal animado en cada caso.
 */
void drawMaze() {
  for (int r = 0; r < mazeRows; r++) {
    for (int c = 0; c < mazeCols; c++) {
      pushMatrix();
      float cx = (c + 0.5) * cellSize;
      float cz = (r + 0.5) * cellSize;
      translate(cx, cellSize / 2, cz);

      if (maze[r][c] == 1) {
        // Pared
        pushStyle();
        texturedBox(cellSize, wallImg);
        popStyle();

        // Verificacion de parche de imagen
        if (patchImages[r][c] != null) {
          pushMatrix();
          pushStyle();
          // Se ajusta levemente la posicion en -Z para pegar la imagen en la pared frontal
          translate(0, 0, -cellSize / 2 - 0.1);
          noStroke();
          float sz = cellSize * 0.3;

          // Dibuja la imagen random en una cara de tamano reducido
          beginShape(QUADS);
            texture(patchImages[r][c]);
            vertex(-sz/2, -sz/2, 0, 0, 0);
            vertex( sz/2, -sz/2, 0, patchImages[r][c].width, 0);
            vertex( sz/2,  sz/2, 0, patchImages[r][c].width, patchImages[r][c].height);
            vertex(-sz/2,  sz/2, 0, 0, patchImages[r][c].height);
          endShape();

          popStyle();
          popMatrix();
        }
      } else {
        // Celda libre: se comprueba si es la entrada o la salida para dibujar un portal
        if (r == entranceRow && c == entranceCol) {
          drawPortal(false);
        } else if (r == exitRow && c == exitCol) {
          drawPortal(true);
        }
      }
      popMatrix();
    }
  }
}

/**
 * Dibujamos una caja con la textura especificada, representando una pared
 * en cada una de sus caras.
 *
 * @param size tamano de la cara (en pixeles)
 * @param tex textura que se aplicara en cada cara del cubo
 */
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

/**
 * Dibujamos un "portal" de entrada o salida, con una textura distinta
 * segun si se trata del punto de partida o de la meta del laberinto.
 * Aplica un efecto de pulso y rotacion para simular un portal animado.
 *
 * @param isExit indica si se trata de la salida (true) o de la entrada (false)
 */
void drawPortal(boolean isExit) {
  pushStyle();
  pushMatrix();

  if (!isExit) {
    // Entrada orientada hacia -Z
    translate(0, 0, -cellSize/2 + 1);
    texturedBox(cellSize, portalEntry);
    translate(0, 0, -0.5);
  } else {
    // Salida orientada hacia +Z
    translate(0, 0, cellSize/2 - 1);
    texturedBox(cellSize, portalExit);
    translate(0, 0, 0.5);
  }

  // Efecto de pulso dinamico
  float t = millis() * 0.01;
  float scaleAmt = 1 + 0.3 * sin(t);
  float rad = cellSize * 0.6 * scaleAmt;

  // Se gira para quedar frente al jugador
  rotateX(HALF_PI);

  noFill();
  strokeWeight(3);
  stroke(isExit ? color(255, 100, 100) : color(100, 255, 100));
  ellipse(0, 0, rad, rad);

  popMatrix();
  popStyle();
}
