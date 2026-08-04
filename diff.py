import pygame
from pathlib import Path

# --------------------------------------------------
# GAME SETTINGS
# --------------------------------------------------
WINDOW_WIDTH = 1200
WINDOW_HEIGHT = 700
FPS = 60
WINDOW_TITLE = "Retro Arcade"

BACKGROUND_IMAGE = "retro_game_background.png"

# Dark overlay so game objects stand out
USE_DARK_OVERLAY = True
OVERLAY_ALPHA = 60


# --------------------------------------------------
# SCALE IMAGE TO FIT THE SCREEN
# --------------------------------------------------
def scale_background(image, window_size):
    window_width, window_height = window_size

    image_width, image_height = image.get_size()

    scale = max(
        window_width / image_width,
        window_height / image_height
    )

    new_width = int(image_width * scale)
    new_height = int(image_height * scale)

    return pygame.transform.smoothscale(
        image,
        (new_width, new_height)
    )


# --------------------------------------------------
# DRAW BACKGROUND
# --------------------------------------------------
def draw_background(screen, image):

    window_width, window_height = screen.get_size()

    scaled = scale_background(
        image,
        (window_width, window_height)
    )

    scaled_width, scaled_height = scaled.get_size()

    x = (window_width - scaled_width) // 2
    y = (window_height - scaled_height) // 2

    screen.blit(scaled, (x, y))

    if USE_DARK_OVERLAY:
        overlay = pygame.Surface(
            (window_width, window_height),
            pygame.SRCALPHA
        )

        overlay.fill((0, 0, 0, OVERLAY_ALPHA))
        screen.blit(overlay, (0, 0))


# --------------------------------------------------
# MAIN
# --------------------------------------------------
def main():

    pygame.init()

    screen = pygame.display.set_mode(
        (WINDOW_WIDTH, WINDOW_HEIGHT),
        pygame.RESIZABLE
    )

    pygame.display.set_caption(WINDOW_TITLE)

    clock = pygame.time.Clock()

    image_path = Path(__file__).parent / BACKGROUND_IMAGE

    background = pygame.image.load(
        image_path
    ).convert()

    font = pygame.font.SysFont(
        "Arial",
        60,
        bold=True
    )

    running = True

    while running:

        for event in pygame.event.get():

            if event.type == pygame.QUIT:
                running = False

            if event.type == pygame.KEYDOWN:

                if event.key == pygame.K_ESCAPE:
                    running = False

        draw_background(screen, background)

        # ==========================================
        # YOUR GAME GOES HERE
        # ==========================================

        title = font.render(
            "RETRO ARCADE",
            True,
            (255, 255, 255)
        )

        shadow = font.render(
            "RETRO ARCADE",
            True,
            (30, 30, 30)
        )

        title_rect = title.get_rect(
            center=(screen.get_width() // 2, 60)
        )

        screen.blit(
            shadow,
            (title_rect.x + 4, title_rect.y + 4)
        )

        screen.blit(title, title_rect)

        # Example object
        pygame.draw.circle(
            screen,
            (255, 230, 0),
            (screen.get_width() // 2,
             screen.get_height() // 2),
            40
        )

        pygame.display.flip()

        clock.tick(FPS)

    pygame.quit()


if __name__ == "__main__":
    main()