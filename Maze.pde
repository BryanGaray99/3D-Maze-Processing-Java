// -------------------
// Maze.pde
// -------------------
import java.util.ArrayList;
import java.util.LinkedList;
import java.util.Queue;
import java.util.Collections;

int mazeRows=15;
int mazeCols=15;
int cellSize=40;

// 1=Pared, 0=Libre
int[][] maze;

int entranceRow=0;
int entranceCol=1;
int exitRow;
int exitCol;

// Matriz de color
color[][] wallColors;

/** Ajusta mazeRows/mazeCols según selectedLevel. 
    Llamada al generar el laberinto. */
void setMazeSizeFromLevel() {
  switch(selectedLevel) {
    case 1:
      mazeRows=15; mazeCols=15;
      break;
    case 2:
      mazeRows=25; mazeCols=25;
      break;
    case 3:
      mazeRows=35; mazeCols=35;
      break;
    default:
      mazeRows=15; mazeCols=15;
  }
}

/** Genera y valida el laberinto, luego parches de color */
void setupMaze() {
  println("[MAZE] setupMaze() => Empezar generacion");
  
  // Ajustar tamaño según el nivel
  setMazeSizeFromLevel();
  
  generateAndValidateMaze();
  
  detectColoredWalls();
}

/** Retorna true si (rr,cc) está dentro de la matriz */
boolean isInside(int rr,int cc){
  return (rr>=0 && rr<mazeRows && cc>=0 && cc<mazeCols);
}

void generateAndValidateMaze(){
  boolean valid=false;
  while(!valid){
    generateMaze();
    // Forzar entrada y salida
    maze[entranceRow][entranceCol]=0;
    maze[exitRow][exitCol]=0;
    valid=isConnectedBFS(entranceRow,entranceCol,exitRow,exitCol);
    if(!valid) {
      println("[MAZE] BFS => no hay camino, regenerando...");
    }
  }
  println("[MAZE] Maze válido! Imprimiendo matriz:");
  for(int r=0;r<mazeRows;r++){
    String rowStr="";
    for(int c=0;c<mazeCols;c++){
      rowStr+=(maze[r][c]+" ");
    }
    println(rowStr);
  }
  println("--------------------");
}

void generateMaze(){
  println("[MAZE] Generar Maze de "+mazeRows+" x "+mazeCols);
  maze=new int[mazeRows][mazeCols];
  for(int r=0;r<mazeRows;r++){
    for(int c=0;c<mazeCols;c++){
      maze[r][c]=1;
    }
  }
  exitRow=mazeRows-1;
  exitCol=int(random(1,mazeCols-1));
  
  maze[1][1]=0;
  dfsCarve(1,1);
}

void dfsCarve(int row,int col){
  int[] dirs={0,1,2,3};
  shuffleArray(dirs);
  for(int d:dirs){
    int nr=row, nc=col;
    switch(d){
      case 0: nr-=2; break;
      case 1: nc+=2; break;
      case 2: nr+=2; break;
      case 3: nc-=2; break;
    }
    if(nr>0 && nr<mazeRows-1 && nc>0 && nc<mazeCols-1){
      if(maze[nr][nc]==1){
        maze[nr][nc]=0;
        maze[(row+nr)/2][(col+nc)/2]=0;
        dfsCarve(nr,nc);
      }
    }
  }
}

boolean isConnectedBFS(int sr,int sc,int er,int ec){
  if(maze[sr][sc]==1 || maze[er][ec]==1) return false;
  boolean[][] visited=new boolean[mazeRows][mazeCols];
  int[] queueR=new int[mazeRows*mazeCols];
  int[] queueC=new int[mazeRows*mazeCols];
  int front=0, back=0;
  
  queueR[back]=sr;
  queueC[back]=sc;
  back++;
  visited[sr][sc]=true;
  
  int[] dr={-1,1,0,0};
  int[] dc={0,0,-1,1};

  while(front<back){
    int rr=queueR[front];
    int cc=queueC[front];
    front++;
    if(rr==er && cc==ec) return true;
    for(int i=0;i<4;i++){
      int r2=rr+dr[i];
      int c2=cc+dc[i];
      if(r2>=0 && r2<mazeRows && c2>=0 && c2<mazeCols){
        if(!visited[r2][c2] && maze[r2][c2]==0){
          visited[r2][c2]=true;
          queueR[back]=r2;
          queueC[back]=c2;
          back++;
        }
      }
    }
  }
  return false;
}

void shuffleArray(int[] arr){
  for(int i=arr.length-1;i>0;i--){
    int idx=(int)random(i+1);
    int temp=arr[idx];
    arr[idx]=arr[i];
    arr[i]=temp;
  }
}

