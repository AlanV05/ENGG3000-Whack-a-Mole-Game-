"""
ENGG3000 Whack-a-Mole
Complete combined version using:
- retro_game_background.png.jpg
- mole.png

Place this Python file and both images in the same folder.

Run:
    python3 -m pip install pygame
    python3 whack_a_mole_complete.py
"""

from pathlib import Path
import math
import random
import sys

import pygame


# =============================================================================
# SETTINGS YOU CAN CHANGE LATER
# =============================================================================

SCREEN_WIDTH = 900
SCREEN_HEIGHT = 650
FPS = 60

ROUND_LENGTH_SECONDS = 60
MOLE_VISIBLE_SECONDS = 0.8# make  mole move faster

HIT_DISPLAY_MILLISECONDS = 220

GRID_ROWS = 3
GRID_COLUMNS = 3

SIDE_MARGIN = 145
TOP_MARGIN = 175
BOTTOM_MARGIN = 70

HOLE_WIDTH = 115
HOLE_HEIGHT = 55

MOLE_WIDTH = 110
MOLE_HEIGHT = 125
MOLE_VERTICAL_OFFSET = 23

BACKGROUND_IMAGE_NAME = "background.png.jpg"
MOLE_IMAGE_NAME = "mole.png"
HAMMER_IMAGE_NAME = "hammer.png"

BACKGROUND_DARKNESS = 60

DOUBLE_CLICK_TIME_MS = 400
DOUBLE_CLICK_DISTANCE = 35

REMOVE_BLACK_FROM_MOLE = True
BLACK_TOLERANCE = 35

# Colours
WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
YELLOW = (255, 225, 30)
PINK = (255, 70, 170)
PURPLE = (125, 60, 150)
DARK_PURPLE = (20, 8, 28)
LIGHT_PURPLE = (225, 200, 255)
RED = (255, 80, 80)

PANEL_COLOUR = (20, 10, 35, 220)
PANEL_BORDER_COLOUR = PINK

SOIL_COLOURS = [
    (120, 72, 35),
    (150, 90, 45),
    (180, 115, 60),
    (95, 55, 25),
]
# =============================================================================
# FILE PATHS
# =============================================================================

PROJECT_FOLDER = Path(__file__).resolve().parent
BACKGROUND_PATH = PROJECT_FOLDER / BACKGROUND_IMAGE_NAME
MOLE_PATH = PROJECT_FOLDER / MOLE_IMAGE_NAME
HAMMER_PATH = PROJECT_FOLDER / HAMMER_IMAGE_NAME


# =============================================================================
# LAYOUT
# =============================================================================

