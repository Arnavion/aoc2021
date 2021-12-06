const std = @import("std");

const input = @import("input.zig");

pub fn run(stdout: anytype) anyerror!void {
    {
        var input_ = try input.readFile("inputs/day6");
        defer input_.deinit();

        const result = try part1(&input_);
        try stdout.print("6a: {}\n", .{ result });
        std.debug.assert(result == 365862);
    }

    {
        var input_ = try input.readFile("inputs/day6");
        defer input_.deinit();

        const result = try part2(&input_);
        try stdout.print("6b: {}\n", .{ result });
        std.debug.assert(result == 1653250886439);
    }
}

fn part1(input_: anytype) !usize {
    return solve(input_, 80);
}

fn part2(input_: anytype) !usize {
    return solve(input_, 256);
}

fn solve(input_: anytype, num_days: usize) !usize {
    const next_reproduction_after = 6;
    const newborn_next_reproduction_after = 8;
    const max_reproduction_after = std.math.max(next_reproduction_after, newborn_next_reproduction_after);
    const ReproductionAfter = std.math.IntFittingRange(0, max_reproduction_after);

    const line = (try input_.next()) orelse return error.InvalidInput;
    var line_parts = std.mem.split(u8, line, ",");

    var fish = [_]usize { 0 } ** (1 + max_reproduction_after);

    while (line_parts.next()) |part| {
        var num_days_remaining = try std.fmt.parseInt(ReproductionAfter, part, 10);
        fish[num_days_remaining] += 1;
    }

    var day: usize = 0;
    while (day < num_days) : (day += 1) {
        const num_newborns = fish[0];
        std.mem.copy(usize, fish[0..(fish.len - 1)], fish[1..]);
        fish[next_reproduction_after] += num_newborns;
        fish[newborn_next_reproduction_after] = num_newborns;
    }

    var sum: usize = 0;
    for (fish) |num_fish| {
        sum += num_fish;
    }
    return sum;
}

test "day 6 example 1" {
    const input_ =
        \\3,4,3,1,2
        ;

    try std.testing.expectEqual(@as(usize, 5934), try part1(&input.readString(input_)));
    try std.testing.expectEqual(@as(usize, 26984457539), try part2(&input.readString(input_)));
}
