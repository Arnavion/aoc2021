const std = @import("std");

const input = @import("input.zig");

pub fn run(allocator: std.mem.Allocator, stdout: anytype) anyerror!void {
    var input_ = try input.readFile("inputs/day12");
    defer input_.deinit();

    const input_parsed = try Input.init(allocator, &input_);

    {
        const result = try part1(allocator, &input_parsed);
        try stdout.print("12a: {}\n", .{ result });
        std.debug.assert(result == 4691);
    }

    {
        const result = try part2(allocator, &input_parsed);
        try stdout.print("12b: {}\n", .{ result });
        std.debug.assert(result == 140718);
    }
}

const Input = struct {
    const max_num_nodes = 16;
    const NodeId = usize;
    const NeighborsSet = std.StaticBitSet(max_num_nodes);
    const NodeKind = enum {
        start,
        small,
        big,
        end,
    };
    const NodeInfo = struct {
        kind: NodeKind,
        neighbors: NeighborsSet,
    };
    const Node = struct {
        id: NodeId,
        info: NodeInfo,
    };

    nodes: [max_num_nodes]NodeInfo,

    fn init(allocator: std.mem.Allocator, input_: anytype) !@This() {
        var node_names = try std.BoundedArray([]const u8, max_num_nodes).init(0);
        defer for (node_names.slice()) |node_name| {
            allocator.free(node_name);
        };

        var nodes: [max_num_nodes]NodeInfo = [_]NodeInfo { .{ .kind = .end, .neighbors = NeighborsSet.initEmpty() } } ** max_num_nodes;

        while (try input_.next()) |line| {
            var parts = std.mem.split(u8, line, "-");

            const start = parts.next() orelse return error.InvalidInput;
            const start_node_id = try addNode(allocator, &node_names, &nodes, start);

            const end = parts.next() orelse return error.InvalidInput;
            const end_node_id = try addNode(allocator, &node_names, &nodes, end);

            if (nodes[end_node_id].kind != .start) {
                nodes[start_node_id].neighbors.set(end_node_id);
            }
            if (nodes[start_node_id].kind != .start) {
                nodes[end_node_id].neighbors.set(start_node_id);
            }
        }

        return Input {
            .nodes = nodes,
        };
    }

    fn getStartNode(self: *const @This()) !Node {
        for (self.nodes) |info, id| {
            if (info.kind == .start) {
                return Node {
                    .id = id,
                    .info = info,
                };
            }
        }

        return error.NoStartNodeDefined;
    }

    fn getNodeInfo(self: *const @This(), id: NodeId) NodeInfo {
        return self.nodes[id];
    }

    fn addNode(
        allocator: std.mem.Allocator,
        node_names: *std.BoundedArray([]const u8, max_num_nodes),
        nodes: *[max_num_nodes]NodeInfo,
        name: []const u8,
    ) !NodeId {
        for (node_names.constSlice()) |node_name, node_id| {
            if (std.mem.eql(u8, node_name, name)) {
                return node_id;
            }
        }

        const node_id = node_names.len;

        const name_copy = try allocator.alloc(u8, name.len);
        errdefer allocator.free(name_copy);
        std.mem.copy(u8, name_copy, name);
        try node_names.append(name_copy);

        const node_kind =
            if (std.mem.eql(u8, name, "start")) NodeKind.start
            else if (std.mem.eql(u8, name, "end")) NodeKind.end
            else if (name[0] >= 'a' and name[0] <= 'z') NodeKind.small
            else if (name[0] >= 'A' and name[0] <= 'Z') NodeKind.big
            else return error.InvalidInput;
        nodes[node_id].kind = node_kind;
        return node_id;
    }
};

fn part1(allocator: std.mem.Allocator, input_: *const Input) !usize {
    return solve(allocator, input_, false);
}

fn part2(allocator: std.mem.Allocator, input_: *const Input) !usize {
    return solve(allocator, input_, true);
}

