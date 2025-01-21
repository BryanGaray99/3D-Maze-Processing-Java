// File: Maze.pde

import java.util.ArrayList;
import java.util.Stack;
import java.util.Random;
import java.util.Arrays;

// Dimensiones y celda
int mazeRows = 10;
int mazeCols = 10;
int cellSize = 50;

// Matriz del laberinto (0 = libre, 1 = pared)
int[][] maze;

// Generador
MazeGenerator mg;

// =================================================================
// Función para inicializar/generar el laberinto dinámicamente
// =================================================================
void setupMaze() {
  mg = new MazeGenerator(mazeRows);
  mg.generateMaze();

  // El generador crea "1" donde hay camino y "0" donde hay "pared".
  // Necesitamos invertirlo porque en tu drawMaze() y colisiones, "1" es pared.
  int[][] raw = mg.getMazeArray();
  maze = new int[mazeRows][mazeCols];

  for (int row = 0; row < mazeRows; row++) {
    for (int col = 0; col < mazeCols; col++) {
      // Invertir: donde era 1 (camino), ponemos 0 => libre
      //           donde era 0 (pared),   ponemos 1 => pared
      maze[row][col] = (raw[row][col] == 1) ? 0 : 1;
    }
  }

  printMazeToConsole();
}

// =================================================================
// Función para dibujar el laberinto en 3D
// =================================================================
void drawMaze() {
  for (int row = 0; row < mazeRows; row++) {
    for (int col = 0; col < mazeCols; col++) {
      if (maze[row][col] == 1) {
        pushMatrix();
        float boxX = (col + 0.5) * cellSize;
        float boxZ = (row + 0.5) * cellSize;
        translate(boxX, cellSize / 2, boxZ);

        // Ejemplo de color según posición:
        if (row == 0 && (col == 0 || col == 2)) {
          fill(255, 0, 0); // Entrada(s) en la fila 0
        } else if ((row == 7 && col == 9) || (row == 9 && col == 9)) {
          fill(0, 255, 0); // Salida(s) en una parte final
        } else {
          fill(100, 100, 200); // Pared normal
        }

        box(cellSize, cellSize, cellSize);
        popMatrix();
      }
    }
  }
}

// =================================================================
// Función para imprimir la matriz del laberinto en la consola
// =================================================================
void printMazeToConsole() {
  println("Matriz del Laberinto (1 = pared, 0 = camino):");
  for (int row = 0; row < mazeRows; row++) {
    String rowString = "";
    for (int col = 0; col < mazeCols; col++) {
      rowString += maze[row][col];
      if (col < mazeCols - 1) {
        rowString += " ";
      }
    }
    println(rowString);
  }
}

// =================================================================
// Clase para generar laberinto usando DFS (Stack)
// =================================================================
class MazeGenerator {
  private Stack<Node> stack = new Stack<Node>();
  private Random rand = new Random();
  private int[][] mazeArray;   // 1 = camino excavado, 0 = no excavado (pared)
  private int dimension;

  MazeGenerator(int dim) {
    dimension = dim;
    mazeArray = new int[dim][dim];
    for(int y = 0; y < dimension; y++) {
      for(int x = 0; x < dimension; x++) {
        mazeArray[y][x] = 0; // Inicialmente todas las celdas son paredes
      }
    }
  }

  public void generateMaze() {
    stack.push(new Node(0, 0));
    mazeArray[0][0] = 1; // Entrada libre
    while (!stack.empty()) {
      Node current = stack.pop();
      ArrayList<Node> neighbors = findNeighbors(current);
      if (!neighbors.isEmpty()) {
        stack.push(current);
        Node next = neighbors.get(rand.nextInt(neighbors.size()));
        if (mazeArray[next.y][next.x] == 0) {
          mazeArray[next.y][next.x] = 1; // Camino libre
          stack.push(next);
        }
      }
    }
    mazeArray[dimension-1][dimension-1] = 1; // Salida libre
  }

  public int[][] getMazeArray() {
    return mazeArray;
  }

  public String getRawMaze() {
    StringBuilder sb = new StringBuilder();
    for (int[] row : mazeArray) {
      sb.append(Arrays.toString(row)).append("\n");
    }
    return sb.toString();
  }

  public String getSymbolicMaze() {
    StringBuilder sb = new StringBuilder();
    for (int i = 0; i < dimension; i++) {
      for (int j = 0; j < dimension; j++) {
        sb.append(mazeArray[i][j] == 1 ? "*" : " ");
        sb.append(" ");
      }
      sb.append("\n");
    }
    return sb.toString();
  }

  private boolean validNextNode(Node node) {
    // Revisa celdas adyacentes ya excavadas:
    int numNeighboringOnes = 0;
    for (int y = node.y - 1; y <= node.y + 1; y++) {
      for (int x = node.x - 1; x <= node.x + 1; x++) {
        if (pointOnGrid(x, y) && pointNotNode(node, x, y) && mazeArray[y][x] == 1) {
          numNeighboringOnes++;
        }
      }
    }
    // Evitamos que se formen "cuadrados" cerrados (si ya hay demasiadas celdas vecinas = 1)
    // y que no se excave una celda dos veces
    return (numNeighboringOnes < 3) && mazeArray[node.y][node.x] != 1;
  }

  private void randomlyAddNodesToStack(ArrayList<Node> nodes) {
    while (!nodes.isEmpty()) {
      int targetIndex = rand.nextInt(nodes.size());
      stack.push(nodes.remove(targetIndex));
    }
  }

  private ArrayList<Node> findNeighbors(Node node) {
    ArrayList<Node> neighbors = new ArrayList<>();
    for (int y = node.y - 1; y <= node.y + 1; y++) {
      for (int x = node.x - 1; x <= node.x + 1; x++) {
        if (pointOnGrid(x, y)
            && pointNotCorner(node, x, y)
            && pointNotNode(node, x, y)) {
          neighbors.add(new Node(x, y));
        }
      }
    }
    return neighbors;
  }

  private boolean pointOnGrid(int x, int y) {
    return x >= 0 && y >= 0 && x < dimension && y < dimension;
  }

  private boolean pointNotCorner(Node node, int x, int y) {
    // Evitar diagonales; solo celdas arriba/abajo/izq/dcha
    return (x == node.x || y == node.y);
  }

  private boolean pointNotNode(Node node, int x, int y) {
    return !(x == node.x && y == node.y);
  }
}

// =================================================================
// Clase auxiliar Node
// =================================================================
class Node {
  int x, y;
  Node(int x, int y) {
    this.x = x;
    this.y = y;
  }
}
