import pygame
import sys

# -----------------------------
# INITIALIZE PYGAME
# -----------------------------
pygame.init()

# -----------------------------
# GAME SETTINGS
# -----------------------------
WIDTH = 600
HEIGHT = 600

BACKGROUND_COLOR = (35, 40, 55)
CIRCLE_COLOR = (255, 200, 0)

ROWS = 3         # Number of rows
COLS = 3          # Number of columns
CIRCLE_RADIUS = 45

FPS = 60

# -----------------------------
# CREATE WINDOW
# -----------------------------
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Game Background")

clock = pygame.time.Clock()

# -----------------------------
# CREATE CIRCLES AUTOMATICALLY
# -----------------------------
circles = []

# Calculate equal spacing
x_spacing = WIDTH // (COLS + 1)
y_spacing = HEIGHT // (ROWS + 1)

for row in range(ROWS):
    for col in range(COLS):

        x = (col + 1) * x_spacing
        y = (row + 1) * y_spacing

        circles.append((x, y))

# -----------------------------
# MAIN GAME LOOP
# -----------------------------
running = True

while running:

    # Handle Events
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

    # Draw Background
    screen.fill(BACKGROUND_COLOR)

    # Draw All Circles
    for circle in circles:
        pygame.draw.circle(
            screen,
            CIRCLE_COLOR,
            circle,
            CIRCLE_RADIUS
        )

    pygame.display.flip()
    clock.tick(FPS)

pygame.quit()
sys.exit()


