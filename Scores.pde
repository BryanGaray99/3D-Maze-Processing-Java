// -------------------
// Scores.pde
// -------------------
ArrayList<ScoreEntry> scoresEasy   = new ArrayList<ScoreEntry>();
ArrayList<ScoreEntry> scoresMedium = new ArrayList<ScoreEntry>();
ArrayList<ScoreEntry> scoresHard   = new ArrayList<ScoreEntry>();

class ScoreEntry implements Comparable<ScoreEntry> {
  String name;
  int timeMs;
  
  ScoreEntry(String n, int t) {
    name=n;
    timeMs=t;
  }
  
  // Menor tiempo => mejor
  int compareTo(ScoreEntry other) {
    return this.timeMs - other.timeMs;
  }
}

/**
 * Guarda un nuevo resultado en la lista adecuada (easy, medium, hard),
 * ordena y persiste en disco.
 */
void saveScoreForLevel(String playerName, int timeMs, int level) {
  ScoreEntry se = new ScoreEntry(playerName, timeMs);
  ArrayList<ScoreEntry> ref = null;
  String levelStr="";

  switch(level){
    case 1: ref=scoresEasy;   levelStr="FACIL";   break;
    case 2: ref=scoresMedium; levelStr="MEDIO";   break;
    case 3: ref=scoresHard;   levelStr="DIFICIL"; break;
  }
  if(ref==null) return;

  ref.add(se);
  // Ordenar
  Collections.sort(ref);
  // Quedarnos con top 10 (o 3 si prefieres)
  while(ref.size()>10) {
    ref.remove(ref.size()-1);
  }
  println("[SCORES] Añadido => "+playerName+", "+timeMs+"ms, level="+levelStr);
  
  writeScores();
}

/**
 * Carga de "scores.txt", si existe.
 * Cada línea: "FACIL;NOMBRE;TIME"
 */
void loadScores() {
  String[] lines=null;
  try {
    lines=loadStrings("scores.txt");
  } catch(Exception e) {
    println("[SCORES] No existe scores.txt");
  }
  if(lines==null) return;

  for(String ln : lines) {
    String[] parts=ln.split(";");
    if(parts.length<3) continue;
    String levelStr = parts[0];
    String name     = parts[1];
    int t = int(parts[2]);

    ScoreEntry se=new ScoreEntry(name,t);
    if(levelStr.equals("FACIL"))   scoresEasy.add(se);
    if(levelStr.equals("MEDIO"))   scoresMedium.add(se);
    if(levelStr.equals("DIFICIL")) scoresHard.add(se);
  }

  Collections.sort(scoresEasy);
  Collections.sort(scoresMedium);
  Collections.sort(scoresHard);
  println("[SCORES] Cargados => Easy="+scoresEasy.size()
          +", Medium="+scoresMedium.size()
          +", Hard="+scoresHard.size());
}

/**
 * Escribe el array de scores en "scores.txt"
 */
void writeScores() {
  ArrayList<String> lines=new ArrayList<String>();

  // FÁCIL
  for(ScoreEntry s : scoresEasy) {
    lines.add("FACIL;"+s.name+";"+s.timeMs);
  }
  // MEDIO
  for(ScoreEntry s : scoresMedium) {
    lines.add("MEDIO;"+s.name+";"+s.timeMs);
  }
  // DIFÍCIL
  for(ScoreEntry s : scoresHard) {
    lines.add("DIFICIL;"+s.name+";"+s.timeMs);
  }

  // Sobrescribimos "scores.txt"
  saveStrings("scores.txt", lines.toArray(new String[0]));
  println("[SCORES] Guardado scores.txt con "+lines.size()+" líneas");
}
