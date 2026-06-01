#define GRID_W   32
#define GRID_H   16
#define MAX_LEN  64

#define EMPTY  0
#define SNAKE  1
#define FOOD   2
#define HEAD   3

volatile int* fb = (volatile int*)0x00000000;

void fb_set(int x, int y, int color) {
    fb[y * GRID_W + x] = color;
}

void delay() {
    volatile int i;
    for (i = 0; i < 1000; i++);
}

int body_x[MAX_LEN];
int body_y[MAX_LEN];
int head_x, head_y;
int dir;
int length;
int food_x, food_y;
int rand_val = 42;

int simple_rand() {
    rand_val = rand_val * 1103515245 + 12345;
    return (rand_val >> 16) & 0x7FFF;
}

void place_food() {
    food_x = simple_rand() % GRID_W;
    food_y = simple_rand() % GRID_H;
    fb_set(food_x, food_y, FOOD);
}

void init() {
    int i;
    for (i = 0; i < GRID_W * GRID_H; i++)
        fb[i] = EMPTY;

    head_x = 16; head_y = 12;
    dir = 0; length = 3;

    body_x[0] = 16; body_y[0] = 12;
    body_x[1] = 15; body_y[1] = 12;
    body_x[2] = 14; body_y[2] = 12;

    fb_set(16, 12, HEAD);
    fb_set(15, 12, SNAKE);
    fb_set(14, 12, SNAKE);

    place_food();
}

int main() {
    int i, new_x, new_y;
    init();

    while (1) {
        delay();

        new_x = head_x;
        new_y = head_y;

        if      (dir == 0) new_x = new_x + 1;
        else if (dir == 1) new_y = new_y + 1;
        else if (dir == 2) new_x = new_x - 1;
        else               new_y = new_y - 1;

        // wrap around edges
        if (new_x < 0)       new_x = GRID_W - 1;
        if (new_x >= GRID_W) new_x = 0;
        if (new_y < 0)       new_y = GRID_H - 1;
        if (new_y >= GRID_H) new_y = 0;

        // erase tail
        fb_set(body_x[length-1], body_y[length-1], EMPTY);

        // shift body
        for (i = length - 1; i > 0; i--) {
            body_x[i] = body_x[i-1];
            body_y[i] = body_y[i-1];
        }

        // check food
        if (new_x == food_x && new_y == food_y) {
            if (length < MAX_LEN - 1) length++;
            place_food();
        }

        // update head
        head_x = new_x;
        head_y = new_y;
        body_x[0] = head_x;
        body_y[0] = head_y;

        // redraw
        fb_set(body_x[1], body_y[1], SNAKE);
        fb_set(head_x, head_y, HEAD);
    }

    return 0;
}