void detectColoredWalls(){
  println("[MAZE] detectColoredWalls() => Parches");
  wallColors=new color[mazeRows][mazeCols];
  for(int r=0;r<mazeRows;r++){
    for(int c=0;c<mazeCols;c++){
      wallColors[r][c]=color(0,0);
    }
  }
  // Intersecciones
  ArrayList<int[]> intersections=new ArrayList<int[]>();
  for(int r=0;r<mazeRows;r++){
    for(int c=0;c<mazeCols;c++){
      if(maze[r][c]==0){
        int openCount=0;
        if(isInside(r-1,c)&&maze[r-1][c]==0) openCount++;
        if(isInside(r+1,c)&&maze[r+1][c]==0) openCount++;
        if(isInside(r,c-1)&&maze[r][c-1]==0) openCount++;
        if(isInside(r,c+1)&&maze[r][c+1]==0) openCount++;
        if(openCount>=2){
          intersections.add(new int[]{r,c});
        }
      }
    }
  }
  println("[MAZE] Intersections="+intersections.size());

  Collections.shuffle(intersections);
  int desired=max(1,intersections.size()/4);
  println("[MAZE] desired patches="+desired);
  
  ArrayList<int[]> chosenPatches=new ArrayList<int[]>();
  float minDist=4.0;
  int placed=0;

  for(int i=0; i<intersections.size() && placed<desired; i++){
    int rr=intersections.get(i)[0];
    int cc=intersections.get(i)[1];

    ArrayList<int[]> walls=new ArrayList<int[]>();
    if(isInside(rr-1,cc)&&maze[rr-1][cc]==1) walls.add(new int[]{rr-1,cc});
    if(isInside(rr+1,cc)&&maze[rr+1][cc]==1) walls.add(new int[]{rr+1,cc});
    if(isInside(rr,cc-1)&&maze[rr][cc-1]==1) walls.add(new int[]{rr,cc-1});
    if(isInside(rr,cc+1)&&maze[rr][cc+1]==1) walls.add(new int[]{rr,cc+1});

    if(walls.size()>0){
      int[] chosen=walls.get((int)random(walls.size()));
      int wr=chosen[0], wc=chosen[1];
      boolean tooClose=false;
      for(int[] cp: chosenPatches){
        float d=dist(wr,wc, cp[0],cp[1]);
        if(d<minDist){
          tooClose=true; break;
        }
      }
      if(!tooClose){
        color ccol=color(random(255),random(255),random(255));
        wallColors[wr][wc]=ccol;
        chosenPatches.add(new int[]{wr,wc});
        placed++;
      }
    }
  }
  println("[MAZE] placed="+placed+" patches.");
}

void drawMaze(){
  for(int r=0;r<mazeRows;r++){
    for(int c=0;c<mazeCols;c++){
      pushMatrix();
      float cx=(c+0.5)*cellSize;
      float cz=(r+0.5)*cellSize;
      translate(cx,cellSize/2, cz);

      if(maze[r][c]==1){
        pushStyle();
        texturedBox(cellSize, wallImg);
        popStyle();

        if(wallColors[r][c]!=color(0,0)){
          pushMatrix();
          pushStyle();
          translate(0,0,-cellSize/2-0.1);
          fill(wallColors[r][c]);
          noStroke();
          float sz=cellSize*0.3;
          beginShape(QUADS);
            vertex(-sz/2,-sz/2,0);
            vertex( sz/2,-sz/2,0);
            vertex( sz/2, sz/2,0);
            vertex(-sz/2, sz/2,0);
          endShape();
          popStyle();
          popMatrix();
        }
      }
      else if(r==entranceRow && c==entranceCol){
        pushStyle();
        pushMatrix();
        translate(0,0,-cellSize/2+1);
        texturedBox(cellSize, portalEntry);
        popMatrix();
        popStyle();
      }
      else if(r==exitRow && c==exitCol){
        pushStyle();
        pushMatrix();
        translate(0,0, cellSize/2-1);
        texturedBox(cellSize, portalExit);
        popMatrix();
        popStyle();
      }

      popMatrix();
    }
  }
}

void texturedBox(float size, PImage tex){
  float half=size/2;
  noFill();
  noStroke();
  // Cara frontal
  beginShape();
    texture(tex);
    vertex(-half,-half, half, 0,0);
    vertex( half,-half, half, tex.width,0);
    vertex( half, half, half, tex.width,tex.height);
    vertex(-half, half, half, 0,tex.height);
  endShape(CLOSE);

  // Cara trasera
  beginShape();
    texture(tex);
    vertex( half,-half,-half, 0,0);
    vertex(-half,-half,-half, tex.width,0);
    vertex(-half, half,-half, tex.width,tex.height);
    vertex( half, half,-half, 0,tex.height);
  endShape(CLOSE);

  // Cara izquierda
  beginShape();
    texture(tex);
    vertex(-half,-half,-half, 0,0);
    vertex(-half,-half, half, tex.width,0);
    vertex(-half, half, half, tex.width,tex.height);
    vertex(-half, half,-half, 0,tex.height);
  endShape(CLOSE);

  // Cara derecha
  beginShape();
    texture(tex);
    vertex( half,-half, half, 0,0);
    vertex( half,-half,-half, tex.width,0);
    vertex( half, half,-half, tex.width,tex.height);
    vertex( half, half, half, 0,tex.height);
  endShape(CLOSE);

  // Cara superior
  beginShape();
    texture(tex);
    vertex(-half,-half,-half, 0,0);
    vertex( half,-half,-half, tex.width,0);
    vertex( half,-half, half, tex.width,tex.height);
    vertex(-half,-half, half, 0,tex.height);
  endShape(CLOSE);

  // Cara inferior
  beginShape();
    texture(tex);
    vertex(-half, half, half, 0,0);
    vertex( half, half, half, tex.width,0);
    vertex( half, half,-half, tex.width,tex.height);
    vertex(-half, half,-half, 0,tex.height);
  endShape(CLOSE);
}
