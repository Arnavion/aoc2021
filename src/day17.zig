const std = @import("std");

const input = @import("input.zig");

pub fn run(stdout: anytype) anyerror!void {
    var input_ = try input.readFile("inputs/day17");
    defer input_.deinit();

    var part1_result: i64 = undefined;
    var part2_result: usize = undefined;
    try solve(&input_, &part1_result, &part2_result);
    try stdout.print("17a: {}\n", .{ part1_result });
    std.debug.assert(part1_result == 10011);
    try stdout.print("17b: {}\n", .{ part2_result });
    std.debug.assert(part2_result == 2994);
}

fn solve(input_: anytype, part1_result: *i64, part2_result: *usize) !void {
    var min: Vector = undefined;
    var max: Vector = undefined;
    try parseInput(input_, &min, &max);

    part1_result.* = 0;
    part2_result.* = 0;

    var initial_vel_x: i64 = max.x;
    while (initial_vel_x > 0) : (initial_vel_x -= 1) {
        var initial_vel_y: i64 = try std.math.absInt(min.y);
        while (initial_vel_y >= min.y) : (initial_vel_y -= 1) {
            var pos = Vector { .x = 0, .y = 0 };
            var vel = Vector { .x = initial_vel_x, .y = initial_vel_y };
            var y_highest: i64 = pos.y;

            while (true) {
                switch (step(&pos, &vel, min, max)) {
                    .traveling => y_highest = std.math.max(y_highest, pos.y),
                    .hit => {
                        part1_result.* = std.math.max(part1_result.*, y_highest);
                        part2_result.* += 1;
                        break;
                    },
                    .missed => break,
                }
            }
        }
    }
}

const Vector = struct {
    x: i64,
    y: i64,
};

fn parseInput(input_: anytype, min: *Vector, max: *Vector) !void {
    const line = (try input_.next()) orelse return error.InvalidInput;
    if (!std.mem.startsWith(u8, line, "target area: ")) {
        return error.InvalidInput;
    }
    var line_parts = std.mem.split(u8, line[("target area: ".len)..], ", ");

    const x_s = line_parts.next() orelse return error.InvalidInput;
    if (!std.mem.startsWith(u8, x_s, "x=")) {
        return error.InvalidInput;
    }
    var x_start: i64 = undefined;
    var x_end: i64 = undefined;
    try parseRange(x_s[("x=".len)..], &x_start, &x_end);
    min.x = std.math.min(x_start, x_end);
    max.x = std.math.max(x_start, x_end);

    const y_s = line_parts.next() orelse return error.InvalidInput;
    if (!std.mem.startsWith(u8, y_s, "y=")) {
        return error.InvalidInput;
    }
    var y_start: i64 = undefined;
    var y_end: i64 = undefined;
    try parseRange(y_s[("y=".len)..], &y_start, &y_end);
    min.y = std.math.min(y_start, y_end);
    max.y = std.math.max(y_start, y_end);
}

fn parseRange(s: []const u8, start: *i64, end: *i64) !void {
    var s_parts = std.mem.split(u8, s, "..");

    const start_s = s_parts.next() orelse return error.InvalidInput;
    start.* = try std.fmt.parseInt(i64, start_s, 10);

    const end_s = s_parts.next() orelse return error.InvalidInput;
    end.* = try std.fmt.parseInt(i64, end_s, 10);
}

const StepResult = enum {
    traveling,
    hit,
    missed,
};

fn step(pos: *Vector, vel: *Vector, min: Vector, max: Vector) StepResult {
    pos.x += vel.x;
    pos.y += vel.y;
    if (vel.x > 0) {
        vel.x -= 1;
    }
    else if (vel.x < 0) {
        vel.x += 1;
    }
    vel.y -= 1;

    if (pos.x >= min.x and pos.x <= max.x and pos.y >= min.y and pos.y <= max.y) {
        return .hit;
    }

    if (pos.x > max.x or pos.y < min.y) {
        return .missed;
    }

    return .traveling;
}

test "day 17 example 1" {
    const input_ =
        \\target area: x=20..30, y=-10..-5
        ;

    var part1_result: i64 = undefined;
    var part2_result: usize = undefined;
    try solve(&input.readString(input_), &part1_result, &part2_result);
    try std.testing.expectEqual(@as(i64, 45), part1_result);
    try std.testing.expectEqual(@as(usize, 112), part2_result);
}
