const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");

var bird = rl.Rectangle.init(50, 200, 32, 32);
var bird_vel = rl.Vector2.init(0, 0);
const gravity: f32 = -2000.0;

const screen_width = 360;
const screen_height = 720;

const Pipe = struct {
    top_pipe: rl.Rectangle,
    bottom_pipe: rl.Rectangle,
};

var pipes = [3]Pipe{
    Pipe{
        .top_pipe = rl.Rectangle.init(0, 0, 0, 0),
        .bottom_pipe = rl.Rectangle.init(0, 0, 0, 0),
    },
    Pipe{
        .top_pipe = rl.Rectangle.init(0, 0, 0, 0),
        .bottom_pipe = rl.Rectangle.init(0, 0, 0, 0),
    },
    Pipe{
        .top_pipe = rl.Rectangle.init(0, 0, 0, 0),
        .bottom_pipe = rl.Rectangle.init(0, 0, 0, 0),
    },
};
const pipe_width = 64;
const pipe_interval = 300;
const pipe_gap = 200;
const pipe_speed = 100;

var prng = std.rand.DefaultPrng.init(0);

var score: i32 = 0;

var game_running = false;
var game_waiting = false;
var game_over = false;
var auto_play = false;

const time_scale = 1;

fn isJumpInput() bool {
    return rl.isMouseButtonPressed(rl.MouseButton.mouse_button_left) or rl.isKeyPressed(rl.KeyboardKey.key_space);
}

fn autoplayInput() bool {
    return rl.isKeyPressed(rl.KeyboardKey.key_a);
}

fn update() void {
    if (autoplayInput()) {
        auto_play = !auto_play;
    }
    if (!game_running) return;
    // wait for first input
    if (game_waiting) {
        if (isJumpInput()) {
            game_waiting = false;
        } else {
            return;
        }
    }
    const frame_time = rl.getFrameTime() * time_scale;
    if (pipes[0].top_pipe.x < -(pipe_width + 20)) {
        pipes[0] = pipes[1];
        pipes[1] = pipes[2];
        pipes[2] = generatePipe(pipes[1].top_pipe.x + pipe_interval);
        score += 1;
    }
    if (!auto_play and (rl.checkCollisionRecs(bird, pipes[0].top_pipe) or rl.checkCollisionRecs(bird, pipes[0].bottom_pipe) or bird.y > screen_height)) {
        game_over = true;
        game_running = false;
    }
    for (&pipes) |*pipe| {
        pipe.*.top_pipe.x -= pipe_speed * frame_time;
        pipe.*.bottom_pipe.x = pipe.*.top_pipe.x;
    }
    if (isJumpInput()) {
        bird_vel.y -= 800;
    }
    bird_vel.y -= gravity * frame_time;
    bird_vel = bird_vel.clampValue(-500, 1000);
    bird.y += bird_vel.y * frame_time;
    bird.y = @max(bird.y, 0);
    if (auto_play) {
        bird.y = pipes[0].top_pipe.height + (pipe_gap / 2);
    }
}

fn drawBird() void {
    const bird_rot = rl.math.lerp(-90, 90, rl.math.normalize(bird_vel.y, -1000, 1000));
    const bird_draw_rec = rl.Rectangle.init(bird.x + 16, bird.y + 16, bird.width, bird.height);
    rl.drawRectanglePro(bird_draw_rec, rl.Vector2.init(16, 16), bird_rot, rl.fade(rl.Color.yellow, 1.0));
    rl.drawRectanglePro(rl.Rectangle.init(bird_draw_rec.x, bird_draw_rec.y, 20, 10), rl.Vector2.init(-5, 3), bird_rot, rl.Color.black);
    rl.drawRectanglePro(rl.Rectangle.init(bird_draw_rec.x, bird_draw_rec.y, 4, 4), rl.Vector2.init(-5, 9), bird_rot, rl.Color.black);
}

