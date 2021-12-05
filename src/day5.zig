const std = @import("std");

const input = @import("input.zig");

pub fn run(stdout: anytype) anyerror!void {
    {
        var input_ = try input.readFile("inputs/day5");
        defer input_.deinit();

        const result = try part1(&input_);
        try stdout.print("5a: {}\n", .{ result });
        std.debug.assert(result == 8622);
    }

    {
        var input_ = try input.readFile("inputs/day5");
        defer input_.deinit();

        const result = try part2(&input_);
        try stdout.print("5b: {}\n", .{ result });
        std.debug.assert(result == 22037);
    }
}

fn part1(input_: anytype) !usize {
    return solve(input_, false);
}

fn part2(input_: anytype) !usize {
    return solve(input_, true);
}

const Line = struct {
    start: Coord,
    end: Coord,

    fn init(s: []const u8) !@This() {
        var parts = std.mem.split(u8, s, " -> ");
        const start = parts.next() orelse return error.InvalidInput;
        const end = parts.next() orelse return error.InvalidInput;
        return Line {
            .start = try Coord.init(start),
            .end = try Coord.init(end),
        };
    }
};

const Coord = struct {
    const max = 999;
    const Type = std.math.IntFittingRange(0, max);

    x: Type,
    y: Type,

    fn init(s: []const u8) !@This() {
        var parts = std.mem.split(u8, s, ",");
        const x = parts.next() orelse return error.InvalidInput;
        const y = parts.next() orelse return error.InvalidInput;
        return Coord {
            .x = try std.fmt.parseInt(Type, x, 10),
            .y = try std.fmt.parseInt(Type, y, 10),
        };
    }
};

const Pos = enum {
    none,
    one,
    many,

    fn markVent(self: *@This()) void {
        self.* = switch (self.*) {
            .none => .one,
            .one => .many,
            .many => .many,
        };
    }
};

fn solve(input_: anytype, consider_diagonals: bool) !usize {
    var result: usize = 0;

    var grid: [Coord.max + 1][Coord.max + 1]Pos = [_][Coord.max + 1]Pos { [_]Pos{ .none } ** (Coord.max + 1) } ** (Coord.max + 1);

    while (try input_.next()) |line_s| {
        const line = try Line.init(line_s);

        if (!consider_diagonals and line.start.x != line.end.x and line.start.y != line.end.y) {
            continue;
        }

        var x = line.start.x;
        var y = line.start.y;

        while (true) {
            grid[x][y].markVent();

            if (x == line.end.x and y == line.end.y) {
                break;
            }

            switch (std.math.order(line.start.x, line.end.x)) {
                .lt => x += 1,
                .eq => {},
                .gt => x -= 1,
            }

            switch (std.math.order(line.start.y, line.end.y)) {
                .lt => y += 1,
                .eq => {},
                .gt => y -= 1,
            }
        }
    }

    for (grid) |*row| {
        result += std.mem.count(Pos, row, &[_]Pos { .many });
    }

    return result;
}

test "day 5 example 1" {
    const input_ =
        \\0,9 -> 5,9
        \\8,0 -> 0,8
        \\9,4 -> 3,4
        \\2,2 -> 2,1
        \\7,0 -> 7,4
        \\6,4 -> 2,0
        \\0,9 -> 2,9
        \\3,4 -> 1,4
        \\0,0 -> 8,8
        \\5,5 -> 8,2
        ;

    try std.testing.expectEqual(@as(usize, 5), try part1(&input.readString(input_)));
    try std.testing.expectEqual(@as(usize, 12), try part2(&input.readString(input_)));
}
