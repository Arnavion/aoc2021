const std = @import("std");

const input = @import("input.zig");

pub fn run(allocator: std.mem.Allocator, stdout: anytype) anyerror!void {
    const side_length = 100;

    {
        var input_ = try input.readFile("inputs/day15");
        defer input_.deinit();

        const result = try part1(side_length, allocator, &input_);
        try stdout.print("15a: {}\n", .{ result });
        std.debug.assert(result == 592);
    }

    {
        var input_ = try input.readFile("inputs/day15");
        defer input_.deinit();

        const result = try part2(side_length, allocator, &input_);
        try stdout.print("15b: {}\n", .{ result });
        std.debug.assert(result == 2897);
    }
}

const max_level = 9;
const Level = std.math.IntFittingRange(0, max_level);
const Sum = std.math.IntFittingRange(0, max_level * (2 * 100) * 25);

fn part1(comptime side_length: usize, allocator: std.mem.Allocator, input_: anytype) !Sum {
    var levels = try parseInput(side_length, input_);

    const SolveContext = struct {
        levels: *[side_length][side_length]Level,

    fn getLevel(self: *const @This(), row: usize, col: usize) Level {
            return self.levels[row][col];
        }
    };
    return solve(side_length, allocator, SolveContext { .levels = &levels });
}

fn part2(comptime side_length: usize, allocator: std.mem.Allocator, input_: anytype) !Sum {
    var levels = try parseInput(side_length, input_);

    const SolveContext = struct {
        levels: *[side_length][side_length]Level,

        fn getLevel(self: *const @This(), row: usize, col: usize) Level {
            return @intCast(Level, ((@as(u8, self.levels[row % side_length][col % side_length]) - 1) + row / side_length + col / side_length) % 9 + 1);
        }
    };
    return solve(side_length * 5, allocator, SolveContext { .levels = &levels });
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

fn solve(comptime side_length: usize, allocator: std.mem.Allocator, context: anytype) !Sum {
    var sum: [side_length][side_length]SumNode = undefined;
    for (sum) |*row, row_i| {
        for (row) |*node, col_i| {
            node.sum = std.math.maxInt(Sum);
            node.level = context.getLevel(row_i, col_i);
            node.visited = false;
        }
    }
    sum[0][0].sum = 0;

    var to_visit = std.PriorityQueue(Coord(side_length), *const [side_length][side_length]SumNode, comptime sortCoord(side_length)).init(allocator, &sum);
    defer to_visit.deinit();
    try to_visit.add(.{ .row = 0, .col = 0 });

    while (to_visit.removeOrNull()) |coord| {
        const current_sum = sum[coord.row][coord.col].sum;

        if (coord.row == side_length - 1 and coord.col == side_length - 1) {
            return current_sum;
        }

        if (sum[coord.row][coord.col].visited) {
            continue;
        }
        sum[coord.row][coord.col].visited = true;

        if (coord.row > 0) {
            const up = Coord(side_length) { .row = coord.row - 1, .col = coord.col };
            if (!sum[up.row][up.col].visited) {
                const new_sum = std.math.min(sum[up.row][up.col].sum, current_sum + sum[up.row][up.col].level);
                if (new_sum < sum[up.row][up.col].sum) {
                    sum[up.row][up.col].sum = new_sum;
                    try queueForVisiting(side_length, &to_visit, up);
                }
            }
        }
        if (coord.col > 0) {
            const left = Coord(side_length) { .row = coord.row, .col = coord.col - 1 };
            if (!sum[left.row][left.col].visited) {
                const new_sum = std.math.min(sum[left.row][left.col].sum, current_sum + sum[left.row][left.col].level);
                if (new_sum < sum[left.row][left.col].sum) {
                    sum[left.row][left.col].sum = new_sum;
                    try queueForVisiting(side_length, &to_visit, left);
                }
            }
        }
        if (coord.col < side_length - 1) {
            const right = Coord(side_length) { .row = coord.row, .col = coord.col + 1 };
            if (!sum[right.row][right.col].visited) {
                const new_sum = std.math.min(sum[right.row][right.col].sum, current_sum + sum[right.row][right.col].level);
                if (new_sum < sum[right.row][right.col].sum) {
                    sum[right.row][right.col].sum = new_sum;
                    try queueForVisiting(side_length, &to_visit, right);
                }
            }
        }
        if (coord.row < side_length - 1) {
            const down = Coord(side_length) { .row = coord.row + 1, .col = coord.col };
            if (!sum[down.row][down.col].visited) {
                const new_sum = std.math.min(sum[down.row][down.col].sum, current_sum + sum[down.row][down.col].level);
                if (new_sum < sum[down.row][down.col].sum) {
                    sum[down.row][down.col].sum = new_sum;
                    try queueForVisiting(side_length, &to_visit, down);
                }
            }
        }
    }

    return error.InvalidInput;
}

fn sortCoord(comptime side_length: usize) fn(context: *const [side_length][side_length]SumNode, Coord(side_length), Coord(side_length)) std.math.Order {
    const impl = struct {
        fn inner(context: *const [side_length][side_length]SumNode, a: Coord(side_length), b: Coord(side_length)) std.math.Order {
            return std.math.order(context[a.row][a.col].sum, context[b.row][b.col].sum);
        }
    };
    return impl.inner;
}

fn queueForVisiting(
    comptime side_length: usize,
    to_visit: *std.PriorityQueue(Coord(side_length), *const [side_length][side_length]SumNode, sortCoord(side_length)),
    new_coord: Coord(side_length),
) !void {
    try to_visit.add(new_coord);
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

    try std.testing.expectEqual(@as(usize, 40), try part1(side_length, std.testing.allocator, &input.readString(input_)));
    try std.testing.expectEqual(@as(usize, 315), try part2(side_length, std.testing.allocator, &input.readString(input_)));
}
