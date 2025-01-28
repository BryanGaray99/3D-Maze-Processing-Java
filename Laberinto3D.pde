// -------------------
// Laberinto3D.pde
// -------------------
import java.util.Collections;
import java.util.List;

// Estados de juego
int gameState = 0;  // 0=Menú principal, 1=SelecNivel, 2=IngresaNombre, 
                    // 3=Jugando, 4=Fin (tiempo), 5=VerResultados, 6=Cargando
String playerName = "";  
int selectedLevel = 1; // 1=Fácil, 2=Medio, 3=Difícil

// Para medir tiempo
int startTime = 0;
int finalTime = 0;
boolean hasWon = false;
int showTimeStart = 0;
int showTimeDuration = 5000; // 5s

// Pantalla "Cargando"
int loadingStart = 0; 
int loadingDelay = 10000;  // 10s de pantalla "Cargando"

// Texturas
PImage wallImg, portalEntry, portalExit;

void setup() {
  size(800, 600, P3D);
  noSmooth();

  wallImg      = loadImage("wall-2.jpg");
  portalEntry  = loadImage("portalEntry.jpg");
  portalExit   = loadImage("portalExit.jpg");

  // Carga de puntuaciones
  loadScores();
  
  println("[SETUP] gameState=0 (Menú principal)");
}

void draw() {
  background(50);

  switch(gameState) {
    case 0: // Menú principal
    case 1: // Selección de nivel
    case 2: // Ingreso de nombre
    case 5: // Ver resultados
      hint(DISABLE_DEPTH_TEST);
      camera();
      drawUI();
      hint(ENABLE_DEPTH_TEST);
      break;

    case 3: // Jugando laberinto
      setupCamera();
      lights();
      if (!hasWon) {
        updatePlayer();   // (Player.pde original)
        checkWinCondition();
      } else {
        gameState = 4;
        finalTime = millis() - startTime;
        showTimeStart = millis();
        println("[GAME] Jugador ganó en "+finalTime+"ms");
      }
      drawMaze(); // (Maze.pde)
      break;

    case 4: // Mostrando tiempo final
      hint(DISABLE_DEPTH_TEST);
      camera();
      drawFinishTime();
      hint(ENABLE_DEPTH_TEST);
      break;

    case 6: // Cargando...
      hint(DISABLE_DEPTH_TEST);
      camera();
      drawLoadingScreen();
      hint(ENABLE_DEPTH_TEST);
      break;
  }
}

void setupCamera() {
  float fov = PI/3.0;
  float aspect = float(width)/float(height);
  float nearClip = 10;
  float farClip  = 5000;
  perspective(fov, aspect, nearClip, farClip);
}

void drawFinishTime() {
  int elapsed = millis() - showTimeStart;
  
  pushStyle();
  textAlign(CENTER, CENTER);
  fill(255);
  textSize(32);
  String niceTime = formatTime(finalTime);
  text("Tiempo final: " + niceTime, width/2, height/2);
  popStyle();

  if (elapsed > showTimeDuration) {
    println("[FINISH] Guardando score => "+playerName+", lvl="+selectedLevel+", tiempo="+finalTime);
    saveScoreForLevel(playerName, finalTime, selectedLevel);
    
    hasWon=false;
    resetGame(); 
    gameState=0;
    println("[FINISH] Volvemos a Menú (gameState=0)");
  }
}

void resetGame() {
  hasWon=false;
  println("[RESET] setupMaze + resetPlayer");
  setupMaze(); 
  resetPlayer(); 
}

String formatTime(int ms) {
  int totalSecs = ms/1000;
  int s = totalSecs % 60;
  int totalMins = totalSecs/60;
  int m = totalMins % 60;
  int h = totalMins / 60;
  String str="";
  if(h>0) str+=h+"h ";
  if(m>0) str+=m+"m ";
  if(s>0||(h==0&&m==0)) str+=s+"s";
  return str.trim();
}

/** Pantalla "Cargando" con animación */
void drawLoadingScreen() {
  int elapsed = millis() - loadingStart;
  
  pushStyle();
  background(0,100,120);
  textAlign(CENTER, CENTER);
  fill(255);
  textSize(30);
  text("CARGANDO...", width/2, height/2 - 100);
  
  // Figura rotando
  pushMatrix();
  translate(width/2, height/2, 0);
  rotateZ(radians(elapsed*0.2)); // gira lento
  fill(255,100,100);
  noStroke();
  rectMode(CENTER);
  rect(0,0,100,100);
  popMatrix();
  
  popStyle();

  // Si pasaron N milisegundos, generamos el laberinto y vamos a gameState=3
  if (elapsed > loadingDelay) {
    println("[LOADING] Generando laberinto tras "+elapsed+"ms de animación");
    resetGame(); // hace setupMaze + resetPlayer
    startTime = millis();
    gameState = 3; // jugar
  }
}
