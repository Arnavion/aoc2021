const std = @import("std");

const input = @import("input.zig");

pub fn run(allocator: std.mem.Allocator, stdout: anytype) anyerror!void {
    {
        var input_ = try input.readFile("inputs/day16");
        defer input_.deinit();

        const result = try part1(allocator, &input_);
        try stdout.print("16a: {}\n", .{ result });
        std.debug.assert(result == 852);
    }

    {
        var input_ = try input.readFile("inputs/day16");
        defer input_.deinit();

        const result = try part2(allocator, &input_);
        try stdout.print("16b: {}\n", .{ result });
        std.debug.assert(result == 19348959966392);
    }
}

fn part1(allocator: std.mem.Allocator, input_: anytype) !u64 {
    var bits = try BitsIterator.init(input_);

    var packet = try Packet.init(allocator, &bits);
    defer packet.deinit();

    var sum: u64 = 0;
    walkPacket(&packet, &sum);

    return sum;
}

fn part2(allocator: std.mem.Allocator, input_: anytype) !u64 {
    var bits = try BitsIterator.init(input_);

    var packet = try Packet.init(allocator, &bits);
    defer packet.deinit();

    return evalPacket(&packet);
}

const BitsIterator = struct {
    line: []const u8,
    pos: usize,

    fn init(input_: anytype) !@This() {
        const line = (try input_.next()) orelse return error.InvalidInput;
        return BitsIterator { .line = line, .pos = 0 };
    }

    fn next(self: *@This()) !u1 {
        const c = self.line[self.pos / 4];
        const b = try std.fmt.parseInt(u4, &[_]u8 { c }, 16);
        const result = if (b & (@as(u4, 0b1000) >> @intCast(u2, self.pos % 4)) == 0) @as(u1, 0) else @as(u1, 1);
        self.pos += 1;
        return result;
    }
};

const Packet = struct {
    version: u3,
    body: PacketBody,

    fn init(allocator: std.mem.Allocator, bits: *BitsIterator) error{InvalidCharacter, InvalidInput, OutOfMemory, Overflow}!@This() {
        const version = try getNum(3, bits);

        const type_id = try getNum(3, bits);

        const body = body: {
            switch (type_id) {
                4 => {
                    var literal: u64 = 0;
                    while (true) {
                        const block = try getNum(5, bits);
                        literal = (literal << 4) | (block & 0b01111);
                        if (block & 0b10000 == 0) {
                            break;
                        }
                    }
                    break :body PacketBody {
                        .literal = literal,
                    };
                },

                else => {
                    var body = PacketBody {
                        .operator = Operator {
                            .type_id = type_id,
                            .sub_packets = std.ArrayList(Packet).init(allocator),
                        },
                    };
                    errdefer body.deinit();

                    const length_type_id = try bits.next();
                    switch (length_type_id) {
                        0 => {
                            const length = try getNum(15, bits);
                            const end = bits.pos + length;
                            while (bits.pos < end) {
                                const sub_packet = try Packet.init(allocator, bits);
                                try body.operator.sub_packets.append(sub_packet);
                            }
                            bits.pos = end;
                        },

                        1 => {
                            const num_sub_packets = try getNum(11, bits);
                            var sub_packet_i: usize = 0;
                            while (sub_packet_i < num_sub_packets) : (sub_packet_i += 1) {
                                const sub_packet = try Packet.init(allocator, bits);
                                try body.operator.sub_packets.append(sub_packet);
                            }
                        },
                    }

                    break :body body;
                },
            }
        };

        return Packet {
            .version = version,
            .body = body,
        };
    }

    fn deinit(self: *@This()) void {
        self.body.deinit();
    }
};

const PacketBody = union(enum) {
    literal: Literal,
    operator: Operator,

    fn deinit(self: *@This()) void {
        switch (self.*) {
            .literal => {},
            .operator => |*operator| operator.deinit(),
        }
    }
};

const Literal = u64;

const Operator = struct {
    type_id: u3,
    sub_packets: std.ArrayList(Packet),

    fn deinit(self: *@This()) void {
        for (self.sub_packets.items) |*sub_packet| {
            sub_packet.deinit();
        }
        self.sub_packets.deinit();
    }
};

fn getNum(comptime bit_length: usize, bits: *BitsIterator) !std.meta.Int(.unsigned, bit_length) {
    var result: std.meta.Int(.unsigned, bit_length) = 0;
    var i: usize = 0;
    while (i < bit_length) : (i += 1) {
        result = (result << 1) | (try bits.next());
    }
    return result;
}

