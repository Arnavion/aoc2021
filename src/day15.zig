const builtin = @import("builtin");
const std = @import("std");

const input = @import("input.zig");

pub fn run(stdout: anytype) anyerror!void {
    const side_length = 100;

    {
        var input_ = try input.readFile("inputs/day15");
        defer input_.deinit();

        const result = try part1(.stripe, side_length, &input_);
        try stdout.print("15a[stripe]: {}\n", .{ result });
        std.debug.assert(result == 592);
    }

    {
        var input_ = try input.readFile("inputs/day15");
        defer input_.deinit();

        const result = try part1(.dijkstra, side_length, &input_);
        try stdout.print("15a[dijkstra]: {}\n", .{ result });
        std.debug.assert(result == 592);
    }

    // Both strip and dijkstra are annoyingly slow in debug.
    if (builtin.mode != .Debug) {
        var input_ = try input.readFile("inputs/day15");
        defer input_.deinit();

        const result = try part2(.stripe, side_length, &input_);
        try stdout.print("15b[stripe]: {}\n", .{ result });
        std.debug.assert(result == 2897);
    }

    if (builtin.mode != .Debug) {
        var input_ = try input.readFile("inputs/day15");
        defer input_.deinit();

        const result = try part2(.dijkstra, side_length, &input_);
        try stdout.print("15b[dijkstra]: {}\n", .{ result });
        std.debug.assert(result == 2897);
    }
}

const max_level = 9;
const Level = std.math.IntFittingRange(0, max_level);
const Sum = std.math.IntFittingRange(0, max_level * (2 * 100) * 25);

// Surprisingly, stripe is faster than dijkstra in release (~0s vs ~1s) and much faster in debug (~2s vs ~4s).
const Algorithm = enum {
    stripe,
    dijkstra,
};

fn part1(comptime algorithm: Algorithm, comptime side_length: usize, input_: anytype) !Sum {
    var levels = try parseInput(side_length, input_);

    const SolveContext = struct {
        levels: *[side_length][side_length]Level,

    fn getLevel(self: *const @This(), row: usize, col: usize) Level {
            return self.levels[row][col];
        }
    };
    return solve(algorithm, side_length, SolveContext { .levels = &levels });
}

fn part2(comptime algorithm: Algorithm, comptime side_length: usize, input_: anytype) !Sum {
    var levels = try parseInput(side_length, input_);

    const SolveContext = struct {
        levels: *[side_length][side_length]Level,

        fn getLevel(self: *const @This(), row: usize, col: usize) Level {
            return @intCast(Level, ((@as(u8, self.levels[row % side_length][col % side_length]) - 1) + row / side_length + col / side_length) % 9 + 1);
        }
    };
    return solve(algorithm, side_length * 5, SolveContext { .levels = &levels });
}

fn parseInput(comptime side_length: usize, input_: anytype) ![side_length][side_length]Level {
    var levels: [side_length][side_length]Level = [_][side_length]Level { [_]Level { max_level } ** side_length } ** side_length;

    var row_i: usize = 0;
    while (try input_.next()) |line| {
        for (line) |c, col_i| {
            if (c < '0' or c > '9') {
                return error.InvalidInput;
            }

            levels[row_i][col_i] = @intCast(Level, c - '0');
        }
        row_i += 1;
    }

    return levels;
}

fn solve(
    comptime algorithm: Algorithm,
    comptime side_length: usize,
    context: anytype,
) !Sum {
    return switch (algorithm) {
        .stripe => solve_stripe(side_length, context),
        .dijkstra => solve_dijkstra(side_length, context),
    };
}

fn solve_stripe(
    comptime side_length: usize,
    context: anytype,
) !Sum {
    var sum: [side_length][side_length]Sum = [_][side_length]Sum { [_]Sum { std.math.maxInt(Sum) } ** side_length } ** side_length;
    sum[side_length - 1][side_length - 1] = context.getLevel(side_length - 1, side_length - 1);

    while (true) {
        var one_sum_recalculated = false;

        var row_i: usize = side_length - 1;
        while (true) : (row_i -= 1) {
            var col_i: usize = side_length - 1;
            while (true) : (col_i -= 1) {
                const level = context.getLevel(row_i, col_i);
                const current_sum = sum[row_i][col_i];

                var new_sum = current_sum;
                if (row_i > 0) {
                    if (std.math.add(Sum, sum[row_i - 1][col_i], level) catch null) |up_sum| {
                        new_sum = std.math.min(new_sum, up_sum);
                    }
                }
                if (col_i > 0) {
                    if (std.math.add(Sum, sum[row_i][col_i - 1], level) catch null) |left_sum| {
                        new_sum = std.math.min(new_sum, left_sum);
                    }
                }
                if (row_i < side_length - 1) {
                    if (std.math.add(Sum, sum[row_i + 1][col_i], level) catch null) |down_sum| {
                        new_sum = std.math.min(new_sum, down_sum);
                    }
                }
                if (col_i < side_length - 1) {
                    if (std.math.add(Sum, sum[row_i][col_i + 1], level) catch null) |right_sum| {
                        new_sum = std.math.min(new_sum, right_sum);
                    }
                }
                if (new_sum != current_sum) {
                    sum[row_i][col_i] = new_sum;
                    one_sum_recalculated = true;
                }

                if (col_i == 0) {
                    break;
                }
            }

            if (row_i == 0) {
                break;
            }
        }

        if (!one_sum_recalculated) {
            break;
        }
    }

    return std.math.min(sum[0][1], sum[1][0]);
}

