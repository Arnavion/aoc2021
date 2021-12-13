const std = @import("std");

const input = @import("input.zig");

pub fn run(stdout: anytype) anyerror!void {
    {
        var input_ = try input.readFile("inputs/day13");
        defer input_.deinit();

        var paper = Paper.init(0) catch unreachable;

        const result = try part1(&input_, &paper);
        try stdout.print("13a: {}\n", .{ result });
        std.debug.assert(result == 781);
    }

    {
        var input_ = try input.readFile("inputs/day13");
        defer input_.deinit();

        var paper = Paper.init(0) catch unreachable;

        try part2(&input_, &paper);
        try stdout.print("13b: ", .{});
        try printPaper(paper.constSlice(), stdout);
        try assertEqual(
            \\###..####.###...##...##....##.###..###.
            \\#..#.#....#..#.#..#.#..#....#.#..#.#..#
            \\#..#.###..#..#.#....#.......#.#..#.###.
            \\###..#....###..#....#.##....#.###..#..#
            \\#....#....#.#..#..#.#..#.#..#.#....#..#
            \\#....####.#..#..##...###..##..#....###.
            ,
            paper.slice(),
        );
    }
}

const max_num_points = 1000;
const Paper = std.BoundedArray(Point, max_num_points);
const Point = struct {
    y: usize,
    x: usize,
};

fn part1(input_: anytype, paper: *Paper) !usize {
    try parsePaper(input_, paper);

    const folded_once = try step(input_, paper);
    if (!folded_once) {
        return error.InvalidInput;
    }

    return paper.len;
}

fn part2(input_: anytype, paper: *Paper) !void {
    try parsePaper(input_, paper);

    while (try step(input_, paper)) {}

    std.sort.sort(Point, paper.slice(), {}, sortPoint);
}

fn printPaper(paper: []const Point, stdout: anytype) !void {
    var y_max: usize = 0;
    var x_max: usize = 0;
    for (paper) |point| {
        y_max = std.math.max(y_max, point.y);
        x_max = std.math.max(x_max, point.x);
    }

    {
        try stdout.print("\u{2554}\u{2550}", .{});
        var x_i: usize = 0;
        while (x_i <= x_max) : (x_i += 1) {
            try stdout.print("\u{2550}\u{2550}", .{});
        }
        try stdout.print("\u{2550}\u{2557}\n", .{});
    }

    {
        var next_point_i: usize = 0;

        var y_i: usize = 0;
        while (y_i <= y_max) : (y_i += 1) {
            try stdout.print("     \u{2551} ", .{});
            var x_i: usize = 0;
            while (x_i <= x_max) : (x_i += 1) {
                if (next_point_i < paper.len) {
                    const point = paper[next_point_i];
                    if (point.y == y_i and point.x == x_i) {
                        try stdout.print("##", .{});
                        next_point_i += 1;
                    }
                    else {
                        try stdout.print("  ", .{});
                    }
                }
                else {
                    try stdout.print("  ", .{});
                }
            }
            try stdout.print(" \u{2551}\n", .{});
        }
    }

    {
        try stdout.print("     \u{255a}\u{2550}", .{});
        var x_i: usize = 0;
        while (x_i <= x_max) : (x_i += 1) {
            try stdout.print("\u{2550}\u{2550}", .{});
        }
        try stdout.print("\u{2550}\u{255d}\n", .{});
    }
}

fn assertEqual(
    expected_paper_s: []const u8,
    actual_paper: []const Point,
) !void {
    var expected_paper = Paper.init(0) catch unreachable;
    {
        var y_i: usize = 0;
        var lines = std.mem.split(u8, expected_paper_s, "\n");
        while (lines.next()) |line| : (y_i += 1) {
            for (line) |c, x_i| {
                if (c == '#') {
                    try append(&expected_paper, .{ .y = y_i, .x = x_i });
                }
            }
        }
    }

    std.debug.assert(expected_paper.len == actual_paper.len);
    for (expected_paper.constSlice()) |expected_point, point_i| {
        const actual_point = actual_paper[point_i];
        std.debug.assert(expected_point.y == actual_point.y and expected_point.x == actual_point.x);
    }
}

fn sortPoint(context: void, a: Point, b: Point) bool {
    _ = context;
    return switch (std.math.order(a.y, b.y)) {
        .lt => true,
        .eq => a.x < b.x,
        .gt => false,
    };
}

fn parsePaper(input_: anytype, paper: *Paper) !void {
    while (try input_.next()) |line| {
        if (line.len == 0) {
            break;
        }

        var line_parts = std.mem.split(u8, line, ",");

        const x_s = line_parts.next() orelse return error.InvalidInput;
        const x = try std.fmt.parseInt(usize, x_s, 10);

        const y_s = line_parts.next() orelse return error.InvalidInput;
        const y = try std.fmt.parseInt(usize, y_s, 10);

        try append(paper, .{ .y = y, .x = x });
    }
}

fn append(paper: *Paper, new_point: Point) !void {
    for (paper.constSlice()) |point| {
        if (point.y == new_point.y and point.x == new_point.x) {
            return;
        }
    }

    try paper.append(new_point);
}

fn step(input_: anytype, paper: *Paper) !bool {
    const FoldAxis = enum {
        y,
        x,
    };

    const line = (try input_.next()) orelse return false;

    if (!std.mem.startsWith(u8, line, "fold along ")) {
        return error.InvalidInput;
    }
    var fold_line_parts = std.mem.split(u8, line[("fold along ".len)..], "=");

    const axis_s = fold_line_parts.next() orelse return error.InvalidInput;
    const axis = std.meta.stringToEnum(FoldAxis, axis_s) orelse return error.InvalidInput;

    const distance_s = fold_line_parts.next() orelse return error.InvalidInput;
    const distance = try std.fmt.parseInt(usize, distance_s, 10);

    var point_i: usize = 0;
    while (point_i < paper.len) {
        var point = paper.constSlice()[point_i];

        const new_point = switch (axis) {
            .y => if (point.y > distance) Point { .y = point.y - (point.y - distance) * 2, .x = point.x } else null,
            .x => if (point.x > distance) Point { .y = point.y, .x = point.x - (point.x - distance) * 2 } else null,
        };
        if (new_point) |new_point_| {
            _ = paper.swapRemove(point_i);
            try append(paper, new_point_);
        }
        else {
            point_i += 1;
        }
    }

    return true;
}

test "day 13 example 1" {
    const input_ =
        \\6,10
        \\0,14
        \\9,10
        \\0,3
        \\10,4
        \\4,11
        \\6,0
        \\6,12
        \\4,1
        \\0,13
        \\10,12
        \\3,4
        \\3,0
        \\8,4
        \\1,10
        \\2,14
        \\8,10
        \\9,0
        \\
        \\fold along y=7
        \\fold along x=5
        ;

    {
        var paper = Paper.init(0) catch unreachable;

        try std.testing.expectEqual(@as(usize, 17), try part1(&input.readString(input_), &paper));
    }

    {
        var paper = Paper.init(0) catch unreachable;

        try part2(&input.readString(input_), &paper);

        try assertEqual(
            \\#####
            \\#...#
            \\#...#
            \\#...#
            \\#####
            \\.....
            \\.....
            ,
            paper.slice(),
        );
    }
}
