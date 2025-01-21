// File: Input.pde

boolean up = false, down = false, strafeLeft = false, strafeRight = false;
boolean turnLeft = false, turnRight = false;

void keyPressed() {
  if (keyCode == UP)    up = true;
  if (keyCode == DOWN)  down = true;
  if (keyCode == LEFT)  strafeLeft = true;
  if (keyCode == RIGHT) strafeRight = true;
  if (key == 'e' || key == 'E') turnLeft = true;
  if (key == 'q' || key == 'Q') turnRight = true;
}

void keyReleased() {
  if (keyCode == UP)    up = false;
  if (keyCode == DOWN)  down = false;
  if (keyCode == LEFT)  strafeLeft = false;
  if (keyCode == RIGHT) strafeRight = false;
  if (key == 'e' || key == 'E') turnLeft = false;
  if (key == 'q' || key == 'Q') turnRight = false;
}
