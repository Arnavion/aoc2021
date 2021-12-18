const std = @import("std");

const input = @import("input.zig");

pub fn run(stdout: anytype) anyerror!void {
    {
        var input_ = try input.readFile("inputs/day18");
        defer input_.deinit();

        const result = try part1(&input_);
        try stdout.print("18a: {}\n", .{ result });
        std.debug.assert(result == 4365);
    }

    {
        var input_ = try input.readFile("inputs/day18");
        defer input_.deinit();

        const result = try part2(&input_);
        try stdout.print("18b: {}\n", .{ result });
        std.debug.assert(result == 4490);
    }
}

fn part1(input_: anytype) !u16 {
    const result = try addAll(input_);
    return try getMagnitude(result);
}

fn part2(input_: anytype) !u16 {
    var numbers = std.BoundedArray(Tree, 100).init(0) catch unreachable;

    while (try input_.next()) |*line| {
        var tree: Tree = undefined;
        try parseTreeNode(line, &tree, root);
        try numbers.append(tree);
    }

    var max_magnitude: u16 = 0;

    for (numbers.constSlice()) |first, first_i| {
        for (numbers.constSlice()) |second, second_i| {
            if (first_i == second_i) {
                continue;
            }

            const sum = try add(first, second);
            max_magnitude = std.math.max(max_magnitude, try getMagnitude(sum));
        }
    }

    return max_magnitude;
}

const max_num_tree_nodes = 64;

const Tree = [max_num_tree_nodes]TreeNode;

const max_work = 6 + 1;

const TreeNode = union(enum) {
    num: u8,
    pair,
};

fn addAll(input_: anytype) !Tree {
    var result: ?Tree = null;

    while (try input_.next()) |*line| {
        var tree: Tree = undefined;
        try parseTreeNode(line, &tree, root);

        if (result) |result_| {
            result = try add(result_, tree);
        }
        else {
            result = tree;
        }
    }

    return result orelse error.InvalidInput;
}

const root: usize = 1;

const ChildDirection = enum {
    left,
    right,
};

fn child(i: usize, direction: ChildDirection) usize {
    return switch (direction) {
        .left => i << 1,
        .right => (i << 1) | 1,
    };
}

fn parent(i: usize) ?usize {
    const result = i >> 1;
    return if (result == 0) null else result;
}

fn parseTreeNode(s: *[]const u8, tree: *Tree, i: usize) (std.fmt.ParseIntError || error{InvalidInput})!void {
    if ((s.*)[0] == '[') {
        s.* = (s.*)[1..];
        tree[i] = .pair;

        try parseTreeNode(s, tree, child(i, .left));

        if ((s.*)[0] != ',') {
            return error.InvalidInput;
        }
        s.* = (s.*)[1..];

        try parseTreeNode(s, tree, child(i, .right));

        if ((s.*)[0] != ']') {
            return error.InvalidInput;
        }
        s.* = (s.*)[1..];
    }
    else {
        std.debug.assert((s.*)[0] >= '0' and (s.*)[0] <= '9');
        const num = try std.fmt.parseInt(u8, (s.*)[0..1], 10);
        s.* = (s.*)[1..];
        tree[i] = .{ .num = num };
    }
}

fn add(left: Tree, right: Tree) !Tree {
    var sum: Tree = undefined;

    sum[root] = .pair;
    try copyTree(&sum, child(root, .left), left, root);
    try copyTree(&sum, child(root, .right), right, root);

    try reduce(&sum);

    return sum;
}

fn copyTree(dst: *Tree, dst_i: usize, src: Tree, src_i: usize) !void {
    const Work = struct {
        dst_i: usize,
        src_i: usize,
    };
    var work = std.BoundedArray(Work, max_work).init(0) catch unreachable;

    try work.append(.{ .dst_i = dst_i, .src_i = src_i });

    while (work.popOrNull()) |work_| {
        dst[work_.dst_i] = src[work_.src_i];
        switch (src[work_.src_i]) {
            .num => {},
            .pair => {
                try work.append(.{ .dst_i = child(work_.dst_i, .right), .src_i = child(work_.src_i, .right) });
                try work.append(.{ .dst_i = child(work_.dst_i, .left), .src_i = child(work_.src_i, .left) });
            },
        }
    }
}

fn reduce(tree: *Tree) !void {
    while (
        (try walkForExploding(tree)) or
        (try walkForSplitting(tree))
    ) {}
}

