const std = @import("std");

const input = @import("input.zig");

pub fn run(stdout: anytype) anyerror!void {
    {
        var input_ = try input.readFile("inputs/day8");
        defer input_.deinit();

        const result = try part1(&input_);
        try stdout.print("8a: {}\n", .{ result });
        std.debug.assert(result == 239);
    }

    {
        var input_ = try input.readFile("inputs/day8");
        defer input_.deinit();

        const result = try part2(&input_);
        try stdout.print("8b: {}\n", .{ result });
        std.debug.assert(result == 946346);
    }
}

fn part1(input_: anytype) !usize {
    var result: usize = 0;

    while (try input_.next()) |line| {
        var line_parts = std.mem.split(u8, line, " | ");

        _ = line_parts.next();

        const output_part = line_parts.next() orelse return error.InvalidInput;
        var output_digits = std.mem.split(u8, output_part, " ");
        while (output_digits.next()) |output_digit| {
            result += @as(usize, switch (output_digit.len) {
                2, 3, 4, 7 => 1,
                5, 6 => 0,
                else => return error.InvalidInput,
            });
        }
    }

    return result;
}

fn part2(input_: anytype) !u64 {
    var result: u64 = 0;

    while (try input_.next()) |line| {
        var line_parts = std.mem.split(u8, line, " | ");

        const input_part = line_parts.next() orelse return error.InvalidInput;
        var input_digits = std.mem.split(u8, input_part, " ");

        //  pppp
        // q    r
        // q    r
        //  ssss
        // t    u
        // t    u
        //  vvvv
        //
        // [2] one   = ..r..u.
        // [3] seven = p.r..u.
        // [4] four  = .qrs.u.
        // [5] two   = p.rst.v
        // [5] three = p.rs.uv
        // [5] five  = pq.s.uv
        // [6] zero  = pqr.tuv
        // [6] six   = pq.stuv
        // [6] nine  = pqrs.uv
        // [7] eight = pqrstuv

        var maybe_one: ?SegmentSet = null;
        var maybe_four: ?SegmentSet = null;
        var maybe_seven: ?SegmentSet = null;
        var maybe_eight: ?SegmentSet = null;
        var two_or_three_or_five_list = std.BoundedArray(SegmentSet, 3).init(0) catch unreachable;
        var zero_or_six_or_nine_list = std.BoundedArray(SegmentSet, 3).init(0) catch unreachable;
        while (input_digits.next()) |input_digit| {
            switch (input_digit.len) {
                2 => {
                    if (maybe_one != null) {
                        return error.InvalidInput;
                    }
                    maybe_one = try makeSegmentSet(input_digit);
                },
                3 => {
                    if (maybe_seven != null) {
                        return error.InvalidInput;
                    }
                    maybe_seven = try makeSegmentSet(input_digit);
                },
                4 => {
                    if (maybe_four != null) {
                        return error.InvalidInput;
                    }
                    maybe_four = try makeSegmentSet(input_digit);
                },
                5 => try two_or_three_or_five_list.append(try makeSegmentSet(input_digit)),
                6 => try zero_or_six_or_nine_list.append(try makeSegmentSet(input_digit)),
                7 => {
                    if (maybe_eight != null) {
                        return error.InvalidInput;
                    }
                    maybe_eight = try makeSegmentSet(input_digit);
                },
                else => return error.InvalidInput,
            }
        }

        const one = maybe_one orelse return error.InvalidInput;
        const four = maybe_four orelse return error.InvalidInput;
        const seven = maybe_seven orelse return error.InvalidInput;
        const eight = maybe_eight orelse return error.InvalidInput;
        const two_or_three_or_five = two_or_three_or_five_list.constSlice();
        if (two_or_three_or_five.len != 3) {
            return error.InvalidInput;
        }
        const zero_or_six_or_nine = zero_or_six_or_nine_list.constSlice();
        if (zero_or_six_or_nine.len != 3) {
            return error.InvalidInput;
        }
        std.debug.assert(eight == 0b1111111);

        // seven - one => p
        const p = seven & ~one;
        std.debug.assert(@popCount(SegmentSet, p) == 1);

        // two - four - seven => tv
        // three - four - seven => v
        // five - four - seven => v
        const v = v: {
            for (two_or_three_or_five) |two_or_three_or_five_| {
                const tv = two_or_three_or_five_ & ~four & ~seven;
                if (@popCount(SegmentSet, tv) == 1) {
                    break :v tv;
                }
            }

            unreachable;
        };

        // eight - four - seven - v => t
        const t = ~four & ~seven & ~v;
        std.debug.assert(@popCount(SegmentSet, t) == 1);

        // two - one - p - t - v => s
        // three - one - p - t - v => s
        // five - one - p - t - v => qs
        const s = s: {
            for (two_or_three_or_five) |two_or_three_or_five_| {
                const qs = two_or_three_or_five_ & ~one & ~p & ~t & ~v;
                if (@popCount(SegmentSet, qs) == 1) {
                    break :s qs;
                }
            }

            unreachable;
        };

        // eight - one - p - s - t - v => q
        const q = ~one & ~p & ~s & ~t & ~v;
        std.debug.assert(@popCount(SegmentSet, q) == 1);

        // zero - p - q - s - t - v => ru
        // six - p - q - s - t - v => u
        // nine - p - q - s - t - v => ru
        const u = u: {
            for (zero_or_six_or_nine) |zero_or_six_or_nine_| {
                const ru = zero_or_six_or_nine_ & ~p & ~q & ~s & ~t & ~v;
                if (@popCount(SegmentSet, ru) == 1) {
                    break :u ru;
                }
            }

            unreachable;
        };

        // eight - p - q - s - t - u - v => r
        const r = ~p & ~q & ~s & ~t & ~u & ~v;
        std.debug.assert(@popCount(SegmentSet, r) == 1);

        const digits = [_]SegmentSet {
            p | q | r | t | u | v,
            r | u,
            p | r | s | t | v,
            p | r | s | u | v,
            q | r | s | u,
            p | q | s | u | v,
            p | q | s | t | u | v,
            p | r | u,
            p | q | r | s | t | u | v,
            p | q | r | s | u | v,
        };

        const outputs = line_parts.next() orelse return error.InvalidInput;
        var output_parts = std.mem.split(u8, outputs, " ");
        var output_num: u64 = 0;
        while (output_parts.next()) |output| {
            const output_set = try makeSegmentSet(output);
            const digit = std.mem.indexOfScalar(SegmentSet, digits[0..], output_set) orelse return error.InvalidInput;
            output_num = output_num * 10 + digit;
        }

        result += output_num;
    }

    return result;
}

