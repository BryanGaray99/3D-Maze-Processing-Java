/**
 * Alumno: Bryan Enrique Garay Benavidez
 * Este es el archivo principal del proyecto, Laberinto3D.pde contiene tanto las variables globales como las funciones principales 
 * que gestionan el flujo del juego, la configuración de la ventana, la carga de texturas
 * y la visualización de las distintas pantallas (menús, laberinto, resultados, etc.).
 *
 * El juego se divide en varios estados:
 * <ul>
 *   <li>0 = Menu principal</li>
 *   <li>1 = Seleccion de nivel</li>
 *   <li>2 = Ingreso de nombre</li>
 *   <li>3 = Jugando</li>
 *   <li>4 = Pantalla de fin (mostrar tiempo)</li>
 *   <li>5 = Resultados</li>
 *   <li>6 = Cargando</li>
 *   <li>7 = Instrucciones</li>
 * </ul>
 *
 * El sistema tambien maneja el cronometro durante la partida, la deteccion de victoria
 * y la transicion entre pantallas de manera ordenada.
 */
import java.util.Collections;
import java.util.List;

/** Representa el estado actual del juego (0=Menu, 1=Seleccion, 2=Ingreso de nombre, etc.). */
int gameState = 0;

/** Almacena el nombre elegido por el usuario en la pantalla de ingreso. */
String playerName = "";

/** Determina el nivel seleccionado (1=Facil, 2=Medio, 3=Dificil). */
int selectedLevel = 1;

// -----------------------------------------------------------------------------
// Modulo de tiempo y deteccion de fin de partida
// -----------------------------------------------------------------------------

/** Registra el instante de inicio de la partida en milisegundos. */
int startTime = 0;

/** Guarda el total de milisegundos que tardo el jugador en ganar. */
int finalTime = 0;

/** Indica si el jugador alcanzo la salida del laberinto. */
boolean hasWon = false;

/** Marca cuando inicia la visualizacion del tiempo final, para controlar su duracion. */
int showTimeStart = 0;

/** Lapso en milisegundos durante el cual se mostrara el tiempo final en pantalla. */
int showTimeDuration = 5000;

/** Guarda el instante en que comienza la pantalla de "Cargando...". */
int loadingStart = 0;

/** Tiempo en milisegundos que permanecera la pantalla de "Cargando...". */
int loadingDelay = 5000;

// -----------------------------------------------------------------------------
// Texturas utilizadas para las paredes y portales del laberinto
// -----------------------------------------------------------------------------

/** Textura de las paredes del laberinto. */
PImage wallImg;

/** Textura asociada al portal de entrada. */
PImage portalEntry;

/** Textura asociada al portal de salida. */
PImage portalExit;

/**
 * Iniciamos el entorno de Processing en modo P3D, ajusta el tamano de la ventana
 * y desactiva el suavizado. Ademas, procede a cargar las texturas base (pared y portales),
 * recupera las puntuaciones almacenadas y define el estado inicial del juego.
 */
void setup() {
  size(800, 600, P3D);
  noSmooth();

  wallImg     = loadImage("wall-2.jpg");
  portalEntry = loadImage("portalEntry.jpg");
  portalExit  = loadImage("portalExit.jpg");

  // Recupera las puntuaciones previas
  loadScores();

  println("[SETUP] gameState=0 (Menu principal)");
}

/**
 * El Draw forma parte del bucle principal de Processing. Evalua el estado del juego
 * y decide que se dibuja en cada fotograma:
 * <ul>
 *   <li>Menus e interfaces (estados 0,1,2,5,7) se renderizan en 2D.</li>
 *   <li>La accion del laberinto (estado 3) se dibuja en 3D.</li>
 *   <li>La pantalla final (estado 4) muestra el tiempo total.</li>
 *   <li>La pantalla de carga (estado 6) exhibe una animacion temporal.</li>
 * </ul>
 */