fn walkForExploding(tree: *Tree) !bool {
    var work = std.BoundedArray(usize, max_work).init(0) catch unreachable;
    try work.append(root);

    while (work.popOrNull()) |i| {
        switch (tree[i]) {
            .num => {},

            .pair => {
                if (i >= 1 << 4) {
                    switch (tree[child(i, .left)]) {
                        .num => |left| {
                            switch (tree[child(i, .right)]) {
                                .num => |right| {
                                    const parent_i = parent(i).?;

                                    if (findAdjacentNum(tree, parent_i, .left, i)) |left_num| {
                                        left_num.* += left;
                                    }

                                    if (findAdjacentNum(tree, parent_i, .right, i)) |right_num| {
                                        right_num.* += right;
                                    }

                                    tree[i] = .{ .num = 0 };
                                    return true;
                                },

                                .pair => {},
                            }
                        },

                        .pair => {},
                    }
                }

                try work.append(child(i, .right));
                try work.append(child(i, .left));
            },
        }
    }

    return false;
}

fn walkForSplitting(tree: *Tree) !bool {
    var work = std.BoundedArray(usize, max_work).init(0) catch unreachable;
    try work.append(root);

    while (work.popOrNull()) |i| {
        switch (tree[i]) {
            .num => |num| {
                if (num < 10) {
                    continue;
                }

                const left = num / 2;
                const right = num - left;

                tree[i] = .pair;
                tree[child(i, .left)] = .{ .num = left };
                tree[child(i, .right)] = .{ .num = right };

                return true;
            },

            .pair => {
                try work.append(child(i, .right));
                try work.append(child(i, .left));
            },
        }
    }

    return false;
}

// TODO:
// Can't use @call(.{ .modifier = .always_tail }, findAdjacentNum, .{ ... })
// because of https://github.com/ziglang/zig/issues/5692
fn findAdjacentNum(
    tree: *Tree,
    i: usize,
    direction: ChildDirection,
    except: ?usize,
) ?*u8 {
    switch (tree[i]) {
        .num => |*num| return num,

        .pair => {
            if (except) |except_| {
                switch (direction) {
                    .left => if (child(i, .left) != except_) {
                        return findAdjacentNum(tree, child(i, .left), .right, null);
                    },

                    .right => if (child(i, .right) != except_) {
                        return findAdjacentNum(tree, child(i, .right), .left, null);
                    },
                }

                if (parent(i)) |parent_| {
                    return findAdjacentNum(tree, parent_, direction, i);
                }

                return null;
            }

            return findAdjacentNum(
                tree,
                switch (direction) { .left => child(i, .left), .right => child(i, .right) },
                direction,
                null,
            );
        },
    }
}

fn getMagnitude(tree: Tree) !u16 {
    var result: u16 = 0;

    const Work = struct {
        i: usize,
        multiplier: u16,
    };
    var work = std.BoundedArray(Work, max_work).init(0) catch unreachable;
    try work.append(.{ .i = root, .multiplier = 1 });

    while (work.popOrNull()) |work_| {
        switch (tree[work_.i]) {
            .num => |num| result += num * work_.multiplier,
            .pair => {
                try work.append(.{ .i = child(work_.i, .right), .multiplier = work_.multiplier * 2 });
                try work.append(.{ .i = child(work_.i, .left), .multiplier = work_.multiplier * 3 });
            },
        }
    }

    return result;
}

test "day 18 example 1" {
    const input_ =
        \\[[[[4,3],4],4],[7,[[8,4],9]]]
        \\[1,1]
        ;

    try expectEqualTree("[[[[0,7],4],[[7,8],[6,0]]],[8,1]]", try addAll(&input.readString(input_)));
}

test "day 18 example 2" {
    const input_ =
        \\[1,1]
        \\[2,2]
        \\[3,3]
        \\[4,4]
        ;

    try expectEqualTree("[[[[1,1],[2,2]],[3,3]],[4,4]]", try addAll(&input.readString(input_)));
}

test "day 18 example 3" {
    const input_ =
        \\[1,1]
        \\[2,2]
        \\[3,3]
        \\[4,4]
        \\[5,5]
        ;

    try expectEqualTree("[[[[3,0],[5,3]],[4,4]],[5,5]]", try addAll(&input.readString(input_)));
}

test "day 18 example 4" {
    const input_ =
        \\[1,1]
        \\[2,2]
        \\[3,3]
        \\[4,4]
        \\[5,5]
        \\[6,6]
        ;

    try expectEqualTree("[[[[5,0],[7,4]],[5,5]],[6,6]]", try addAll(&input.readString(input_)));
}

