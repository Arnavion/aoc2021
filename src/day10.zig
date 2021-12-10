const std = @import("std");

const input = @import("input.zig");

pub fn run(stdout: anytype) anyerror!void {
    {
        var input_ = try input.readFile("inputs/day10");
        defer input_.deinit();

        const result = try part1(&input_);
        try stdout.print("10a: {}\n", .{ result });
        std.debug.assert(result == 294195);
    }

    {
        var input_ = try input.readFile("inputs/day10");
        defer input_.deinit();

        const result = try part2(&input_);
        try stdout.print("10b: {}\n", .{ result });
        std.debug.assert(result == 3490802734);
    }
}

const Answer = u64;

fn part1(input_: anytype) !Answer {
    var result: Answer = 0;

    while (try input_.next()) |line| {
        const line_validation_result = try validateLine(line);
        switch (line_validation_result) {
            .invalid_char => |invalid_char| result += @as(Answer, switch (invalid_char) {
                .@")" => 3,
                .@"]" => 57,
                .@"}" => 1197,
                .@">" => 25137,
                else => unreachable,
            }),

            else => {},
        }
    }

    return result;
}

fn part2(input_: anytype) !Answer {
    var all_scores = std.BoundedArray(Answer, max_line_len).init(0) catch unreachable;

    while (try input_.next()) |line| {
        var line_validation_result = try validateLine(line);
        switch (line_validation_result) {
            .remaining_closing_chars => |*remaining_closing_chars| {
                var score: Answer = 0;

                while (remaining_closing_chars.popOrNull()) |c| {
                    score = score * 5 + @as(Answer, switch (c) {
                        .@")" => 1,
                        .@"]" => 2,
                        .@"}" => 3,
                        .@">" => 4,
                        else => unreachable,
                    });
                }

                try all_scores.append(score);
            },

            else => {},
        }
    }

    std.sort.sort(Answer, all_scores.slice(), {}, comptime std.sort.asc(Answer));

    return all_scores.constSlice()[all_scores.len / 2];
}

const max_line_len = 100;

const Char = enum {
    @"(",
    @"[",
    @"{",
    @"<",
    @")",
    @"]",
    @"}",
    @">",
};

const LineValidationResult = union (enum) {
    ok,
    invalid_char: Char,
    remaining_closing_chars: std.BoundedArray(Char, max_line_len),
};

fn validateLine(line: []const u8) !LineValidationResult {
    var remaining_closing_chars = std.BoundedArray(Char, max_line_len).init(0) catch unreachable;

    for (line) |c| {
        const char = std.meta.stringToEnum(Char, &[_]u8 { c }) orelse return error.InvalidInput;
        switch (char) {
            .@"(" => {
                try remaining_closing_chars.append(.@")");
            },
            .@"[" => {
                try remaining_closing_chars.append(.@"]");
            },
            .@"{" => {
                try remaining_closing_chars.append(.@"}");
            },
            .@"<" => {
                try remaining_closing_chars.append(.@">");
            },
            else => {
                if (remaining_closing_chars.popOrNull()) |remaining_closing_chars_closing_char| {
                    if (remaining_closing_chars_closing_char == char) {
                        continue;
                    }

                    try remaining_closing_chars.append(remaining_closing_chars_closing_char);
                }

                return LineValidationResult {
                    .invalid_char = char,
                };
            },
        }
    }

    return
        if (remaining_closing_chars.len > 0) LineValidationResult { .remaining_closing_chars = remaining_closing_chars }
        else LineValidationResult { .ok = {} };
}

test "day 10 example 1" {
    const input_ =
        \\[({(<(())[]>[[{[]{<()<>>
        \\[(()[<>])]({[<{<<[]>>(
        \\{([(<{}[<>[]}>{[]{[(<()>
        \\(((({<>}<{<{<>}{[]{[]{}
        \\[[<[([]))<([[{}[[()]]]
        \\[{[{({}]{}}([{[{{{}}([]
        \\{<[[]]>}<{[{[{[]{()[[[]
        \\[<(<(<(<{}))><([]([]()
        \\<{([([[(<>()){}]>(<<{{
        \\<{([{{}}[<[[[<>{}]]]>[]]
        ;

    try std.testing.expectEqual(@as(Answer, 2 * 3 + 1 * 57 + 1 * 1197 + 1 * 25137), try part1(&input.readString(input_)));
    try std.testing.expectEqual(@as(Answer, 288957), try part2(&input.readString(input_)));
}
