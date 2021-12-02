const std = @import("std");

const input = @import("input.zig");

pub fn run(stdout: anytype) anyerror!void {
    {
        var input_ = try input.readFile("inputs/day2");
        defer input_.deinit();

        const result = try part1(&input_);
        try stdout.print("2a: {}\n", .{ result });
        std.debug.assert(result == 1813801);
    }

    {
        var input_ = try input.readFile("inputs/day2");
        defer input_.deinit();

        const result = try part2(&input_);
        try stdout.print("2b: {}\n", .{ result });
        std.debug.assert(result == 1960569556);
    }
}

fn part1(input_: anytype) !i64 {
    var horizontal: i64 = 0;
    var depth: i64 = 0;

    while (try input_.next()) |line| {
        const command = try parseCommand(line);

        switch (command.direction) {
            .forward => horizontal += command.distance,
            .down => depth += command.distance,
            .up => depth -= command.distance,
        }
    }

    return horizontal * depth;
}

fn part2(input_: anytype) !i64 {
    var horizontal: i64 = 0;
    var depth: i64 = 0;
    var aim: i64 = 0;

    while (try input_.next()) |line| {
        const command = try parseCommand(line);

        switch (command.direction) {
            .forward => {
                horizontal += command.distance;
                depth += aim * command.distance;
            },
            .down => aim += command.distance,
            .up => aim -= command.distance,
        }
    }

    return horizontal * depth;
}

const Command = struct {
    direction: Direction,
    distance: i64,
};

const Direction = enum {
    forward,
    down,
    up,
};

fn parseCommand(line: []const u8) !Command {
    var parts = std.mem.split(u8, line, " ");

    const direction_s = parts.next() orelse return error.InvalidInput;
    const direction = std.meta.stringToEnum(Direction, direction_s) orelse return error.InvalidInput;

    const distance_s = parts.next() orelse return error.InvalidInput;
    const distance = try std.fmt.parseInt(i64, distance_s, 10);

    return Command {
        .direction = direction,
        .distance = distance,
    };
}

test "day 2 example 1" {
    const input_ =
        \\forward 5
        \\down 5
        \\forward 8
        \\up 3
        \\down 8
        \\forward 2
        ;

    try std.testing.expectEqual(@as(i64, 15 * 10), try part1(&input.readString(input_)));
    try std.testing.expectEqual(@as(i64, 15 * 60), try part2(&input.readString(input_)));
}
