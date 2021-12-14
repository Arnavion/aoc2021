const std = @import("std");

const input = @import("input.zig");

pub fn run(stdout: anytype) anyerror!void {
    {
        var input_ = try input.readFile("inputs/day14");
        defer input_.deinit();

        const result = try part1(&input_);
        try stdout.print("14a: {}\n", .{ result });
        std.debug.assert(result == 4517);
    }

    {
        var input_ = try input.readFile("inputs/day14");
        defer input_.deinit();

        const result = try part2(&input_);
        try stdout.print("14b: {}\n", .{ result });
        std.debug.assert(result == 4704817645083);
    }
}

fn part1(input_: anytype) !usize {
    return solve(input_, 10);
}

fn part2(input_: anytype) !usize {
    return solve(input_, 40);
}

const max_element = 'Z' - 'A';
const Element = std.math.IntFittingRange(0, max_element);

fn parseElement(c: u8) !Element {
    if (c < 'A' or c > 'Z') {
        return error.InvalidInput;
    }
    return @intCast(Element, c - 'A');
}

fn solve(input_: anytype, num_steps: usize) !usize {
    var pairs: [max_element + 1][max_element + 1]usize = [_][max_element + 1]usize { [_]usize { 0 } ** (max_element + 1) } ** (max_element + 1);
    const template_last_element = template_last_element: {
        const template = (try input_.next()) orelse return error.InvalidInput;
        var template_i: usize = 1;
        while (template_i < template.len) : (template_i += 1) {
            const left = try parseElement(template[template_i - 1]);
            const right = try parseElement(template[template_i]);
            pairs[left][right] += 1;
        }
        break :template_last_element try parseElement(template[template_i - 1]);
    };

    _ = (try input_.next()) orelse return error.InvalidInput;

    var rules: [max_element + 1][max_element + 1]?Element = [_][max_element + 1]?Element { [_]?Element { null } ** (max_element + 1) } ** (max_element + 1);
    while (try input_.next()) |line| {
        if (line.len != 2 + 4 + 1 or !std.mem.eql(u8, line[2..6], " -> ")) {
            return error.InvalidInput;
        }

        const left = try parseElement(line[0]);
        const right = try parseElement(line[1]);
        const middle = try parseElement(line[6]);
        rules[left][right] = middle;
    }

    {
        var new_pairs = pairs;

        var step_i: usize = 1;
        while (step_i <= num_steps) : (step_i += 1) {
            for (new_pairs) |*row, left_i| {
                for (row) |*new_count, right_i| {
                    if (rules[left_i][right_i]) |middle| {
                        const count = pairs[left_i][right_i];
                        new_count.* -= count;
                        new_pairs[left_i][middle] += count;
                        new_pairs[middle][right_i] += count;
                    }
                }
            }

            pairs = new_pairs;
        }
    }

    var counts = [_]usize { 0 } ** (max_element + 1);
    for (pairs) |row, left_i| {
        for (row) |count| {
            counts[left_i] += count;
        }
    }
    counts[template_last_element] += 1;

    var max_count: usize = 0;
    var min_count: usize = std.math.maxInt(usize);
    for (counts) |count| {
        max_count = std.math.max(max_count, count);
        if (count > 0) {
            min_count = std.math.min(min_count, count);
        }
    }
    return max_count - min_count;
}

test "day 14 example 1" {
    const input_ =
        \\NNCB
        \\
        \\CH -> B
        \\HH -> N
        \\CB -> H
        \\NH -> C
        \\HB -> C
        \\HC -> B
        \\HN -> C
        \\NN -> C
        \\BH -> H
        \\NC -> B
        \\NB -> B
        \\BN -> B
        \\BB -> N
        \\BC -> B
        \\CC -> N
        \\CN -> C
        ;

    try std.testing.expectEqual(@as(usize, 1749 - 161), try part1(&input.readString(input_)));
    try std.testing.expectEqual(@as(usize, 2192039569602 - 3849876073), try part2(&input.readString(input_)));
}
