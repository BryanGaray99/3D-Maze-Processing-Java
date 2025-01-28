// -------------------
// Input.pde
// -------------------
boolean up=false, down=false, strafeLeft=false, strafeRight=false;
boolean turnLeft=false, turnRight=false;

void keyPressed() {
  // Movimiento solo si gameState=3 (jugando)
  if(gameState==3) {
    if(keyCode==UP)   up=true;
    if(keyCode==DOWN) down=true;
    if(keyCode==LEFT) strafeLeft=true;
    if(keyCode==RIGHT)strafeRight=true;
    if(key=='e'||key=='E') turnLeft=true;
    if(key=='q'||key=='Q') turnRight=true;
  }
  
  // Pantalla de ingresar nombre
  if(gameState==2) {
    if(key==BACKSPACE && playerName.length()>0) {
      playerName=playerName.substring(0, playerName.length()-1);
    }
    else if(key==ENTER||key==RETURN) {
      if(playerName.trim().length()>0) {
        println("[UI] Enter con nombre='"+playerName+"'");
        // En vez de generar Maze al instante => vamos a gameState=6 (cargando)
        gameState=6;
        loadingStart=millis();
        println("[UI] => gameState=6 (cargando)");
      }
    }
    else if(key!=CODED) {
      playerName+=key;
    }
  }
}

void keyReleased() {
  if(gameState==3) {
    if(keyCode==UP)   up=false;
    if(keyCode==DOWN) down=false;
    if(keyCode==LEFT) strafeLeft=false;
    if(keyCode==RIGHT)strafeRight=false;
    if(key=='e'||key=='E') turnLeft=false;
    if(key=='q'||key=='Q') turnRight=false;
  }
}

void mousePressed() {
  println("[MOUSE] Click en ("+mouseX+","+mouseY+"), gameState="+gameState);
  
  switch(gameState) {
    case 0:
      // Botón JUGAR
      if(mouseOverRect(width/2-110,200,220,60)) {
        println("[UI] Botón 'JUGAR'");
        gameState=1;
      }
      // Botón Mejores Resultados
      else if(mouseOverRect(width/2-110,300,220,60)) {
        println("[UI] Botón 'MEJORES RESULTADOS'");
        gameState=5;
      }
      break;

    case 1: // Selección nivel
      if(mouseOverRect(width/2-100,200,200,60)) {
        println("[UI] Nivel FÁCIL");
        selectedLevel=1;
        gameState=2;
      }
      else if(mouseOverRect(width/2-100,300,200,60)) {
        println("[UI] Nivel MEDIO");
        selectedLevel=2;
        gameState=2;
      }
      else if(mouseOverRect(width/2-100,400,200,60)) {
        println("[UI] Nivel DIFÍCIL");
        selectedLevel=3;
        gameState=2;
      }
      break;

    case 2: // Nombre
      if(mouseOverRect(width/2-50,300,100,50)) {
        println("[UI] Botón OK con nombre='"+playerName+"'");
        if(playerName.trim().length()>0) {
          // Ir a pantalla CARGANDO
          gameState=6;
          loadingStart=millis();
          println("[UI] => gameState=6 (cargando)");
        }
        else {
          println("[UI] Nombre vacío, no iniciamos");
        }
      }
      break;

    case 5: // Ver scores
      // Botón VOLVER
      if(mouseOverRect(width-160, height-70, 140,50)) {
        println("[UI] Botón VOLVER en Scores");
        gameState=0;
      }
      break;
  }
}
