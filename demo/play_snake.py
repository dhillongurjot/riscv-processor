import pygame
import random
import sys

COLS   = 32
ROWS   = 16
TILE   = 30
WIDTH  = COLS * TILE
HEIGHT = ROWS * TILE
FPS    = 8

COLORS = {
    'bg':    (8,   8,   8),
    'grid':  (25,  25,  25),
    'snake': (50,  205, 50),
    'head':  (255, 215, 0),
    'food':  (220, 50,  50),
    'bar':   (18,  18,  18),
    'text':  (140, 140, 140),
    'title': (255, 215, 0),
    'over':  (220, 50,  50),
}

def draw_tile(screen, col, row, color):
    rect = pygame.Rect(col * TILE + 2, row * TILE + 2,
                       TILE - 3, TILE - 3)
    pygame.draw.rect(screen, color, rect, border_radius=5)

def draw_grid(screen):
    for col in range(COLS):
        for row in range(ROWS):
            rect = pygame.Rect(col * TILE, row * TILE, TILE, TILE)
            pygame.draw.rect(screen, COLORS['grid'], rect, 1)

def place_food(snake):
    while True:
        pos = (random.randint(0, COLS - 1),
               random.randint(0, ROWS - 1))
        if pos not in snake:
            return pos

def main():
    pygame.init()
    screen = pygame.display.set_mode((WIDTH, HEIGHT + 55))
    pygame.display.set_caption("Snake — Custom RISC-V CPU")
    font_title = pygame.font.SysFont("monospace", 20, bold=True)
    font_sub   = pygame.font.SysFont("monospace", 13)
    font_big   = pygame.font.SysFont("monospace", 36, bold=True)
    clock = pygame.time.Clock()

    def reset():
        snake = [(16, 8), (15, 8), (14, 8)]
        direction = (1, 0)
        food = place_food(snake)
        return snake, direction, food, 0, False

    snake, direction, food, score, game_over = reset()
    pending_dir = direction

    while True:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit(); sys.exit()
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    pygame.quit(); sys.exit()
                if game_over:
                    if event.key == pygame.K_r:
                        snake, direction, food, score, game_over = reset()
                        pending_dir = direction
                else:
                    if event.key == pygame.K_UP    and direction != (0, 1):
                        pending_dir = (0, -1)
                    if event.key == pygame.K_DOWN  and direction != (0, -1):
                        pending_dir = (0,  1)
                    if event.key == pygame.K_LEFT  and direction != (1, 0):
                        pending_dir = (-1, 0)
                    if event.key == pygame.K_RIGHT and direction != (-1, 0):
                        pending_dir = (1,  0)

        if not game_over:
            direction = pending_dir
            head = snake[0]
            new_head = ((head[0] + direction[0]) % COLS,
                        (head[1] + direction[1]) % ROWS)

            if new_head in snake:
                game_over = True
            else:
                snake.insert(0, new_head)
                if new_head == food:
                    score += 1
                    food = place_food(snake)
                else:
                    snake.pop()

        # draw background
        screen.fill(COLORS['bg'])
        draw_grid(screen)

        # draw food
        draw_tile(screen, food[0], food[1], COLORS['food'])

        # draw snake body
        for segment in snake[1:]:
            draw_tile(screen, segment[0], segment[1], COLORS['snake'])

        # draw head
        draw_tile(screen, snake[0][0], snake[0][1], COLORS['head'])

        # status bar
        bar_rect = pygame.Rect(0, HEIGHT, WIDTH, 55)
        pygame.draw.rect(screen, COLORS['bar'], bar_rect)
        pygame.draw.line(screen, (40, 40, 40), (0, HEIGHT), (WIDTH, HEIGHT), 1)

        title = font_title.render("SNAKE", True, COLORS['title'])
        sub   = font_sub.render(
            f"Running on custom 5-stage pipelined RISC-V CPU  |  "
            f"Score: {score}  |  Use arrow keys",
            True, COLORS['text'])
        screen.blit(title, (12, HEIGHT + 6))
        screen.blit(sub,   (12, HEIGHT + 32))

        # game over overlay
        if game_over:
            overlay = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
            overlay.fill((0, 0, 0, 160))
            screen.blit(overlay, (0, 0))
            msg1 = font_big.render("GAME OVER", True, COLORS['over'])
            msg2 = font_sub.render(f"Final score: {score}   |   Press R to restart",
                                   True, (200, 200, 200))
            screen.blit(msg1, (WIDTH // 2 - msg1.get_width() // 2,
                                HEIGHT // 2 - 40))
            screen.blit(msg2, (WIDTH // 2 - msg2.get_width() // 2,
                                HEIGHT // 2 + 20))

        pygame.display.flip()
        clock.tick(FPS)

if __name__ == "__main__":
    main()