void draw() {
  // Alterna el fondo en funcion de si se esta o no dentro del laberinto
  if (gameState == 3) {
    background(50);
  } else {
    background(0, 100, 120);
  }

  switch (gameState) {
    case 0: // Menu principal
    case 1: // Seleccion de nivel
    case 2: // Ingreso de nombre
    case 5: // Pantalla de resultados
    case 7: // Instrucciones
      // Se utiliza renderizado 2D para estos estados
      hint(DISABLE_DEPTH_TEST);
      camera();
      drawUI();
      hint(ENABLE_DEPTH_TEST);
      break;

    case 3: // Laberinto en 3D
      setupCamera();
      lights();
      if (!hasWon) {
        updatePlayer();
        checkWinCondition();
      } else {
        // Al detectar victoria, mide el tiempo final y pasa a la etapa de presentacion
        gameState = 4;
        finalTime = millis() - startTime;
        showTimeStart = millis();
        println("[GAME] Jugador gano en " + finalTime + "ms");
      }
      drawMaze();
      break;

    case 4: // Vista final con el tiempo logrado
      hint(DISABLE_DEPTH_TEST);
      camera();
      drawFinishTime();
      hint(ENABLE_DEPTH_TEST);
      break;

    case 6: // Pantalla de carga con animacion
      hint(DISABLE_DEPTH_TEST);
      camera();
      drawLoadingScreen();
      hint(ENABLE_DEPTH_TEST);
      break;
  }
}

/**
 * Ajustamos la camara 3D con un determinado campo de vision (FOV), la relacion de aspecto
 * y los planos de recorte cercano y lejano. Se aplica cuando se entra a la fase de juego.
 */
void setupCamera() {
  float fov = PI / 3.0;
  float aspect = float(width) / float(height);
  float nearClip = 10;
  float farClip  = 5000;
  perspective(fov, aspect, nearClip, farClip);
}

/**
 * Una vez que el jugador gana, se muestra en pantalla el tiempo final
 * y se espera un periodo determinado (showTimeDuration). 
 * Pasado ese intervalo, se registra el nuevo puntaje, se reinicia el juego
 * y se regresa al menu principal.
 */
void drawFinishTime() {
  int elapsed = millis() - showTimeStart;

  pushStyle();
  textAlign(CENTER, CENTER);
  fill(255);
  textSize(32);
  String niceTime = formatTime(finalTime);
  text("Tiempo final: " + niceTime, width / 2, height / 2);
  popStyle();

  if (elapsed > showTimeDuration) {
    println("[FINISH] Guardando score => " 
            + playerName + ", lvl=" + selectedLevel + ", tiempo=" + finalTime);
    saveScoreForLevel(playerName, finalTime, selectedLevel);

    hasWon = false;
    resetGame();
    gameState = 0;
    println("[FINISH] Volvemos al Menu (gameState=0)");
  }
}

/**
 * Reinicia las variables clave de la partida. Genera un nuevo laberinto
 * y posiciona al jugador en la entrada, asegurandose de dejar hasWon en falso.
 */
void resetGame() {
  hasWon = false;
  println("[RESET] setupMaze + resetPlayer");
  setupMaze();
  resetPlayer();
}

/**
 * Convertimos un valor en milisegundos a un formato comprensible,
 * incluyendo horas, minutos y segundos de manera condensada.
 *
 * @param ms cantidad de milisegundos a formatear
 * @return texto con la forma "Xh Ym Zs" (omitiendo componentes que sean cero)
 */
String formatTime(int ms) {
  int totalSecs = ms / 1000;
  int s = totalSecs % 60;
  int totalMins = totalSecs / 60;
  int m = totalMins % 60;
  int h = totalMins / 60;
  String str = "";
  if (h > 0) str += h + "h ";
  if (m > 0) str += m + "m ";
  if (s > 0 || (h == 0 && m == 0)) str += s + "s";
  return str.trim();
}

/**
 * Mostramos en pantalla el texto "CARGANDO..." junto a una figura rotando
 * de manera simple. Cuando transcurre el tiempo configurado en loadingDelay,
 * se procede a generar el laberinto y cambiar el estado a la fase de juego.
 */
void drawLoadingScreen() {
  int elapsed = millis() - loadingStart;

  pushStyle();
  background(0, 100, 120);
  textAlign(CENTER, CENTER);
  fill(255);
  textSize(30);
  text("CARGANDO...", width / 2, height / 2 - 100);

  // Se dibuja un cuadrado rotando en el centro
  pushMatrix();
  translate(width / 2, height / 2, 0);
  rotateZ(radians(elapsed * 0.2));
  fill(255, 100, 100);
  noStroke();
  rectMode(CENTER);
  rect(0, 0, 100, 100);
  popMatrix();

  popStyle();

  // Al cumplirse el tiempo de carga, inicializa laberinto y jugador
  if (elapsed > loadingDelay) {
    println("[LOADING] Generando laberinto tras " + elapsed + "ms de animacion");
    resetGame(); // Internamente hace setupMaze + resetPlayer
    startTime = millis();
    gameState = 3; // Estado de juego
  }
}