const Path = struct {
    const VisitedSet = std.StaticBitSet(Input.max_num_nodes);

    visited_nodes: VisitedSet,
    visit_next: Input.NeighborsSet,
    have_visited_small_twice: bool,

    fn init(start_node: Input.Node) @This() {
        std.debug.assert(start_node.info.kind == .start);

        var visited_nodes = VisitedSet.initEmpty();
        visited_nodes.set(start_node.id);

        return Path {
            .visited_nodes = visited_nodes,
            .visit_next = start_node.info.neighbors,
            .have_visited_small_twice = false,
        };
    }

    fn visit(self: *const @This(), node: Input.Node) @This() {
        var visited_nodes = self.visited_nodes;
        if (node.info.kind != .big) {
            visited_nodes.set(node.id);
        }
        return Path {
            .visited_nodes = visited_nodes,
            .visit_next = node.info.neighbors,
            .have_visited_small_twice = self.have_visited_small_twice,
        };
    }

    fn have_visited(self: *const @This(), node_id: Input.NodeId) bool {
        return self.visited_nodes.isSet(node_id);
    }
};

fn solve(allocator: std.mem.Allocator, input_: *const Input, allow_visiting_small_twice: bool) !usize {
    var result: usize = 0;

    var paths = std.ArrayList(Path).init(allocator);
    defer paths.deinit();

    {
        const start_node = try input_.getStartNode();
        const path = Path.init(start_node);
        try paths.append(path);
    }

    while (paths.popOrNull()) |path| {
        var neighbors = path.visit_next.iterator(.{});
        while (neighbors.next()) |neighbor_id| {
            const neighbor_info = input_.getNodeInfo(neighbor_id);

            if (neighbor_info.kind == .end) {
                result += 1;
            }
            else if (!path.have_visited(neighbor_id)) {
                const path_copy = path.visit(.{ .id = neighbor_id, .info = neighbor_info });
                try paths.append(path_copy);
            }
            else if (allow_visiting_small_twice and !path.have_visited_small_twice) {
                var path_copy = path.visit(.{ .id = neighbor_id, .info = neighbor_info });
                path_copy.have_visited_small_twice = true;
                try paths.append(path_copy);
            }
        }
    }

    return result;
}

test "day 12 example 1" {
    const input_ =
        \\start-A
        \\start-b
        \\A-c
        \\A-b
        \\b-d
        \\A-end
        \\b-end
        ;

    var input__ = input.readString(input_);
    const input_parsed = try Input.init(std.testing.allocator, &input__);

    try std.testing.expectEqual(@as(usize, 10), try part1(std.testing.allocator, &input_parsed));
    try std.testing.expectEqual(@as(usize, 36), try part2(std.testing.allocator, &input_parsed));
}

test "day 12 example 2" {
    const input_ =
        \\dc-end
        \\HN-start
        \\start-kj
        \\dc-start
        \\dc-HN
        \\LN-dc
        \\HN-end
        \\kj-sa
        \\kj-HN
        \\kj-dc
        ;

    var input__ = input.readString(input_);
    const input_parsed = try Input.init(std.testing.allocator, &input__);

    try std.testing.expectEqual(@as(usize, 19), try part1(std.testing.allocator, &input_parsed));
    try std.testing.expectEqual(@as(usize, 103), try part2(std.testing.allocator, &input_parsed));
}

test "day 12 example 3" {
    const input_ =
        \\fs-end
        \\he-DX
        \\fs-he
        \\start-DX
        \\pj-DX
        \\end-zg
        \\zg-sl
        \\zg-pj
        \\pj-he
        \\RW-he
        \\fs-DX
        \\pj-RW
        \\zg-RW
        \\start-pj
        \\he-WI
        \\zg-he
        \\pj-fs
        \\start-RW
        ;

    var input__ = input.readString(input_);
    const input_parsed = try Input.init(std.testing.allocator, &input__);

    try std.testing.expectEqual(@as(usize, 226), try part1(std.testing.allocator, &input_parsed));
    try std.testing.expectEqual(@as(usize, 3509), try part2(std.testing.allocator, &input_parsed));
}