fn Coord(comptime side_length: usize) type {
    return struct {
        row: std.math.IntFittingRange(0, side_length - 1),
        col: std.math.IntFittingRange(0, side_length - 1),
    };
}

const SumNode = struct {
    sum: Sum,
    level: Level,
    visited: bool,
};

fn solve_dijkstra(
    comptime side_length: usize,
    context: anytype,
) !Sum {
    var sum: [side_length][side_length]SumNode = undefined;
    for (sum) |*row, row_i| {
        for (row) |*node, col_i| {
            node.sum = std.math.maxInt(Sum);
            node.level = context.getLevel(row_i, col_i);
            node.visited = false;
        }
    }
    sum[0][0].sum = 0;

    var to_visit = std.BoundedArray(Coord(side_length), side_length * side_length).init(0) catch unreachable;
    try to_visit.append(.{ .row = 0, .col = 0 });

    while (std.sort.argMin(Coord(side_length), to_visit.constSlice(), &sum, comptime sortCoord(side_length))) |min_coord_i| {
        const coord = to_visit.swapRemove(min_coord_i);

        if (coord.row == side_length - 1 and coord.col == side_length - 1) {
            break;
        }

        sum[coord.row][coord.col].visited = true;

        if (coord.row > 0) {
            const up = Coord(side_length) { .row = coord.row - 1, .col = coord.col };
            if (!sum[up.row][up.col].visited) {
                sum[up.row][up.col].sum = std.math.min(sum[up.row][up.col].sum, sum[coord.row][coord.col].sum + sum[up.row][up.col].level);
                try queueForVisiting(side_length, &to_visit, up);
            }
        }
        if (coord.col > 0) {
            const left = Coord(side_length) { .row = coord.row, .col = coord.col - 1 };
            if (!sum[left.row][left.col].visited) {
                sum[left.row][left.col].sum = std.math.min(sum[left.row][left.col].sum, sum[coord.row][coord.col].sum + sum[left.row][left.col].level);
                try queueForVisiting(side_length, &to_visit, left);
            }
        }
        if (coord.col < side_length - 1) {
            const right = Coord(side_length) { .row = coord.row, .col = coord.col + 1 };
            if (!sum[right.row][right.col].visited) {
                sum[right.row][right.col].sum = std.math.min(sum[right.row][right.col].sum, sum[coord.row][coord.col].sum + sum[right.row][right.col].level);
                try queueForVisiting(side_length, &to_visit, right);
            }
        }
        if (coord.row < side_length - 1) {
            const down = Coord(side_length) { .row = coord.row + 1, .col = coord.col };
            if (!sum[down.row][down.col].visited) {
                sum[down.row][down.col].sum = std.math.min(sum[down.row][down.col].sum, sum[coord.row][coord.col].sum + sum[down.row][down.col].level);
                try queueForVisiting(side_length, &to_visit, down);
            }
        }
    }

    return sum[side_length - 1][side_length - 1].sum;
}

fn sortCoord(comptime side_length: usize) fn(context: *const [side_length][side_length]SumNode, Coord(side_length), Coord(side_length)) bool {
    const impl = struct {
        fn inner(context: *const [side_length][side_length]SumNode, a: Coord(side_length), b: Coord(side_length)) bool {
            return context[a.row][a.col].sum < context[b.row][b.col].sum;
        }
    };
    return impl.inner;
}

fn queueForVisiting(
    comptime side_length: usize,
    to_visit: *std.BoundedArray(Coord(side_length), side_length * side_length),
    new_coord: Coord(side_length),
) !void {
    for (to_visit.constSlice()) |coord| {
        if (std.meta.eql(coord, new_coord)) {
            return;
        }
    }

    try to_visit.append(new_coord);
}

test "day 15 example 1" {
    const input_ =
        \\1163751742
        \\1381373672
        \\2136511328
        \\3694931569
        \\7463417111
        \\1319128137
        \\1359912421
        \\3125421639
        \\1293138521
        \\2311944581
        ;

    const side_length = 10;
    try std.testing.expectEqual(@as(usize, 40), try part1(.stripe, side_length, &input.readString(input_)));
    try std.testing.expectEqual(@as(usize, 40), try part1(.dijkstra, side_length, &input.readString(input_)));
    try std.testing.expectEqual(@as(usize, 315), try part2(.stripe, side_length, &input.readString(input_)));
    try std.testing.expectEqual(@as(usize, 315), try part2(.dijkstra, side_length, &input.readString(input_)));
}