fn walkPacket(packet: *const Packet, sum: *u64) void {
    sum.* += packet.version;
    switch (packet.body) {
        .literal => {},
        .operator => |operator| {
            for (operator.sub_packets.items) |*sub_packet| {
                walkPacket(sub_packet, sum);
            }
        }
    }
}

fn evalPacket(packet: *const Packet) error{InvalidInput}!u64 {
    switch (packet.body) {
        .literal => |literal| return literal,
        .operator => |operator| {
            switch (operator.type_id) {
                0 => {
                    var result: u64 = 0;
                    for (operator.sub_packets.items) |*sub_packet| {
                        result += try evalPacket(sub_packet);
                    }
                    return result;
                },

                1 => {
                    var result: u64 = 1;
                    for (operator.sub_packets.items) |*sub_packet| {
                        result *= try evalPacket(sub_packet);
                    }
                    return result;
                },

                2 => {
                    var result: u64 = std.math.maxInt(u64);
                    for (operator.sub_packets.items) |*sub_packet| {
                        result = std.math.min(result, try evalPacket(sub_packet));
                    }
                    return result;
                },

                3 => {
                    var result: u64 = std.math.minInt(u64);
                    for (operator.sub_packets.items) |*sub_packet| {
                        result = std.math.max(result, try evalPacket(sub_packet));
                    }
                    return result;
                },

                5 => {
                    if (operator.sub_packets.items.len != 2) {
                        return error.InvalidInput;
                    }

                    const left_packet = &operator.sub_packets.items[0];
                    const right_packet = &operator.sub_packets.items[1];
                    if ((try evalPacket(left_packet)) > (try evalPacket(right_packet))) {
                        return 1;
                    }

                    return 0;
                },

                6 => {
                    if (operator.sub_packets.items.len != 2) {
                        return error.InvalidInput;
                    }

                    const left_packet = &operator.sub_packets.items[0];
                    const right_packet = &operator.sub_packets.items[1];
                    if ((try evalPacket(left_packet)) < (try evalPacket(right_packet))) {
                        return 1;
                    }

                    return 0;
                },

                7 => {
                    if (operator.sub_packets.items.len != 2) {
                        return error.InvalidInput;
                    }

                    const left_packet = &operator.sub_packets.items[0];
                    const right_packet = &operator.sub_packets.items[1];
                    if ((try evalPacket(left_packet)) == (try evalPacket(right_packet))) {
                        return 1;
                    }

                    return 0;
                },

                else => return error.InvalidInput,
            }
        }
    }
}

test "day 16 example 1" {
    const input_ =
        \\D2FE28
        ;

    var input__ = input.readString(input_);
    var bits = try BitsIterator.init(&input__);

    var packet = try Packet.init(std.testing.allocator, &bits);
    defer packet.deinit();

    try std.testing.expectEqual(@as(u3, 6), packet.version);
    switch (packet.body) {
        .literal => |literal| try std.testing.expectEqual(@as(u64, 2021), literal),
        else => try std.testing.expect(false),
    }
}

test "day 16 example 2" {
    const input_ =
        \\38006F45291200
        ;

    var input__ = input.readString(input_);
    var bits = try BitsIterator.init(&input__);

    var packet = try Packet.init(std.testing.allocator, &bits);
    defer packet.deinit();

    try std.testing.expectEqual(@as(u3, 1), packet.version);
    switch (packet.body) {
        .operator => |operator| {
            try std.testing.expectEqual(@as(u3, 6), operator.type_id);
            try std.testing.expectEqual(@as(usize, 2), operator.sub_packets.items.len);

            const sub_packet0 = &operator.sub_packets.items[0];
            switch (sub_packet0.body) {
                .literal => |literal| try std.testing.expectEqual(@as(u64, 10), literal),
                else => try std.testing.expect(false),
            }

            const sub_packet1 = &operator.sub_packets.items[1];
            switch (sub_packet1.body) {
                .literal => |literal| try std.testing.expectEqual(@as(u64, 20), literal),
                else => try std.testing.expect(false),
            }
        },
        else => try std.testing.expect(false),
    }
}

