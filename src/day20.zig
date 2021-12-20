const std = @import("std");

const input = @import("input.zig");

pub fn run(stdout: anytype) anyerror!void {
    {
        var input_ = try input.readFile("inputs/day20");
        defer input_.deinit();

        const result = try part1(&input_);
        try stdout.print("20a: {}\n", .{ result });
        std.debug.assert(result == 5680);
    }

    {
        var input_ = try input.readFile("inputs/day20");
        defer input_.deinit();

        const result = try part2(&input_);
        try stdout.print("20b: {}\n", .{ result });
        std.debug.assert(result == 19766);
    }
}

fn part1(input_: anytype) !usize {
    return solve(input_, 2);
}

fn part2(input_: anytype) !usize {
    return solve(input_, 50);
}

fn solve(input_: anytype, comptime num_steps: usize) !usize {
    const num_rows = 100 + num_steps * 2 + 2 * 2;
    const num_cols = 100 + num_steps * 2 + 2 * 2;

    var algorithm: [512]u1 = undefined;
    {
        const line = (try input_.next()) orelse return error.InvalidInput;
        if (line.len != 512) {
            return error.InvalidInput;
        }
        for (line) |c, i| {
            algorithm[i] = switch (c) {
                '#' => 1,
                '.' => 0,
                else => return error.InvalidInput,
            };
        }
    }

    var image: [num_rows][num_cols]u1 = [_][num_cols]u1 { [_]u1 { 0 } ** num_cols } ** num_rows;

    _ = try input_.next();

    {
        var row_i: usize = num_steps + 2;
        while (try input_.next()) |line| {
            for (line) |c, col_i_| {
                const col_i = num_steps + col_i_ + 2;
                image[row_i][col_i] = switch (c) {
                    '#' => 1,
                    '.' => 0,
                    else => return error.InvalidInput,
                };
            }

            row_i += 1;
        }
    }

    {
        var new_image = image;

        var step_i: usize = 1;
        while (step_i <= num_steps) : (step_i += 1) {
            for (new_image) |*row, row_i| {
                for (row) |*new_b, col_i| {
                    const up = std.math.sub(usize, row_i, 1) catch row_i;
                    const down = if (std.math.add(usize, row_i, 1) catch null) |down_| if (down_ < num_rows) down_ else row_i else row_i;
                    const left = std.math.sub(usize, col_i, 1) catch col_i;
                    const right = if (std.math.add(usize, col_i, 1) catch null) |right_| if (right_ < num_cols) right_ else col_i else col_i;

                    var index: u9 = 0;

                    for ([_]usize { up, row_i, down }) |row_j| {
                        for ([_]usize { left, col_i, right }) |col_j| {
                            index = (index << 1) | image[row_j][col_j];
                        }
                    }

                    new_b.* = algorithm[index];
                }
            }

            image = new_image;
        }
    }

    var result: usize = 0;
    for (image) |row| {
        for (row) |b| {
            result += b;
        }
    }
    return result;
}

test "day 20 example 1" {
    const input_ =
        \\..#.#..#####.#.#.#.###.##.....###.##.#..###.####..#####..#....#..#..##..###..######.###...####..#..#####..##..#.#####...##.#.#..#.##..#.#......#.###.######.###.####...#.##.##..#..#..#####.....#.#....###..#.##......#.....#..#..#..##..#...##.######.####.####.#.#...#.......#..#.#.#...####.##.#......#..#...##.#.##..#...##.#.##..###.#......#.#.......#.#.#.####.###.##...#.....####.#..#..#.##.#....##..#.####....##...##..#...#......#.#.......#.......##..####..#...#.#.#...##..#.#..###..#####........#..####......#..#
        \\
        \\#..#.
        \\#....
        \\##..#
        \\..#..
        \\..###
        ;

    try std.testing.expectEqual(@as(usize, 35), try part1(&input.readString(input_)));
    try std.testing.expectEqual(@as(usize, 3351), try part2(&input.readString(input_)));
}
