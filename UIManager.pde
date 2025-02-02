/**
 * UIManager.pde contiene la gestion de la interfaz de usuario
 * para los diferentes estados del juego. Se encarga de dibujar menus,
 * pantallas de seleccion de nivel, ingreso de nombre, tabla de puntajes e
 * instrucciones, asi como los botones que permiten la navegacion.
 */

/**
 * Funcion principal de UI que determina cual pantalla se dibuja segun
 * el estado actual del juego (gameState). Aplica un fondo azul claro y
 * luego delega en las funciones que dibujan cada pantalla concreta.
 */
void drawUI() {
  background(0, 100, 120);
  
  switch(gameState) {
    case 0:
      drawMainMenu();
      break;
    case 1:
      drawSelectLevelMenu();
      break;
    case 2:
      drawEnterNameScreen();
      break;
    case 5:
      drawScoresScreen();
      break;
    case 7:
      drawInstructionsScreen();
      break;
  }
}

/**
 * Dibujamos un boton con estilo "moderno": bordes redondeados,
 * cambio de color al pasar el mouse (hover) y texto centrado.
 *
 * @param x coordenada X de la esquina superior izquierda
 * @param y coordenada Y de la esquina superior izquierda
 * @param w ancho del boton
 * @param h alto del boton
 * @param label texto que se mostrara dentro del boton
 */
void drawModernButton(float x, float y, float w, float h, String label) {
  pushStyle();
    noStroke();
    if (mouseOverRect(x, y, w, h))
      fill(100, 200, 100);
    else
      fill(80);

    rect(x, y, w, h, 15); // Bordes redondeados (radio=15)

    fill(255);
    textSize(20);
    textAlign(CENTER, CENTER);
    text(label, x + w/2, y + h/2);
  popStyle();
}

/**
 * Dibujamos la pantalla principal, mostrando el titulo "Laberinto 3D",
 * creditos y botones para iniciar partida, ver puntuaciones o ver instrucciones.
 */
void drawMainMenu() {
  pushStyle();
    textAlign(CENTER, CENTER);
    fill(255);
    textSize(40);
    text("Laberinto 3D", width/2, 100);

    textSize(20);
    text("By Bryan Garay", width/2, 160);

    float bw = 220, bh = 60;
    float bx = width/2 - bw/2;

    // Boton "Jugar"
    float by = 200;
    drawModernButton(bx, by, bw, bh, "Jugar");

    // Boton "Mejores Tiempos"
    float by2 = 300;
    drawModernButton(bx, by2, bw, bh, "Mejores Tiempos");

    // Boton "Instrucciones"
    float by3 = 400;
    drawModernButton(bx, by3, bw, bh, "Instrucciones");
  popStyle();
}

/**
 * Dibujamos la pantalla de seleccion de nivel, presentando opciones
 * para un laberinto facil, medio o dificil. Cada boton dispara
 * la creacion del laberinto en un tamaño distinto.
 */
void drawSelectLevelMenu() {
  pushStyle();
    textAlign(CENTER, CENTER);
    fill(255);
    textSize(32);
    text("Selecciona un nivel :)", width/2, 100);

    float bw = 550, bh = 60;
    float bx = width/2 - bw/2;

    // Niveles con distintas dificultades
    float byF = 200;
    drawModernButton(bx, byF, bw, bh, "Fácil! 5x5 (Para pasar el rato!)");

    float byM = 300;
    drawModernButton(bx, byM, bw, bh, "Medio: 15x15 (Para jugar con paciencia!)");

    float byD = 400;
    drawModernButton(bx, byD, bw, bh, "Difícil: 25x25 (Solo Para Valientes!)");
  popStyle();
}

/**
 * Pantalla para ingresar el nombre o apodo del jugador. Contiene
 * una caja de texto para escribir, y un boton "OK" para avanzar
 * al proceso de carga del laberinto.
 */
void drawEnterNameScreen() {
  pushStyle();
    textAlign(CENTER, CENTER);
    fill(255);
    textSize(32);
    text("Ingresa tu apodo de gamer :)", width/2, 120);

    // Caja de texto
    float tw = 300, th = 50;
    float tx = width/2 - tw/2;
    float ty = 200;
    pushStyle();
      fill(80);
      noStroke();
      rect(tx, ty, tw, th, 10);
      fill(255);
      textSize(20);
      textAlign(CENTER, CENTER);
      text(playerName, tx + tw/2, ty + th/2);
    popStyle();

    // Boton OK
    float bw = 100, bh = 50;
    float bx = width/2 - bw/2;
    float by = 300;
    drawModernButton(bx, by, bw, bh, "OK");
  popStyle();
}

/**
 * Desplegamos la pantalla de puntuaciones, mostrando un top 3 para
 * cada nivel (Facil, Medio, Dificil), seguido de un boton para volver
 * al menu principal.
 */
void drawScoresScreen() {
  pushStyle();
    textAlign(LEFT, CENTER);
    fill(255);
    textSize(36);
    text("Mejores Tiempos :)", 50, 50);

    int yStart = 120, yOffset = 30;

    // Seccion FACIL
    textSize(24);
    text("FÁCIL:", 50, yStart);
    for (int i = 0; i < min(3, scoresEasy.size()); i++) {
      ScoreEntry s = scoresEasy.get(i);
      text("  " + (i + 1) + ") " + s.name + " - " + formatTime(s.timeMs), 
           70, yStart + (i + 1) * yOffset);
    }

    // Seccion MEDIO
    int block = 140;
    text("MEDIO:", 50, yStart + block);
    for (int i = 0; i < min(3, scoresMedium.size()); i++) {
      ScoreEntry s = scoresMedium.get(i);
      text("  " + (i + 1) + ") " + s.name + " - " + formatTime(s.timeMs),
           70, yStart + block + (i + 1) * yOffset);
    }

    // Seccion DIFICIL
    int block2 = 300;
    text("DIFÍCIL:", 50, yStart + block2);
    for (int i = 0; i < min(3, scoresHard.size()); i++) {
      ScoreEntry s = scoresHard.get(i);
      text("  " + (i + 1) + ") " + s.name + " - " + formatTime(s.timeMs),
           70, yStart + block2 + (i + 1) * yOffset);
    }

    // Boton VOLVER
    float bw = 140, bh = 50;
    float bx = width - bw - 20;
    float by = height - bh - 20;
    drawModernButton(bx, by, bw, bh, "Volver");
  popStyle();
}

/**
 * Pantalla de instrucciones (estado 7). Presenta los conceptos basicos del juego,
 * asi como la lista de controles disponibles. Incluye un boton para regresar al menu.
 */
void drawInstructionsScreen() {
  pushStyle();
    textAlign(CENTER, CENTER);
    fill(255);
    textSize(32);
    text("Instrucciones", width/2, 80);

    textSize(20);
    String instrucciones =
      "Después de ingresar tu apodo se inicia el juego.\n" +
      "Debes encontrar la salida del laberinto, que se identifica\n" +
      "por una puerta abierta en la pared final.\n\n" +
      "Controles:\n" +
      "• Flechas: Movimiento ↑ Adelante | ↓ Atras | ← Izquierda | → Derecha\n" +
      "• E: Girar la camara a la izquierda\n" +
      "• Q: Girar la camara a la derecha";
    text(instrucciones, width/2, 250);

    // Boton VOLVER
    float bw = 140, bh = 50;
    float bx = width - bw - 20;
    float by = height - bh - 20;
    drawModernButton(bx, by, bw, bh, "Volver");
  popStyle();
}
