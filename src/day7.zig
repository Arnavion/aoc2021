const std = @import("std");

const input = @import("input.zig");

pub fn run(stdout: anytype) anyerror!void {
    {
        var input_ = try input.readFile("inputs/day7");
        defer input_.deinit();

        const result = try part1(&input_);
        try stdout.print("7a: {}\n", .{ result });
        std.debug.assert(result == 328187);
    }

    {
        var input_ = try input.readFile("inputs/day7");
        defer input_.deinit();

        const result = try part2(&input_);
        try stdout.print("7b: {}\n", .{ result });
        std.debug.assert(result == 91257582);
    }
}

const NumCrabs = u8;

const max_distance = 2000;
const Distance = std.math.IntFittingRange(0, max_distance);

// https://www.wolframalpha.com/input/?i=summation%28%28n%5E2+%2B+2n+%2B+1%29+%2F+2%29
const max_fuel_used =
    (2 * max_distance * max_distance * max_distance + 9 * max_distance * max_distance + 13 * max_distance) * std.math.maxInt(NumCrabs) / 12;
const FuelUsed = std.math.IntFittingRange(0, max_fuel_used);

fn part1(input_: anytype) !FuelUsed {
    return solve(input_, part1_fuel_used);
}

fn part1_fuel_used(distance: Distance) FuelUsed {
    return @as(FuelUsed, distance);
}

fn part2(input_: anytype) !FuelUsed {
    return solve(input_, part2_fuel_used);
}

fn part2_fuel_used(distance: Distance) FuelUsed {
    return (@as(FuelUsed, distance) * @as(FuelUsed, distance + 1)) / 2;
}

fn solve(input_: anytype, fuel_used: fn(Distance) FuelUsed) !FuelUsed {
    const line = (try input_.next()) orelse return error.InvalidInput;
    var line_parts = std.mem.split(u8, line, ",");

    var crabs = [_]NumCrabs { 0 } ** max_distance;
    var realMaxDistance: Distance = 0;

    while (line_parts.next()) |part| {
        var pos = try std.fmt.parseInt(Distance, part, 10);
        crabs[pos] += 1;
        realMaxDistance = std.math.max(realMaxDistance, pos);
    }

    var end: Distance = 0;
    var best_sum: FuelUsed = max_fuel_used;
    outer: while (end <= realMaxDistance) : (end += 1) {
        var sum: FuelUsed = 0;
        var pos: Distance = 0;
        while (pos < crabs.len) : (pos += 1) {
            const distance = std.math.max(pos, end) - std.math.min(pos, end);
            const num_crabs = crabs[pos];
            sum += fuel_used(distance) * num_crabs;
            if (sum > best_sum) {
                continue :outer;
            }
        }
        best_sum = sum;
    }

    return best_sum;
}

test "day 7 example 1" {
    const input_ =
        \\16,1,2,0,4,2,7,1,2,14
        ;

    try std.testing.expectEqual(@as(FuelUsed, 14 + 1 + 0 + 2 + 2 + 0 + 5 + 1 + 0 + 12), try part1(&input.readString(input_)));
    try std.testing.expectEqual(@as(FuelUsed, 66 + 10 + 6 + 15 + 1 + 6 + 3 + 10 + 6 + 45), try part2(&input.readString(input_)));
}