test "day 16 example 3" {
    const input_ =
        \\EE00D40C823060
        ;

    var input__ = input.readString(input_);
    var bits = try BitsIterator.init(&input__);

    var packet = try Packet.init(std.testing.allocator, &bits);
    defer packet.deinit();

    try std.testing.expectEqual(@as(u3, 7), packet.version);
    switch (packet.body) {
        .operator => |operator| {
            try std.testing.expectEqual(@as(u3, 3), operator.type_id);
            try std.testing.expectEqual(@as(usize, 3), operator.sub_packets.items.len);

            const sub_packet0 = &operator.sub_packets.items[0];
            switch (sub_packet0.body) {
                .literal => |literal| try std.testing.expectEqual(@as(u64, 1), literal),
                else => try std.testing.expect(false),
            }

            const sub_packet1 = &operator.sub_packets.items[1];
            switch (sub_packet1.body) {
                .literal => |literal| try std.testing.expectEqual(@as(u64, 2), literal),
                else => try std.testing.expect(false),
            }

            const sub_packet2 = &operator.sub_packets.items[2];
            switch (sub_packet2.body) {
                .literal => |literal| try std.testing.expectEqual(@as(u64, 3), literal),
                else => try std.testing.expect(false),
            }
        },
        else => try std.testing.expect(false),
    }
}

test "day 16 example 4" {
    const input_ =
        \\8A004A801A8002F478
        ;

    {
        var input__ = input.readString(input_);

        var bits = try BitsIterator.init(&input__);

        var packet = try Packet.init(std.testing.allocator, &bits);
        defer packet.deinit();

        try std.testing.expectEqual(@as(u3, 4), packet.version);
        switch (packet.body) {
            .operator => |operator| {
                try std.testing.expectEqual(@as(usize, 1), operator.sub_packets.items.len);

                const sub_packet0 = &operator.sub_packets.items[0];
                try std.testing.expectEqual(@as(u3, 1), sub_packet0.version);
                switch (sub_packet0.body) {
                    .operator => |sub_operator| {
                        try std.testing.expectEqual(@as(usize, 1), sub_operator.sub_packets.items.len);

                        const sub_sub_packet0 = &sub_operator.sub_packets.items[0];
                        try std.testing.expectEqual(@as(u3, 5), sub_sub_packet0.version);
                        switch (sub_sub_packet0.body) {
                            .operator => |sub_sub_operator| {
                                try std.testing.expectEqual(@as(usize, 1), sub_sub_operator.sub_packets.items.len);

                                const sub_sub_sub_packet0 = &sub_sub_operator.sub_packets.items[0];
                                try std.testing.expectEqual(@as(u3, 6), sub_sub_sub_packet0.version);
                                switch (sub_sub_sub_packet0.body) {
                                    .literal => {},
                                    else => try std.testing.expect(false),
                                }
                            },
                            else => try std.testing.expect(false),
                        }
                    },
                    else => try std.testing.expect(false),
                }
            },
            else => try std.testing.expect(false),
        }
    }

    try std.testing.expectEqual(@as(u64, 16), try part1(std.testing.allocator, &input.readString(input_)));
}

test "day 16 example 5" {
    const input_ =
        \\620080001611562C8802118E34
        ;

    {
        var input__ = input.readString(input_);

        var bits = try BitsIterator.init(&input__);

        var packet = try Packet.init(std.testing.allocator, &bits);
        defer packet.deinit();

        try std.testing.expectEqual(@as(u3, 3), packet.version);
        switch (packet.body) {
            .operator => |operator| {
                try std.testing.expectEqual(@as(usize, 2), operator.sub_packets.items.len);

                for (operator.sub_packets.items) |sub_packet| {
                    switch (sub_packet.body) {
                        .operator => |sub_operator| {
                            try std.testing.expectEqual(@as(usize, 2), sub_operator.sub_packets.items.len);

                            for (sub_operator.sub_packets.items) |sub_sub_packet| {
                                switch (sub_sub_packet.body) {
                                    .literal => {},
                                    else => try std.testing.expect(false),
                                }
                            }
                        },
                        else => try std.testing.expect(false),
                    }
                }
            },
            else => try std.testing.expect(false),
        }
    }

    try std.testing.expectEqual(@as(u64, 12), try part1(std.testing.allocator, &input.readString(input_)));
}

