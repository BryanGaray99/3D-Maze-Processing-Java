/**
 * Scores.pde administra el almacenamiento y la recuperacion
 * de los mejores tiempos de juego, divididos por nivel de dificultad.
 * Define estructuras para llevar puntajes en listas separadas (facil, medio, dificil)
 * y lee/escribe dichas listas en un archivo externo ("scores.txt").
 */
import java.util.ArrayList;
import java.util.Collections;
import java.io.File;

/** Lista de puntajes para el nivel facil. */
ArrayList<ScoreEntry> scoresEasy   = new ArrayList<ScoreEntry>();
/** Lista de puntajes para el nivel medio. */
ArrayList<ScoreEntry> scoresMedium = new ArrayList<ScoreEntry>();
/** Lista de puntajes para el nivel dificil. */
ArrayList<ScoreEntry> scoresHard   = new ArrayList<ScoreEntry>();

/**
 * Clase que representa una entrada de puntaje,
 * con un nombre de jugador y el tiempo en milisegundos.
 * Se implementa Comparable para poder ordenar por tiempo.
 */
class ScoreEntry implements Comparable<ScoreEntry> {
  String name;
  int timeMs;

  /**
   * Construye un ScoreEntry con el nombre y tiempo proporcionados.
   *
   * @param n Nombre del jugador
   * @param t Tiempo en milisegundos
   */
  ScoreEntry(String n, int t) {
    name = n;
    timeMs = t;
  }

  /**
   * Determina el criterio de comparacion basandose en
   * el tiempo (menor tiempo => mejor puntuacion).
   *
   * @param other Otra entrada de puntaje
   * @return diferencia entre timeMs propios y del otro
   */
  int compareTo(ScoreEntry other) {
    return this.timeMs - other.timeMs;
  }
}

/**
 * Guardamos un nuevo puntaje en la lista correspondiente al nivel dado,
 * lo ordena, reduce su tamano a un maximo (por ejemplo, top 10)
 * y finalmente persiste los resultados en el archivo de texto.
 *
 * @param playerName nombre del jugador
 * @param timeMs tiempo que tardo en finalizar, en milisegundos
 * @param level identificador de nivel (1=facil, 2=medio, 3=dificil)
 */
void saveScoreForLevel(String playerName, int timeMs, int level) {
  ScoreEntry se = new ScoreEntry(playerName, timeMs);
  ArrayList<ScoreEntry> ref = null;
  String levelStr = "";

  switch(level) {
    case 1: 
      ref = scoresEasy;   
      levelStr = "FACIL";   
      break;
    case 2: 
      ref = scoresMedium; 
      levelStr = "MEDIO";   
      break;
    case 3: 
      ref = scoresHard;   
      levelStr = "DIFICIL"; 
      break;
  }
  if (ref == null) return;

  ref.add(se);
  Collections.sort(ref);

  // Limita la lista a los 10 mejores
  while (ref.size() > 10) {
    ref.remove(ref.size() - 1);
  }
  println("[SCORES] Anadido => " + playerName + ", " + timeMs + "ms, level=" + levelStr);

  writeScores();
}

/**
 * Intentamos cargar un archivo "scores.txt" ubicado en la carpeta del sketch.
 * Cada linea del archivo debe tener el formato "FACIL;NOMBRE;TIME"
 * (o MEDIO/DIFICIL). Crea las entradas, las ordena y las
 * almacena en las listas correspondientes.
 */
void loadScores() {
  String filePath = sketchPath("scores.txt");
  File f = new File(filePath);
  if (!f.exists()) {
    println("[SCORES] No existe scores.txt en: " + filePath);
    return;
  }
  String[] lines = loadStrings(filePath);
  if (lines == null) return;

  for (String ln : lines) {
    String[] parts = ln.split(";");
    if (parts.length < 3) continue;
    String levelStr = parts[0];
    String name = parts[1];
    int t = int(parts[2]);

    ScoreEntry se = new ScoreEntry(name, t);
    if (levelStr.equals("FACIL"))   scoresEasy.add(se);
    if (levelStr.equals("MEDIO"))   scoresMedium.add(se);
    if (levelStr.equals("DIFICIL")) scoresHard.add(se);
  }

  // Ordena cada lista por tiempo ascendente
  Collections.sort(scoresEasy);
  Collections.sort(scoresMedium);
  Collections.sort(scoresHard);
  println("[SCORES] Cargados => Easy=" + scoresEasy.size()
          + ", Medium=" + scoresMedium.size()
          + ", Hard=" + scoresHard.size());
}

/**
 * Escribimos las listas de puntajes actuales en "scores.txt" usando el formato
 * "FACIL;NOMBRE;TIME". Esta funcion sobrescribe el archivo anterior.
 */
void writeScores() {
  ArrayList<String> lines = new ArrayList<String>();

  // Seccion FACIL
  for (ScoreEntry s : scoresEasy) {
    lines.add("FACIL;" + s.name + ";" + s.timeMs);
  }
  // Seccion MEDIO
  for (ScoreEntry s : scoresMedium) {
    lines.add("MEDIO;" + s.name + ";" + s.timeMs);
  }
  // Seccion DIFICIL
  for (ScoreEntry s : scoresHard) {
    lines.add("DIFICIL;" + s.name + ";" + s.timeMs);
  }

  String filePath = sketchPath("scores.txt");
  saveStrings(filePath, lines.toArray(new String[0]));
  println("[SCORES] Guardado scores.txt con " + lines.size() + " lineas en: " + filePath);
}
