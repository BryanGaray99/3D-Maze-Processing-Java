// -------------------
// UIManager.pde
// -------------------
void drawUI() {
  background(0,100,120);
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
  }
}

void drawMainMenu() {
  pushStyle();
  textAlign(CENTER, CENTER);
  fill(255);
  textSize(40);
  text("Menú Principal", width/2, 100);

  float bw=220, bh=60;
  float bx= width/2 - bw/2;
  float by= 200;

  // Botón JUGAR
  pushMatrix();
    pushStyle();
    if (mouseOverRect(bx,by,bw,bh)) fill(100,200,100);
    else fill(80);
    rect(bx,by,bw,bh);
    fill(255);
    textSize(20);
    text("Jugar", bx+bw/2, by+bh/2);
    popStyle();
  popMatrix();

  // Botón "Mejores Resultados"
  float by2=300;
  pushMatrix();
    pushStyle();
    if(mouseOverRect(bx,by2,bw,bh)) fill(100,200,100);
    else fill(80);
    rect(bx,by2,bw,bh);
    fill(255);
    textSize(20);
    text("Mejores Tiempos", bx+bw/2, by2+bh/2);
    popStyle();
  popMatrix();

  popStyle();
}

void drawSelectLevelMenu() {
  pushStyle();
  textAlign(CENTER,CENTER);
  fill(255);
  textSize(32);
  text("Selecciona un nivel :)", width/2, 100);

  float bw=550, bh=60;
  float bx= width/2 - bw/2;

  float byF=200; // Fácil
  pushMatrix();
    pushStyle();
    if(mouseOverRect(bx,byF,bw,bh)) fill(100,200,100);
    else fill(80);
    rect(bx,byF,bw,bh);
    fill(255);
    textSize(28);
    text("Fácil! 15x15 (Para pasar el rato!)", bx+bw/2, byF+bh/2);
    popStyle();
  popMatrix();

  float byM=300; // Medio
  pushMatrix();
    pushStyle();
    if(mouseOverRect(bx,byM,bw,bh)) fill(100,200,100);
    else fill(80);
    rect(bx,byM,bw,bh);
    fill(255);
    textSize(28);
    text("Medio: 25x25 (Para jugar con paciencia!)", bx+bw/2, byM+bh/2);
    popStyle();
  popMatrix();

  float byD=400; // Difícil
  pushMatrix();
    pushStyle();
    if(mouseOverRect(bx,byD,bw,bh)) fill(100,200,100);
    else fill(80);
    rect(bx,byD,bw,bh);
    fill(255);
    textSize(28);
    text("Dificil: 35x35 (Solo Para Valientes!)", bx+bw/2, byD+bh/2);
    popStyle();
  popMatrix();

  popStyle();
}

void drawEnterNameScreen() {
  pushStyle();
  textAlign(CENTER,CENTER);
  fill(255);
  textSize(32);
  text("Ingresa tu apodo de gamer :)", width/2, 120);

  float tw=300, th=50;
  float tx= width/2 - tw/2;
  float ty= 200;

  pushMatrix();
    pushStyle();
    fill(80);
    rect(tx, ty, tw, th);
    fill(255);
    textSize(20);
    text(playerName, tx+tw/2, ty+th/2);
    popStyle();
  popMatrix();

  float bw=100, bh=50;
  float bx= width/2 - bw/2;
  float by= 300;
  pushMatrix();
    pushStyle();
    if(mouseOverRect(bx,by,bw,bh)) fill(100,200,100);
    else fill(80);
    rect(bx,by,bw,bh);
    fill(255);
    textSize(20);
    text("OK", bx+bw/2, by+bh/2);
    popStyle();
  popMatrix();

  popStyle();
}

void drawScoresScreen() {
  pushStyle();
  textAlign(LEFT, CENTER);
  fill(255);
  textSize(36);
  text("Mejores Tiempos :)", 50,50);

  int yStart=120, yOffset=30;

  // FÁCIL
  textSize(24);
  text("FÁCIL:", 50,yStart);
  for(int i=0;i<min(3,scoresEasy.size());i++){
    ScoreEntry s=scoresEasy.get(i);
    text("  "+(i+1)+") "+s.name+" - "+formatTime(s.timeMs), 70,yStart+(i+1)*yOffset);
  }

  // MEDIO
  int block=120;
  text("MEDIO:", 50,yStart+block);
  for(int i=0;i<min(3,scoresMedium.size());i++){
    ScoreEntry s=scoresMedium.get(i);
    text("  "+(i+1)+") "+s.name+" - "+formatTime(s.timeMs), 70,yStart+block+(i+1)*yOffset);
  }

  // DIFÍCIL
  int block2=240;
  text("DIFÍCIL:", 50,yStart+block2);
  for(int i=0;i<min(3,scoresHard.size());i++){
    ScoreEntry s=scoresHard.get(i);
    text("  "+(i+1)+") "+s.name+" - "+formatTime(s.timeMs), 70,yStart+block2+(i+1)*yOffset);
  }

  // Botón VOLVER
  float bw=140,bh=50;
  float bx= width-bw-20;
  float by= height-bh-20;
  pushMatrix();
    pushStyle();
    if(mouseOverRect(bx,by,bw,bh)) fill(100,200,100);
    else fill(80);
    rect(bx,by,bw,bh);
    fill(255);
    textAlign(CENTER,CENTER);
    text("Volver", bx+bw/2, by+bh/2);
    popStyle();
  popMatrix();

  popStyle();
}

boolean mouseOverRect(float x,float y,float w,float h){
  return (mouseX>=x && mouseX<=x+w && mouseY>=y && mouseY<=y+h);
}