test "day 16 example 6" {
    const input_ =
        \\C0015000016115A2E0802F182340
        ;

    {
        var input__ = input.readString(input_);

        var bits = try BitsIterator.init(&input__);

        var packet = try Packet.init(std.testing.allocator, &bits);
        defer packet.deinit();

        switch (packet.body) {
            .operator => |operator| {
                try std.testing.expectEqual(@as(usize, 2), operator.sub_packets.items.len);

                for (operator.sub_packets.items) |sub_packet| {
                    switch (sub_packet.body) {
                        .operator => |sub_operator| {
                            try std.testing.expectEqual(@as(usize, 2), sub_operator.sub_packets.items.len);

                            for (sub_operator.sub_packets.items) |sub_sub_packet| {
                                switch (sub_sub_packet.body) {
                                    .literal => {},
                                    else => try std.testing.expect(false),
                                }
                            }
                        },
                        else => try std.testing.expect(false),
                    }
                }
            },
            else => try std.testing.expect(false),
        }
    }

    try std.testing.expectEqual(@as(u64, 23), try part1(std.testing.allocator, &input.readString(input_)));
}

test "day 16 example 7" {
    const input_ =
        \\A0016C880162017C3686B18A3D4780
        ;

    {
        var input__ = input.readString(input_);

        var bits = try BitsIterator.init(&input__);

        var packet = try Packet.init(std.testing.allocator, &bits);
        defer packet.deinit();

        switch (packet.body) {
            .operator => |operator| {
                try std.testing.expectEqual(@as(usize, 1), operator.sub_packets.items.len);

                for (operator.sub_packets.items) |sub_packet| {
                    switch (sub_packet.body) {
                        .operator => |sub_operator| {
                            try std.testing.expectEqual(@as(usize, 1), sub_operator.sub_packets.items.len);

                            for (sub_operator.sub_packets.items) |sub_sub_packet| {
                                switch (sub_sub_packet.body) {
                                    .operator => |sub_sub_operator| {
                                        try std.testing.expectEqual(@as(usize, 5), sub_sub_operator.sub_packets.items.len);

                                        for (sub_sub_operator.sub_packets.items) |sub_sub_sub_packet| {
                                            switch (sub_sub_sub_packet.body) {
                                                .literal => {},
                                                else => try std.testing.expect(false),
                                            }
                                        }
                                    },
                                    else => try std.testing.expect(false),
                                }
                            }
                        },
                        else => try std.testing.expect(false),
                    }
                }
            },
            else => try std.testing.expect(false),
        }
    }

    try std.testing.expectEqual(@as(u64, 31), try part1(std.testing.allocator, &input.readString(input_)));
}

test "day 16 example 8" {
    const input_ =
        \\C200B40A82
        ;

    try std.testing.expectEqual(@as(u64, 1 + 2), try part2(std.testing.allocator, &input.readString(input_)));
}

test "day 16 example 9" {
    const input_ =
        \\04005AC33890
        ;

    try std.testing.expectEqual(@as(u64, 6 * 9), try part2(std.testing.allocator, &input.readString(input_)));
}

test "day 16 example 10" {
    const input_ =
        \\880086C3E88112
        ;

    try std.testing.expectEqual(@as(u64, std.math.min3(7, 8, 9)), try part2(std.testing.allocator, &input.readString(input_)));
}

test "day 16 example 11" {
    const input_ =
        \\CE00C43D881120
        ;

    try std.testing.expectEqual(@as(u64, std.math.max3(7, 8, 9)), try part2(std.testing.allocator, &input.readString(input_)));
}

test "day 16 example 12" {
    const input_ =
        \\D8005AC2A8F0
        ;

    try std.testing.expectEqual(@as(u64, if (5 < 15) 1 else 0), try part2(std.testing.allocator, &input.readString(input_)));
}

test "day 16 example 13" {
    const input_ =
        \\F600BC2D8F
        ;

    try std.testing.expectEqual(@as(u64, if (5 > 15) 1 else 0), try part2(std.testing.allocator, &input.readString(input_)));
}

test "day 16 example 14" {
    const input_ =
        \\9C005AC2F8F0
        ;

    try std.testing.expectEqual(@as(u64, if (5 == 15) 1 else 0), try part2(std.testing.allocator, &input.readString(input_)));
}

test "day 16 example 15" {
    const input_ =
        \\9C0141080250320F1802104A08
        ;

    try std.testing.expectEqual(@as(u64, if (1 + 3 == 2 * 2) 1 else 0), try part2(std.testing.allocator, &input.readString(input_)));
}
