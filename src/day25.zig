const std = @import("std");

const input = @import("input.zig");

pub fn run(stdout: anytype) anyerror!void {
    {
        var input_ = try input.readFile("inputs/day25");
        defer input_.deinit();

        const result = try part1(137, 139, &input_);
        try stdout.print("25a: {}\n", .{ result });
        std.debug.assert(result == 305);
    }
}

const Spot = enum {
    empty,
    right,
    down,
};

fn part1(comptime num_rows: usize, comptime num_cols: usize, input_: anytype) !usize {
    var grid: [num_rows][num_cols]Spot = undefined;

    {
        var row_i: usize = 0;
        while (try input_.next()) |line| {
            for (line) |c, col_i| {
                grid[row_i][col_i] = switch (c) {
                    '.' => .empty,
                    '>' => .right,
                    'v' => .down,
                    else => return error.InvalidInput,
                };
            }

            row_i += 1;
        }
    }

    var new_grid = grid;

    var step_num: usize = 1;
    while (true) {
        var one_moved = false;

        for (grid) |row, row_i| {
            for (row) |spot, col_i| {
                const right = (col_i + 1) % num_cols;
                if (spot == .right and row[right] == .empty) {
                    new_grid[row_i][col_i] = .empty;
                    new_grid[row_i][right] = .right;
                    one_moved = true;
                }
            }
        }

        grid = new_grid;

        for (grid) |row, row_i| {
            const down = (row_i + 1) % num_rows;
            for (row) |spot, col_i| {
                if (spot == .down and grid[down][col_i] == .empty) {
                    new_grid[row_i][col_i] = .empty;
                    new_grid[down][col_i] = .down;
                    one_moved = true;
                }
            }
        }

        grid = new_grid;

        if (!one_moved) {
            break;
        }

        step_num += 1;
    }

    return step_num;
}

test "day 25 example 1" {
    const input_ =
        \\v...>>.vv>
        \\.vv>>.vv..
        \\>>.>v>...v
        \\>>v>>.>.v.
        \\v>v.vv.v..
        \\>.>>..v...
        \\.vv..>.>v.
        \\v.v..>>v.v
        \\....v..v.>
        ;

    try std.testing.expectEqual(@as(usize, 58), try part1(9, 10, &input.readString(input_)));
}
