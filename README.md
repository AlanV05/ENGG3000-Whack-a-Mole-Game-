# ENGG3000 Whack-a-Mole Game

A Whack-a-Mole game developed in Python using Pygame as part of the ENGG3000 project.

## Requirements

Before running the game, make sure you have:

- Python 3
- Pygame

## Install Pygame

If Pygame is not installed, run:

```bash
python3 -m pip install pygame
```

## Compile / Check for Syntax Errors

Before running the game, check the Python file for syntax errors:

```bash
python3 -m py_compile whack_a_mole.py
```

If no error message appears, the code has passed the syntax check.

## Run the Game

Run the game using:

```bash
python3 whack_a_mole.py
```

## How to Play

1. Start the game by running `whack_a_mole.py`.
2. Wait for the mole to appear from one of the holes.
3. Move the hammer over the mole.
4. Double-click the mole to hit it.
5. Each successful hit increases your score.
6. The mole will continue appearing at different positions.
7. Try to hit as many moles as possible before the timer reaches zero.
8. When the game ends, press `R` to restart.
9. Press `ESC` to quit the game.

## Main Game Features

- 3 × 3 Whack-a-Mole grid
- Random mole spawning
- Animated mole movement
- Hammer mouse cursor
- Hammer hit animation
- Soil particle effects when the mole appears
- Score tracking
- Countdown timer
- Double-click hit detection
- Game-over screen
- Restart functionality
- Custom mole and background images

## Project Files

```text
ENGG3000-Whack-a-Mole-Game-/
├── whack_a_mole.py
├── background.png.jpg
├── mole.png
├── hammer.png
├── README.md
└── .gitignore
```

### `whack_a_mole.py`

Contains the main game logic, including:

- Game loop
- Mole movement
- Mole spawning
- Hit detection
- Hammer cursor
- Soil particle animation
- Score system
- Timer
- Game-over and restart functionality

### `background.png.jpg`

Contains the background image used for the game.

### `mole.png`

Contains the mole character image.

### `hammer.png`

Contains the hammer image used as the custom mouse cursor.

## Controls

| Control | Action |
| --- | --- |
| Mouse Movement | Move the hammer |
| Double-click | Hit the mole |
| `R` | Restart the game after time runs out |
| `ESC` | Quit the game |

## Quick Start

```bash
python3 -m pip install pygame
python3 -m py_compile whack_a_mole.py
python3 whack_a_mole.py
```

## Technologies Used

- Python
- Pygame
- Git
- GitHub

## Author

Rikita Shil

Software Engineering  
Macquarie University
