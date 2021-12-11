const std = @import("std");

const input = @import("input.zig");

pub fn run(stdout: anytype) anyerror!void {
    {
        var input_ = try input.readFile("inputs/day11");
        defer input_.deinit();

        const result = try part1(&input_);
        try stdout.print("11a: {}\n", .{ result });
        std.debug.assert(result == 1705);
    }

    {
        var input_ = try input.readFile("inputs/day11");
        defer input_.deinit();

        const result = try part2(&input_);
        try stdout.print("11b: {}\n", .{ result });
        std.debug.assert(result == 265);
    }
}

const num_rows = 10;
const num_cols = 10;

fn part1(input_: anytype) !usize {
    var levels = try parseInput(input_);

    var result: usize = 0;

    var step_num: usize = 1;
    while (step_num <= 100) : (step_num += 1) {
        result += step(&levels);
    }

    return result;
}

fn part2(input_: anytype) !usize {
    var levels = try parseInput(input_);

    var step_num: usize = 1;
    while (true) : (step_num += 1) {
        const num_flashed = step(&levels);
        if (num_flashed == num_rows * num_cols) {
            return step_num;
        }
    }
}

fn parseInput(input_: anytype) ![num_rows][num_cols]Level {
    var levels: [num_rows][num_cols]Level = [_][num_cols]Level { [_]Level { 0 } ** num_cols } ** num_rows;

    var row_i: usize = 0;
    while (try input_.next()) |line| {
        for (line) |c, col_i| {
            levels[row_i][col_i] = try std.fmt.parseInt(Level, &[_]u8 { c }, 10);
        }

        row_i += 1;
    }

    return levels;
}

const flash_at = 10;

// 0...(flash_at - 1) : will not flash
// flash_at           : should flash
// flash_at + 1       : has already flashed and will not flash again
const Level = std.math.IntFittingRange(0, flash_at + 1);

fn step(levels: *[num_rows][num_cols]Level) usize {
    for (levels) |*row| {
        for (row) |*level| {
            increaseLevel(level);
        }
    }

    while (true) {
        var had_a_flash = false;

        for (levels) |*row, row_i| {
            for (row) |*level, col_i| {
                if (level.* == flash_at) {
                    level.* = flash_at + 1;
                    had_a_flash = true;

                    const up = std.math.sub(usize, row_i, 1) catch null;
                    const down = if (std.math.add(usize, row_i, 1) catch null) |down_| if (down_ < num_rows) down_ else null else null;
                    const left = std.math.sub(usize, col_i, 1) catch null;
                    const right = if (std.math.add(usize, col_i, 1) catch null) |right_| if (right_ < num_cols) right_ else null else null;

                    for ([_]?usize { up, row_i, down }) |row_j| {
                        for ([_]?usize { left, col_i, right }) |col_j| {
                            const row_j_ = row_j orelse continue;
                            const col_j_ = col_j orelse continue;
                            if (row_j_ != row_i or col_j_ != col_i) {
                                increaseLevel(&levels[row_j_][col_j_]);
                            }
                        }
                    }
                }
            }
        }

        if (!had_a_flash) {
            break;
        }
    }

    var num_flashed: usize = 0;
    for (levels) |*row| {
        for (row) |*level| {
            if (level.* > flash_at) {
                level.* = 0;
                num_flashed += 1;
            }
        }
    }
    return num_flashed;
}

fn increaseLevel(level: *Level) void {
    if (level.* < flash_at) {
        level.* += 1;
    }
}

test "day 11 example 1" {
    const input_ =
        \\5483143223
        \\2745854711
        \\5264556173
        \\6141336146
        \\6357385478
        \\4167524645
        \\2176841721
        \\6882881134
        \\4846848554
        \\5283751526
        ;

    try std.testing.expectEqual(@as(usize, 1656), try part1(&input.readString(input_)));
    try std.testing.expectEqual(@as(usize, 195), try part2(&input.readString(input_)));
}
