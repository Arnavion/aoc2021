const std = @import("std");

const input = @import("input.zig");

pub fn run(stdout: anytype) anyerror!void {
    {
        var input_ = try input.readFile("inputs/day1");
        defer input_.deinit();

        const result = try part1(&input_);
        try stdout.print("1a: {}\n", .{ result });
        std.debug.assert(result == 1292);
    }

    {
        var input_ = try input.readFile("inputs/day1");
        defer input_.deinit();

        const result = try part2(&input_);
        try stdout.print("1b: {}\n", .{ result });
        std.debug.assert(result == 1262);
    }
}

const Datum = u16;

fn part1(input_: anytype) !usize {
    return solve(1, input_);
}

fn part2(input_: anytype) !usize {
    return solve(3, input_);
}

fn solve(comptime n: usize, input_: anytype) !usize {
    var window = [_]Datum { std.math.maxInt(Datum) } ** n;
    var result: usize = 0;
    var window_start: usize = 0;

    while (try input_.next()) |line| {
        const datum = try std.fmt.parseInt(Datum, line, 10);
        if (datum > window[window_start]) {
            result += 1;
        }

        window[window_start] = datum;
        window_start = (window_start + 1) % n;
    }

    return result;
}

test "day 1 example 1" {
    const input_ =
        \\199
        \\200
        \\208
        \\210
        \\200
        \\207
        \\240
        \\269
        \\260
        \\263
        ;

    try std.testing.expectEqual(@as(usize, 7), try part1(&input.readString(input_)));
    try std.testing.expectEqual(@as(usize, 5), try part2(&input.readString(input_)));
}
