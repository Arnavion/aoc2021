const std = @import("std");

const input = @import("input.zig");

pub fn run(allocator: *std.mem.Allocator, stdout: anytype) anyerror!void {
    {
        var input_ = try input.readFile("inputs/day3");
        defer input_.deinit();

        const result = try part1(&input_);
        try stdout.print("3a: {}\n", .{ result });
        std.debug.assert(result == 4147524);
    }

    {
        var input_ = try input.readFile("inputs/day3");
        defer input_.deinit();

        const result = try part2(allocator, &input_);
        try stdout.print("3b: {}\n", .{ result });
        std.debug.assert(result == 3570354);
    }
}

const Datum = u12;
const DatumBits = std.math.Log2Int(Datum);
const Answer = std.math.IntFittingRange(0, std.math.maxInt(Datum) * std.math.maxInt(Datum));

fn part1(input_: anytype) !Answer {
    const Count = struct {
        ones: usize = 0,
        zeroes: usize = 0,
    };

    var counts = [_]Count { .{} } ** @bitSizeOf(Datum);

    while (try input_.next()) |line| {
        const datum = try std.fmt.parseInt(Datum, line, 2);

        var i: DatumBits = @bitSizeOf(Datum) - 1;
        while (true) : (i -= 1) {
            if (datum & (@as(Datum, 1) << i) == 0) {
                counts[i].zeroes += 1;
            }
            else {
                counts[i].ones += 1;
            }

            if (i == 0) {
                break;
            }
        }
    }

    var gamma_rate: Datum = 0;
    var epsilon_rate: Datum = 0;

    for (counts) |count, i| {
        if (count.ones == count.zeroes) {
            return error.InvalidInput;
        }

        if (count.ones > count.zeroes) {
            gamma_rate |= (@as(Datum, 1) << @intCast(DatumBits, i));
        }
        else if (count.ones > 0) {
            epsilon_rate |= (@as(Datum, 1) << @intCast(DatumBits, i));
        }
    }

    return @as(Answer, gamma_rate) * @as(Answer, epsilon_rate);
}

fn part2(allocator: *std.mem.Allocator, input_: anytype) !Answer {
    var input_list = std.ArrayList(Datum).init(allocator);
    defer input_list.deinit();
    while (try input_.next()) |line| {
        const datum = try std.fmt.parseInt(Datum, line, 2);
        try input_list.append(datum);
    }
    std.sort.sort(Datum, input_list.items, {}, comptime std.sort.asc(Datum));
    const input_slice: []const Datum = input_list.items;

    const oxygen_generator_rating = oxygen_generator_rating: {
        var oxygen_generator_input = input_slice;
        break :oxygen_generator_rating part2_inner(&oxygen_generator_input, .larger);
    };

    const co2_scrubber_rating = co2_scrubber_rating: {
        var co2_scrubber_input = input_slice;
        break :co2_scrubber_rating part2_inner(&co2_scrubber_input, .smaller);
    };

    return @as(Answer, oxygen_generator_rating) * @as(Answer, co2_scrubber_rating);
}

const Part2Choice = enum {
    larger,
    smaller,
};

fn part2_inner(input_: *[]const Datum, subslice_choice: Part2Choice) Datum {
    var num_bits_remaining: DatumBits = @bitSizeOf(Datum) - 1;
    while (true) : (num_bits_remaining -= 1) {
        const mid =
            ((input_.*)[0] & ~(@as(Datum, std.math.maxInt(Datum)) >> (@bitSizeOf(Datum) - 1 - num_bits_remaining))) |
            (@as(Datum, 1) << num_bits_remaining);

        var i: usize = input_.len / 2;
        while (i > 0 and (input_.*)[i - 1] >= mid) {
            i -= 1;
        }
        while (i < input_.len and (input_.*)[i] < mid) {
            i += 1;
        }

        const num_less_than_mid = i;
        const num_greater_than_mid = input_.len - i;

        if (num_less_than_mid > 0 and num_greater_than_mid > 0) {
            switch (subslice_choice) {
                .larger => {
                    if (num_less_than_mid <= num_greater_than_mid) {
                        input_.* = (input_.*)[i..];
                    }
                    else {
                        input_.* = (input_.*)[0..i];
                    }
                },
                .smaller => {
                    if (num_less_than_mid > num_greater_than_mid) {
                        input_.* = (input_.*)[i..];
                    }
                    else {
                        input_.* = (input_.*)[0..i];
                    }
                },
            }
        }

        if (input_.len == 1 or num_bits_remaining == 0) {
            return (input_.*)[0];
        }
    }
}

test "day 3 example 1" {
    const input_ =
        \\00100
        \\11110
        \\10110
        \\10111
        \\10101
        \\01111
        \\00111
        \\11100
        \\10000
        \\11001
        \\00010
        \\01010
        ;

    try std.testing.expectEqual(@as(Answer, 22 * 9), try part1(&input.readString(input_)));

    {
        var allocator = std.heap.GeneralPurposeAllocator(.{}){};
        defer {
            const leaked = allocator.deinit();
            if (leaked) {
                @panic("memory leaked");
            }
        }

        try std.testing.expectEqual(@as(Answer, 23 * 10), try part2(&allocator.allocator, &input.readString(input_)));
    }
}
