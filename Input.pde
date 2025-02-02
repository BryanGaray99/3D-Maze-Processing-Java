/**
 * Input.pde administra la interaccion a traves del teclado y el raton.
 * Define banderas para el movimiento y la rotacion del jugador, ademas de manejar
 * la seleccion de opciones en pantalla mediante clicks.
 */

// -----------------------------------------------------------------------------
// Variables para controlar movimiento y rotacion por teclado
// -----------------------------------------------------------------------------

/** Indica si el jugador se esta desplazando hacia adelante. */
boolean up = false;
/** Indica si el jugador se esta desplazando hacia atras. */
boolean down = false;
/** Indica si el jugador se esta desplazando lateralmente hacia la izquierda. */
boolean strafeLeft = false;
/** Indica si el jugador se esta desplazando lateralmente hacia la derecha. */
boolean strafeRight = false;
/** Indica si el jugador esta girando la camara a la izquierda. */
boolean turnLeft = false;
/** Indica si el jugador esta girando la camara a la derecha. */
boolean turnRight = false;

/**
 * Detectamos la pulsacion de teclas y ajusta las banderas de movimiento o rotacion
 * cuando el juego esta en el estado de partida (gameState == 3). Tambien gestiona
 * la edicion del nombre del jugador en el estado de ingreso (gameState == 2).
 */
void keyPressed() {
  // Movimientos solo aplicables en la fase de juego
  if (gameState == 3) {
    if (keyCode == UP)    up = true;
    if (keyCode == DOWN)  down = true;
    if (keyCode == LEFT)  strafeLeft = true;
    if (keyCode == RIGHT) strafeRight = true;
    if (key == 'e' || key == 'E') turnLeft = true;
    if (key == 'q' || key == 'Q') turnRight = true;
  }

  // Edicion del nombre en la pantalla de ingreso
  if (gameState == 2) {
    if (key == BACKSPACE && playerName.length() > 0) {
      playerName = playerName.substring(0, playerName.length() - 1);
    }
    else if (key == ENTER || key == RETURN) {
      if (playerName.trim().length() > 0) {
        println("[UI] Enter con nombre='" + playerName + "'");
        // Se pasa a la pantalla de carga (estado 6) en lugar de generar el laberinto inmediatamente
        gameState = 6;
        loadingStart = millis();
        println("[UI] => gameState=6 (cargando)");
      }
    }
    else if (key != CODED) {
      playerName += key;
    }
  }
}

/**
 * Detectamos la liberacion de teclas y desactiva las banderas
 * de movimiento o rotacion cuando el juego esta en marcha (gameState == 3).
 */
void keyReleased() {
  if (gameState == 3) {
    if (keyCode == UP)    up = false;
    if (keyCode == DOWN)  down = false;
    if (keyCode == LEFT)  strafeLeft = false;
    if (keyCode == RIGHT) strafeRight = false;
    if (key == 'e' || key == 'E') turnLeft = false;
    if (key == 'q' || key == 'Q') turnRight = false;
  }
}

/**
 * Gestionamos el clic del raton, registrando la posicion donde se hizo clic
 * y, segun el estado actual del juego, determina cual boton se ha presionado.
 * Esto abarca la navegacion por el menu principal, seleccion de nivel,
 * ingreso de nombre y otras pantallas de interfaz.
 */
void mousePressed() {
  println("[MOUSE] Click en (" + mouseX + "," + mouseY + "), gameState=" + gameState);

  switch (gameState) {
    case 0:
      // Boton "Jugar"
      if (mouseOverRect(width/2 - 110, 200, 220, 60)) {
        println("[UI] Boton 'JUGAR'");
        gameState = 1;
      }
      // Boton "Mejores Resultados"
      else if (mouseOverRect(width/2 - 110, 300, 220, 60)) {
        println("[UI] Boton 'MEJORES RESULTADOS'");
        gameState = 5;
      }
      // Boton "Instrucciones"
      else if (mouseOverRect(width/2 - 110, 400, 220, 60)) {
        println("[UI] Boton 'INSTRUCCIONES'");
        gameState = 7;
      }
      break;

    case 1:
      // Seleccion de nivel
      if (mouseOverRect(width/2 - 100, 200, 200, 60)) {
        println("[UI] Nivel FACIL");
        selectedLevel = 1;
        gameState = 2;
      }
      else if (mouseOverRect(width/2 - 100, 300, 200, 60)) {
        println("[UI] Nivel MEDIO");
        selectedLevel = 2;
        gameState = 2;
      }
      else if (mouseOverRect(width/2 - 100, 400, 200, 60)) {
        println("[UI] Nivel DIFICIL");
        selectedLevel = 3;
        gameState = 2;
      }
      break;

    case 2:
      // Pantalla de ingreso de nombre: boton OK
      if (mouseOverRect(width/2 - 50, 300, 100, 50)) {
        println("[UI] Boton OK con nombre='" + playerName + "'");
        if (playerName.trim().length() > 0) {
          gameState = 6;
          loadingStart = millis();
          println("[UI] => gameState=6 (cargando)");
        }
        else {
          println("[UI] Nombre vacio, no iniciamos");
        }
      }
      break;

    case 5:
      // Pantalla de Mejores Resultados: boton VOLVER
      if (mouseOverRect(width - 160, height - 70, 140, 50)) {
        println("[UI] Boton VOLVER en Scores");
        gameState = 0;
      }
      break;

    case 7:
      // Pantalla de Instrucciones: boton VOLVER
      if (mouseOverRect(width - 160, height - 70, 140, 50)) {
        println("[UI] Boton VOLVER en Instrucciones");
        gameState = 0;
      }
      break;
  }
}

/**
 * Verificamos si la posicion actual del raton se encuentra dentro de
 * un rectangulo definido por x, y, w, h.
 *
 * @param x coordenada X superior izquierda del rectangulo
 * @param y coordenada Y superior izquierda del rectangulo
 * @param w ancho del rectangulo
 * @param h alto del rectangulo
 * @return true si (mouseX, mouseY) cae dentro de los limites de ese rectangulo
 */
boolean mouseOverRect(float x, float y, float w, float h) {
  return (mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h);
}