fn drawPipe(pipe: Pipe) void {
    rl.drawRectangleRec(pipe.top_pipe, rl.Color.green);
    rl.drawRectangleRec(rl.Rectangle.init(pipe.top_pipe.x - 10, pipe.top_pipe.y + (pipe.top_pipe.height - 20), pipe.top_pipe.width + 20, 20), rl.Color.green);
    rl.drawRectangleRec(pipe.bottom_pipe, rl.Color.green);
    rl.drawRectangleRec(rl.Rectangle.init(pipe.bottom_pipe.x - 10, pipe.bottom_pipe.y, pipe.bottom_pipe.width + 20, 20), rl.Color.green);
}

fn drawGame() void {
    rl.beginDrawing();
    rl.clearBackground(rl.Color.sky_blue);

    drawBird();

    for (pipes) |pipe| {
        if (pipe.top_pipe.x < screen_width) {
            drawPipe(pipe);
        }
    }

    if (!game_running) {
        drawStartScreen();
    } else {
        if (game_waiting) {
            const waiting_text = "Jump to start (space/left click)";
            rl.drawText(
                waiting_text,
                screen_width / 2 - (@divExact(rl.measureText(waiting_text, 20), 2)),
                screen_height / 2,
                20,
                rl.Color.black,
            );
        }
        const curr_screen_w_i = rl.getScreenWidth();
        const curr_screen_h_i = rl.getScreenHeight();
        const score_text = rl.textFormat("Score: %i", .{score});
        rl.drawText(
            score_text,
            curr_screen_w_i - (rl.measureText(score_text, 20) + 20),
            30,
            20,
            rl.Color.black,
        );
        const fps_text = rl.textFormat("CURRENT FPS: %i", .{rl.getFPS()});
        rl.drawText(
            fps_text,
            curr_screen_w_i - (rl.measureText(fps_text, 20) + 20),
            curr_screen_h_i - 30,
            20,
            rl.Color.black,
        );
    }
    rl.endDrawing();
}

fn drawStartScreen() void {
    rl.drawRectangle(0, 0, screen_width, screen_height, rl.fade(rl.Color.light_gray, 0.5));
    if (game_over) {
        const game_over_text = "Game over";
        const score_text = rl.textFormat("Final score: %i", .{score});
        rl.drawText(game_over_text, (screen_width / 2) - @divExact(rl.measureText(game_over_text, 40), 2), (screen_height / 2) - 120, 40, rl.Color.black);
        rl.drawText(score_text, (screen_width / 2) - @divExact(rl.measureText(score_text, 20), 2), (screen_height / 2) - 60, 20, rl.Color.black);
    } else {
        const game_text = "Flappy";
        rl.drawText(game_text, (screen_width / 2) - @divExact(rl.measureText(game_text, 40), 2), (screen_height / 2) - 120, 40, rl.Color.black);
    }
    if (rg.guiButton(rl.Rectangle.init((screen_width / 2) - 32, (screen_height / 2) + 40, 64, 64), "#119#") != 0 or rl.isKeyPressed(rl.KeyboardKey.key_space)) {
        pipes = generateStartingPipes();
        bird = rl.Rectangle.init(50, 200, 32, 32);
        bird_vel = rl.Vector2.init(0, 0);
        game_over = false;
        score = 0;
        game_waiting = true;
        game_running = true;
    }
}

fn generatePipe(x: f32) Pipe {
    const top_height = (prng.random().float(f32) * 400) + 100;
    return Pipe{ .top_pipe = rl.Rectangle.init(x, 0, pipe_width, top_height), .bottom_pipe = rl.Rectangle.init(x, top_height + pipe_gap, pipe_width, screen_height - (top_height + pipe_gap)) };
}

fn generateStartingPipes() [3]Pipe {
    return [3]Pipe{
        generatePipe(@floatFromInt(screen_width)),
        generatePipe(@floatFromInt(screen_width + pipe_interval)),
        generatePipe(@floatFromInt(screen_width + (2 * pipe_interval))),
    };
}

pub fn main() !void {
    rl.initWindow(screen_width, screen_height, "flappy");
    defer rl.closeWindow();
    rl.setTargetFPS(10000);

    while (!rl.windowShouldClose()) {
        update();
        drawGame();
    }
}