def create_hole_positions():
    """Create evenly spaced hole positions automatically."""
    usable_width = SCREEN_WIDTH - (2 * SIDE_MARGIN)
    usable_height = SCREEN_HEIGHT - TOP_MARGIN - BOTTOM_MARGIN

    if GRID_COLUMNS == 1:
        x_positions = [SCREEN_WIDTH // 2]
    else:
        x_gap = usable_width / (GRID_COLUMNS - 1)
        x_positions = [
            round(SIDE_MARGIN + column * x_gap)
            for column in range(GRID_COLUMNS)
        ]

    if GRID_ROWS == 1:
        y_positions = [
            round(TOP_MARGIN + usable_height / 2)
        ]
    else:
        y_gap = usable_height / (GRID_ROWS - 1)
        y_positions = [
            round(TOP_MARGIN + row * y_gap)
            for row in range(GRID_ROWS)
        ]

    return [
        (x, y)
        for y in y_positions
        for x in x_positions
    ]


HOLE_POSITIONS = create_hole_positions()


# =============================================================================
# IMAGE FUNCTIONS
# =============================================================================

def load_image(path, use_alpha=True):
    """Load an image and give a clear error when it is missing."""
    if not path.exists():
        raise FileNotFoundError(
            f"\nCould not find this file:\n{path}\n\n"
            f"Put '{path.name}' in the same folder as this Python file."
        )

    image = pygame.image.load(str(path))

    if use_alpha:
        return image.convert_alpha()

    return image.convert()


def remove_near_black_pixels(image, tolerance):
    """
    Make near-black pixels transparent.

    This is useful when the mole image has a black background.
    """
    result = image.copy().convert_alpha()
    width, height = result.get_size()

    for x in range(width):
        for y in range(height):
            red, green, blue, alpha = result.get_at((x, y))

            if (
                red <= tolerance
                and green <= tolerance
                and blue <= tolerance
            ):
                result.set_at((x, y), (red, green, blue, 0))

    return result


def scale_to_cover(image, target_width, target_height):
    """Scale an image to cover the entire window without stretching."""
    image_width, image_height = image.get_size()

    scale = max(
        target_width / image_width,
        target_height / image_height,
    )

    new_width = round(image_width * scale)
    new_height = round(image_height * scale)

    return pygame.transform.smoothscale(
        image,
        (new_width, new_height),
    )


def prepare_background(image):
    return scale_to_cover(
        image,
        SCREEN_WIDTH,
        SCREEN_HEIGHT,
    )


def prepare_mole(image):
    if REMOVE_BLACK_FROM_MOLE:
        image = remove_near_black_pixels(
            image,
            BLACK_TOLERANCE,
        )

    return pygame.transform.smoothscale(
        image,
        (MOLE_WIDTH, MOLE_HEIGHT),
    )


# =============================================================================
# DRAWING FUNCTIONS
# =============================================================================

def draw_background(surface, background):
    """Draw the arcade background centred on the screen."""
    background_width, background_height = background.get_size()

    x = (SCREEN_WIDTH - background_width) // 2
    y = (SCREEN_HEIGHT - background_height) // 2

    surface.blit(background, (x, y))

    if BACKGROUND_DARKNESS > 0:
        overlay = pygame.Surface(
            (SCREEN_WIDTH, SCREEN_HEIGHT),
            pygame.SRCALPHA,
        )
        overlay.fill((0, 0, 0, BACKGROUND_DARKNESS))
        surface.blit(overlay, (0, 0))


def draw_holes(surface):
    """Draw all mole holes."""
    for x, y in HOLE_POSITIONS:
        # pygame.draw.ellipse(
        #     surface,
        #     PINK,
        #     (
        #         x - HOLE_WIDTH // 2 - 5,
        #         y - HOLE_HEIGHT // 2 - 5,
        #         HOLE_WIDTH + 10,
        #         HOLE_HEIGHT + 10,
        #     ),
        # )

        # pygame.draw.ellipse(
        #     surface,
        #     PURPLE,
        #     (
        #         x - HOLE_WIDTH // 2 - 2,
        #         y - HOLE_HEIGHT // 2 - 2,
        #         HOLE_WIDTH + 4,
        #         HOLE_HEIGHT + 4,
        #     ),
        # )

        pygame.draw.ellipse(
            surface,
            DARK_PURPLE,
            (
                x - HOLE_WIDTH // 2,
                y - HOLE_HEIGHT // 2,
                HOLE_WIDTH,
                HOLE_HEIGHT,
            ),
        )


def draw_panel(surface, rectangle):
    panel = pygame.Surface(
        (rectangle.width, rectangle.height),
        pygame.SRCALPHA,
    )

    pygame.draw.rect(
        panel,
        PANEL_COLOUR,
        panel.get_rect(),
        border_radius=14,
    )

    pygame.draw.rect(
        panel,
        PANEL_BORDER_COLOUR,
        panel.get_rect(),
        width=2,
        border_radius=14,
    )

    surface.blit(panel, rectangle.topleft)


def draw_hud(surface, font, small_font, score, time_remaining):
    score_panel = pygame.Rect(20, 18, 190, 65)
    title_panel = pygame.Rect(
        SCREEN_WIDTH // 2 - 230,
        18,
        460,
        65,
    )
    timer_panel = pygame.Rect(
        SCREEN_WIDTH - 210,
        18,
        190,
        65,
    )

    for panel in (score_panel, title_panel, timer_panel):
        draw_panel(surface, panel)

    score_text = font.render(
        f"Score: {score}",
        True,
        WHITE,
    )

    title_text = font.render(
        " WHACK-A-MOLE GAME",
        True,
        WHITE,
    )

    instruction_text = small_font.render(
        "Double-click the mole",
        True,
        WHITE,
    )

    timer_text = font.render(
        f"Time: {max(0, math.ceil(time_remaining))}",
        True,
        WHITE,
    )

    surface.blit(
        score_text,
        score_text.get_rect(center=score_panel.center),
    )

    surface.blit(
        title_text,
        title_text.get_rect(
            center=(title_panel.centerx, title_panel.centery - 10)
        ),
    )

    surface.blit(
        instruction_text,
        instruction_text.get_rect(
            center=(title_panel.centerx, title_panel.centery + 18)
        ),
    )

    surface.blit(
        timer_text,
        timer_text.get_rect(center=timer_panel.center),
    )


def draw_hammer(surface, hammer_image, position, hitting):
    """Draw the hammer at the mouse position."""

    if hitting:
        # Rotate hammer when clicking
        hammer = pygame.transform.rotate(
            hammer_image,
            -35
        )
    else:
        hammer = hammer_image

    hammer_rect = hammer.get_rect(
        center=position
    )

    surface.blit(
        hammer,
        hammer_rect
    )


def draw_game_over(surface, large_font, medium_font, small_font, score):
    overlay = pygame.Surface(
        (SCREEN_WIDTH, SCREEN_HEIGHT),
        pygame.SRCALPHA,
    )
    overlay.fill((5, 0, 12, 190))
    surface.blit(overlay, (0, 0))

    panel = pygame.Rect(
        SCREEN_WIDTH // 2 - 260,
        SCREEN_HEIGHT // 2 - 130,
        520,
        260,
    )

    draw_panel(surface, panel)

    title = large_font.render(
        "TIME'S UP!",
        True,
        PINK,
    )

    score_text = medium_font.render(
        f"Final Score: {score}",
        True,
        WHITE,
    )

    restart_text = small_font.render(
        "Press R to play again",
        True,
        WHITE,
    )

    quit_text = small_font.render(
        "Press ESC to quit",
        True,
        WHITE,
    )

    surface.blit(
        title,
        title.get_rect(
            center=(panel.centerx, panel.top + 65)
        ),
    )

    surface.blit(
        score_text,
        score_text.get_rect(
            center=(panel.centerx, panel.top + 130)
        ),
    )

    surface.blit(
        restart_text,
        restart_text.get_rect(
            center=(panel.centerx, panel.top + 185)
        ),
    )

    surface.blit(
        quit_text,
        quit_text.get_rect(
            center=(panel.centerx, panel.top + 218)
        ),
    )


# =============================================================================
# MOLE CLASS
# =============================================================================

class SoilParticle:
    """A small piece of soil thrown from the hole."""

    def __init__(self, x, y):
        self.x = x + random.randint(-35, 35)
        self.y = y + random.randint(-8, 8)

        self.velocity_x = random.uniform(-5.0, 5.0)
        self.velocity_y = random.uniform(-10.0, -4.0)

        self.gravity = 0.35
        self.radius = random.randint(3, 7)
        self.colour = random.choice(SOIL_COLOURS)
        self.life = random.randint(25, 45)

    def update(self):
        self.x += self.velocity_x
        self.y += self.velocity_y
        self.velocity_y += self.gravity
        self.life -= 1

    def draw(self, surface):
        pygame.draw.circle(
            surface,
            self.colour,
            (int(self.x), int(self.y)),
            self.radius,
        )

    def is_dead(self):
        return self.life <= 0


class Mole:
    def __init__(self, image):
        self.image = image
        self.position = random.choice(HOLE_POSITIONS)
        self.spawn_time = pygame.time.get_ticks()

        self.hit = False
        self.hit_time = 0

        # Create the soil particles when the mole appears.
        self.soil_particles = []

        x, y = self.position

        for _ in range(25):
            self.soil_particles.append(
                SoilParticle(x, y)
            )

    def contains(self, point):
        """Return True when a click lands on the visible mole."""
        x, hole_y = self.position

        hit_box = pygame.Rect(
            x - MOLE_WIDTH // 2,
            hole_y - MOLE_HEIGHT + MOLE_VERTICAL_OFFSET,
            MOLE_WIDTH,
            MOLE_HEIGHT,
        )

        return hit_box.collidepoint(point)

    def register_hit(self):
        self.hit = True
        self.hit_time = pygame.time.get_ticks()

    def has_expired(self):
        age_seconds = (
            pygame.time.get_ticks() - self.spawn_time
        ) / 1000

        return age_seconds >= MOLE_VISIBLE_SECONDS

    def should_be_removed(self):
        if self.hit:
            return (
                pygame.time.get_ticks() - self.hit_time
            ) >= HIT_DISPLAY_MILLISECONDS

        return self.has_expired()

    def draw(self, surface):
        x, hole_y = self.position

        # Update and draw the flying soil.
        for particle in self.soil_particles:
            particle.update()
            particle.draw(surface)

        # Remove soil particles whose animation has finished.
        self.soil_particles = [
            particle
            for particle in self.soil_particles
            if not particle.is_dead()
        ]

        # Animate the mole rising from the hole.
        age_ms = pygame.time.get_ticks() - self.spawn_time
        rise_progress = min(1, age_ms / 180)
        rise_amount = round(22 * rise_progress)

        mole_rect = self.image.get_rect(
            midbottom=(
                x,
                hole_y + MOLE_VERTICAL_OFFSET - rise_amount,
            )
        )

        surface.blit(self.image, mole_rect)

        if self.hit:
            self.draw_hit_effect(surface, mole_rect.center)

    @staticmethod
    def draw_hit_effect(surface, centre):
        for angle in range(0, 360, 45):
            radians = math.radians(angle)

            end_x = centre[0] + round(
                75 * math.cos(radians)
            )
            end_y = centre[1] + round(
                75 * math.sin(radians)
            )

            pygame.draw.line(
                surface,
                YELLOW,
                centre,
                (end_x, end_y),
                width=4,
            )

# =============================================================================
# GAME STATE
# =============================================================================

def create_new_game(mole_image):
    return {
        "score": 0,
        "start_time": pygame.time.get_ticks(),
        "mole": Mole(mole_image),
        "game_over": False,
        "last_click_time": None,
        "last_click_position": None,
        "cursor_flash_until": 0,
    }


def is_double_click(state, click_position, click_time):
    last_click_time = state["last_click_time"]
    last_click_position = state["last_click_position"]

    if (
        last_click_time is None
        or last_click_position is None
    ):
        return False

    time_gap = click_time - last_click_time

    distance = math.hypot(
        click_position[0] - last_click_position[0],
        click_position[1] - last_click_position[1],
    )

    return (
        time_gap <= DOUBLE_CLICK_TIME_MS
        and distance <= DOUBLE_CLICK_DISTANCE
    )


# =============================================================================
# MAIN GAME LOOP
# =============================================================================

def run_game():
    pygame.init()

    screen = pygame.display.set_mode(
        (SCREEN_WIDTH, SCREEN_HEIGHT)
    )

    pygame.display.set_caption(
        "ENGG3000 Whack-a-Mole"
    )
    pygame.mouse.set_visible(False)

    clock = pygame.time.Clock()

    small_font = pygame.font.SysFont(
        "arial",
        18,
    )

    medium_font = pygame.font.SysFont(
        "arial",
        27,
        bold=True,
    )

    large_font = pygame.font.SysFont(
        "arial",
        52,
        bold=True,
    )

    try:
        background_original = load_image(
            BACKGROUND_PATH,
            use_alpha=False,
        )

        mole_original = load_image(
            MOLE_PATH,
            use_alpha=True,
        )

        hammer_image = load_image(
            HAMMER_PATH,
            use_alpha=True,
        )

        hammer_image = pygame.transform.smoothscale(
            hammer_image,
            (90, 90),
        )

    except (FileNotFoundError, pygame.error) as error:
        pygame.quit()
        raise SystemExit(error) from error

    background = prepare_background(
        background_original
    )

    mole_image = prepare_mole(
        mole_original
    )

    state = create_new_game(mole_image)

    running = True

    while running:
        for event in pygame.event.get():

            if event.type == pygame.QUIT:
                running = False

            elif event.type == pygame.KEYDOWN:

                if event.key == pygame.K_ESCAPE:
                    running = False

                elif (
                    event.key == pygame.K_r
                    and state["game_over"]
                ):
                    state = create_new_game(mole_image)

            elif (
                event.type == pygame.MOUSEBUTTONDOWN
                and event.button == 1
                and not state["game_over"]
            ):
                click_time = pygame.time.get_ticks()
                click_position = event.pos

                if is_double_click(
                    state,
                    click_position,
                    click_time,
                ):
                    state["cursor_flash_until"] = (
                        click_time + 160
                    )

                    mole = state["mole"]

                    if (
                        not mole.hit
                        and mole.contains(click_position)
                    ):
                        mole.register_hit()
                        state["score"] += 1

                    state["last_click_time"] = None
                    state["last_click_position"] = None

                else:
                    state["last_click_time"] = click_time
                    state["last_click_position"] = click_position

        draw_background(screen, background)
        draw_holes(screen)

        if not state["game_over"]:

            elapsed_seconds = (
                pygame.time.get_ticks()
                - state["start_time"]
            ) / 1000

            time_remaining = (
                ROUND_LENGTH_SECONDS - elapsed_seconds
            )

            if time_remaining <= 0:
                state["game_over"] = True

            else:
                if state["mole"].should_be_removed():
                    state["mole"] = Mole(mole_image)

                state["mole"].draw(screen)

            cursor_position = pygame.mouse.get_pos()

            cursor_is_flashing = (
                    pygame.time.get_ticks()
                    < state["cursor_flash_until"]
                )

            draw_hammer(
                    screen,
                    hammer_image,
                    cursor_position,
                    cursor_is_flashing,
                )

            draw_hud(
                    screen,
                    medium_font,
                    small_font,
                    state["score"],
                    time_remaining,
                )

        if state["game_over"]:
            draw_game_over(
                screen,
                large_font,
                medium_font,
                small_font,
                state["score"],
            )

        pygame.display.flip()
        clock.tick(FPS)

    pygame.quit()
    sys.exit()


if __name__ == "__main__":
    run_game()