const SegmentSet = u7;

fn makeSegmentSet(s: []const u8) !SegmentSet {
    var result: SegmentSet = 0;
    for (s) |c| {
        switch (c) {
            'a' => result |= 0b1000000,
            'b' => result |= 0b0100000,
            'c' => result |= 0b0010000,
            'd' => result |= 0b0001000,
            'e' => result |= 0b0000100,
            'f' => result |= 0b0000010,
            'g' => result |= 0b0000001,
            else => return error.InvalidInput,
        }
    }
    return result;
}

test "day 8 example 1" {
    const input_ =
        \\be cfbegad cbdgef fgaecd cgeb fdcge agebfd fecdb fabcd edb | fdgacbe cefdb cefbgd gcbe
        \\edbfga begcd cbg gc gcadebf fbgde acbgfd abcde gfcbed gfec | fcgedb cgb dgebacf gc
        \\fgaebd cg bdaec gdafb agbcfd gdcbef bgcad gfac gcb cdgabef | cg cg fdcagb cbg
        \\fbegcd cbd adcefb dageb afcb bc aefdc ecdab fgdeca fcdbega | efabcd cedba gadfec cb
        \\aecbfdg fbg gf bafeg dbefa fcge gcbea fcaegb dgceab fcbdga | gecf egdcabf bgf bfgea
        \\fgeab ca afcebg bdacfeg cfaedg gcfdb baec bfadeg bafgc acf | gebdcfa ecba ca fadegcb
        \\dbcfg fgd bdegcaf fgec aegbdf ecdfab fbedc dacgb gdcebf gf | cefg dcbef fcge gbcadfe
        \\bdfegc cbegaf gecbf dfcage bdacg ed bedf ced adcbefg gebcd | ed bcgafe cdgba cbgef
        \\egadfb cdbfeg cegd fecab cgb gbdefca cg fgcdab egfdb bfceg | gbdfcae bgc cg cgb
        \\gcafb gcf dcaebfg ecagb gf abcdeg gaef cafbge fdbac fegbdc | fgae cfgab fg bagce
        ;

    try std.testing.expectEqual(@as(usize, 26), try part1(&input.readString(input_)));
    try std.testing.expectEqual(@as(u64, 8394 + 9781 + 1197 + 9361 + 4873 + 8418 + 4548 + 1625 + 8717 + 4315), try part2(&input.readString(input_)));
}
