// -------------------
// UIManager.pde
// -------------------
void drawUI() {
  // Fondo consistente en azul claro
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
 * Dibuja un botón moderno con bordes redondeados y cambio de color en hover.
 * Cada llamada se aísla con pushStyle()/popStyle().
 */
void drawModernButton(float x, float y, float w, float h, String label) {
  pushStyle();
    noStroke();
    if (mouseOverRect(x, y, w, h))
      fill(100, 200, 100);
    else
      fill(80);
    // Dibujamos el rectángulo con esquinas redondeadas (radio = 15)
    rect(x, y, w, h, 15);
    
    fill(255);
    textSize(20);
    textAlign(CENTER, CENTER);
    text(label, x + w/2, y + h/2);
  popStyle();
}

void drawMainMenu() {
  pushStyle();
    // Título y créditos
    textAlign(CENTER, CENTER);
    fill(255);
    textSize(40);
    text("Laberinto 3D", width/2, 100);
    
    textSize(20);
    text("By Bryan Garay", width/2, 160);

    // Parámetros comunes para botones
    float bw = 220, bh = 60;
    float bx = width/2 - bw/2;
    
    // Botón "Jugar"
    float by = 200;
    drawModernButton(bx, by, bw, bh, "Jugar");
    
    // Botón "Mejores Tiempos"
    float by2 = 300;
    drawModernButton(bx, by2, bw, bh, "Mejores Tiempos");
    
    // Botón "Instrucciones"
    float by3 = 400;
    drawModernButton(bx, by3, bw, bh, "Instrucciones");
  popStyle();
}

void drawSelectLevelMenu() {
  pushStyle();
    textAlign(CENTER, CENTER);
    fill(255);
    textSize(32);
    text("Selecciona un nivel :)", width/2, 100);

    float bw = 550, bh = 60;
    float bx = width/2 - bw/2;
    
    // Botón para nivel Fácil
    float byF = 200;
    drawModernButton(bx, byF, bw, bh, "Fácil! 15x15 (Para pasar el rato!)");
    
    // Botón para nivel Medio
    float byM = 300;
    drawModernButton(bx, byM, bw, bh, "Medio: 25x25 (Para jugar con paciencia!)");
    
    // Botón para nivel Difícil
    float byD = 400;
    drawModernButton(bx, byD, bw, bh, "Difícil: 35x35 (Solo Para Valientes!)");
  popStyle();
}

void drawEnterNameScreen() {
  pushStyle();
    textAlign(CENTER, CENTER);
    fill(255);
    textSize(32);
    text("Ingresa tu apodo de gamer :)", width/2, 120);

    // Caja de texto para el nombre
    float tw = 300, th = 50;
    float tx = width/2 - tw/2;
    float ty = 200;
    pushStyle();
      fill(80);
      noStroke();
      rect(tx, ty, tw, th, 10); // Esquinas suavizadas
      fill(255);
      textSize(20);
      textAlign(CENTER, CENTER);
      text(playerName, tx + tw/2, ty + th/2);
    popStyle();

    // Botón OK
    float bw = 100, bh = 50;
    float bx = width/2 - bw/2;
    float by = 300;
    drawModernButton(bx, by, bw, bh, "OK");
  popStyle();
}

void drawScoresScreen() {
  pushStyle();
    textAlign(LEFT, CENTER);
    fill(255);
    textSize(36);
    text("Mejores Tiempos :)", 50, 50);

    int yStart = 120, yOffset = 30;

    // Sección FÁCIL
    textSize(24);
    text("FÁCIL:", 50, yStart);
    for (int i = 0; i < min(3, scoresEasy.size()); i++) {
      ScoreEntry s = scoresEasy.get(i);
      text("  " + (i + 1) + ") " + s.name + " - " + formatTime(s.timeMs), 70, yStart + (i + 1) * yOffset);
    }

    // Sección MEDIO
    int block = 120;
    text("MEDIO:", 50, yStart + block);
    for (int i = 0; i < min(3, scoresMedium.size()); i++) {
      ScoreEntry s = scoresMedium.get(i);
      text("  " + (i + 1) + ") " + s.name + " - " + formatTime(s.timeMs), 70, yStart + block + (i + 1) * yOffset);
    }

    // Sección DIFÍCIL
    int block2 = 240;
    text("DIFÍCIL:", 50, yStart + block2);
    for (int i = 0; i < min(3, scoresHard.size()); i++) {
      ScoreEntry s = scoresHard.get(i);
      text("  " + (i + 1) + ") " + s.name + " - " + formatTime(s.timeMs), 70, yStart + block2 + (i + 1) * yOffset);
    }

    // Botón VOLVER
    float bw = 140, bh = 50;
    float bx = width - bw - 20;
    float by = height - bh - 20;
    drawModernButton(bx, by, bw, bh, "Volver");
  popStyle();
}

/**
 * Nueva pantalla de Instrucciones (gameState == 7).
 * Se muestran las indicaciones de juego y los controles, junto con un botón "Volver"
 * para regresar al menú principal.
 */
void drawInstructionsScreen() {
  pushStyle();
    textAlign(CENTER, CENTER);
    fill(255);
    textSize(32);
    text("Instrucciones", width/2, 80);
    
    textSize(20);
    // Texto de instrucciones (se puede ajustar el interlineado usando \n)
    String instrucciones = 
      "Después de ingresar tu apodo se inicia el juego.\n" +
      "Debes encontrar la salida del laberinto, que se identifica\n" +
      "por una puerta abierta en la pared final.\n\n" +
      "Controles:\n" +
      "• Flechas: Movimiento ↑ Adelante | ↓ Atras | ← Izquierda | → Derecha\n" +
      "• E: Girar la cámara a la izquierda\n" +
      "• Q: Girar la cámara a la derecha";
    text(instrucciones, width/2, 250);
    
    // Botón VOLVER
    float bw = 140, bh = 50;
    float bx = width - bw - 20;
    float by = height - bh - 20;
    drawModernButton(bx, by, bw, bh, "Volver");
  popStyle();
}
