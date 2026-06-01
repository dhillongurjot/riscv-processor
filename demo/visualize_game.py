import subprocess
import pygame
import sys

COLS  = 32
ROWS  = 16
TILE  = 30
WIDTH = COLS * TILE
HEIGHT = ROWS * TILE
FPS   = 10

COLORS = {
    0: (15,  15,  15),
    1: (50,  205, 50),
    2: (220, 50,  50),
    3: (255, 215, 0),
}

BORDER = (40, 40, 40)

def run_simulation():
    print("Running simulation...")
    result = subprocess.run(["vvp", "snake_sim"],
                            capture_output=True, text=True)
    return result.stdout

def parse_frames(output):
    frames, current = [], []
    for line in output.splitlines():
        line = line.strip()
        if line.startswith("FRAME"):
            if current:
                frames.append(current[:])
            current = []
        elif line == "DONE":
            if current:
                frames.append(current[:])
        elif line.isdigit():
            current.append(int(line))
    return frames

def draw_frame(screen, tiles, frame_num, font_big, font_small):
    screen.fill((8, 8, 8))

    # draw grid border
    pygame.draw.rect(screen, BORDER,
                     (0, 0, WIDTH, HEIGHT), 2)

    for i, val in enumerate(tiles[:512]):
        col = i % COLS
        row = i // COLS
        color = COLORS.get(val & 3, COLORS[0])
        rect = pygame.Rect(col * TILE + 2, row * TILE + 2,
                           TILE - 3, TILE - 3)
        pygame.draw.rect(screen, color, rect, border_radius=5)

    # status bar
    bar = pygame.Rect(0, HEIGHT, WIDTH, 50)
    pygame.draw.rect(screen, (20, 20, 20), bar)

    title = font_big.render("SNAKE", True, (255, 215, 0))
    sub   = font_small.render(
        "Running on custom 5-stage pipelined RISC-V CPU  |  "
        f"Frame {frame_num}", True, (140, 140, 140))

    screen.blit(title, (12, HEIGHT + 8))
    screen.blit(sub,   (12, HEIGHT + 30))
    pygame.display.flip()

def main():
    output = run_simulation()
    frames = parse_frames(output)

    if not frames:
        print("No frames found. Make sure snake_sim is compiled.")
        sys.exit(1)

    print(f"Got {len(frames)} frames. Starting visualizer...")

    pygame.init()
    screen = pygame.display.set_mode((WIDTH, HEIGHT + 50))
    pygame.display.set_caption(
        "Snake — Custom RISC-V CPU")
    font_big   = pygame.font.SysFont("monospace", 20, bold=True)
    font_small = pygame.font.SysFont("monospace", 13)
    clock = pygame.time.Clock()

    frame_idx = 0
    paused    = False

    while True:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit(); sys.exit()
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    pygame.quit(); sys.exit()
                if event.key == pygame.K_SPACE:
                    paused = not paused
                if event.key == pygame.K_RIGHT:
                    frame_idx = (frame_idx + 1) % len(frames)
                if event.key == pygame.K_LEFT:
                    frame_idx = (frame_idx - 1) % len(frames)

        if not paused:
            draw_frame(screen, frames[frame_idx],
                       frame_idx, font_big, font_small)
            frame_idx = (frame_idx + 1) % len(frames)

        clock.tick(FPS)

if __name__ == "__main__":
    main()