test "day 18 example 5" {
    const input_ =
        \\[[[0,[4,5]],[0,0]],[[[4,5],[2,6]],[9,5]]]
        \\[7,[[[3,7],[4,3]],[[6,3],[8,8]]]]
        \\[[2,[[0,8],[3,4]]],[[[6,7],1],[7,[1,6]]]]
        \\[[[[2,4],7],[6,[0,5]]],[[[6,8],[2,8]],[[2,1],[4,5]]]]
        \\[7,[5,[[3,8],[1,4]]]]
        \\[[2,[2,2]],[8,[8,1]]]
        \\[2,9]
        \\[1,[[[9,3],9],[[9,0],[0,7]]]]
        \\[[[5,[7,4]],7],1]
        \\[[[[4,2],2],6],[8,7]]
        ;

    try expectEqualTree("[[[[8,7],[7,7]],[[8,6],[7,7]]],[[[0,7],[6,6]],[8,7]]]", try addAll(&input.readString(input_)));
}

test "day 18 example 6" {
    const input_ = "[9,1]";

    try std.testing.expectEqual(@as(u16, 29), try part1(&input.readString(input_)));
}

test "day 18 example 7" {
    const input_ = "[1,9]";

    try std.testing.expectEqual(@as(u16, 21), try part1(&input.readString(input_)));
}

test "day 18 example 8" {
    const input_ = "[[9,1],[1,9]]";

    try std.testing.expectEqual(@as(u16, 129), try part1(&input.readString(input_)));
}

test "day 18 example 9" {
    const input_ = "[[1,2],[[3,4],5]]";

    try std.testing.expectEqual(@as(u16, 143), try part1(&input.readString(input_)));
}

test "day 18 example 10" {
    const input_ = "[[[[0,7],4],[[7,8],[6,0]]],[8,1]]";

    try std.testing.expectEqual(@as(u16, 1384), try part1(&input.readString(input_)));
}

test "day 18 example 11" {
    const input_ = "[[[[1,1],[2,2]],[3,3]],[4,4]]";

    try std.testing.expectEqual(@as(u16, 445), try part1(&input.readString(input_)));
}

test "day 18 example 12" {
    const input_ = "[[[[3,0],[5,3]],[4,4]],[5,5]]";

    try std.testing.expectEqual(@as(u16, 791), try part1(&input.readString(input_)));
}

test "day 18 example 13" {
    const input_ = "[[[[5,0],[7,4]],[5,5]],[6,6]]";

    try std.testing.expectEqual(@as(u16, 1137), try part1(&input.readString(input_)));
}

test "day 18 example 14" {
    const input_ = "[[[[8,7],[7,7]],[[8,6],[7,7]]],[[[0,7],[6,6]],[8,7]]]";

    try std.testing.expectEqual(@as(u16, 3488), try part1(&input.readString(input_)));
}

test "day 18 example 15" {
    const input_ =
        \\[[[0,[5,8]],[[1,7],[9,6]]],[[4,[1,2]],[[1,4],2]]]
        \\[[[5,[2,8]],4],[5,[[9,9],0]]]
        \\[6,[[[6,2],[5,6]],[[7,6],[4,7]]]]
        \\[[[6,[0,7]],[0,9]],[4,[9,[9,0]]]]
        \\[[[7,[6,4]],[3,[1,3]]],[[[5,5],1],9]]
        \\[[6,[[7,3],[3,2]]],[[[3,8],[5,7]],4]]
        \\[[[[5,4],[7,7]],8],[[8,3],8]]
        \\[[9,3],[[9,9],[6,[4,9]]]]
        \\[[2,[[7,7],7]],[[5,8],[[9,3],[0,2]]]]
        \\[[[[5,2],5],[8,[3,7]]],[[5,[7,5]],[4,4]]]
        ;

    try expectEqualTree("[[[[6,6],[7,6]],[[7,7],[7,0]]],[[[7,7],[7,7]],[[7,8],[9,9]]]]", try addAll(&input.readString(input_)));

    try std.testing.expectEqual(@as(u16, 4140), try part1(&input.readString(input_)));
    try std.testing.expectEqual(@as(u16, 3993), try part2(&input.readString(input_)));
}

fn expectEqualTree(expected: []const u8, actual: Tree) !void {
    var allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = allocator.deinit();
        if (leaked) {
            @panic("memory leaked");
        }
    }

    var string = std.ArrayList(u8).init(&allocator.allocator);
    defer string.deinit();

    var string_writer = string.writer();
    try printTree(actual, root, string_writer);

    try std.testing.expectEqualStrings(expected, string.items);
}

fn printTree(tree: Tree, i: usize, writer: anytype) (@TypeOf(writer).Error)!void {
    switch (tree[i]) {
        .num => |num| try writer.print("{}", .{ num }),
        .pair => {
            try writer.print("[", .{});
            try printTree(tree, child(i, .left), writer);
            try writer.print(",", .{});
            try printTree(tree, child(i, .right), writer);
            try writer.print("]", .{});
        },
    }
}
