const std = @import("std");

const input = @import("input.zig");

pub fn run(stdout: anytype) anyerror!void {
    {
        var input_ = try input.readFile("inputs/day23");
        defer input_.deinit();

        const result = try part1(&input_);
        try stdout.print("23a: {}\n", .{ result });
        std.debug.assert(result == 14510);
    }

    {
        var input_ = try input.readFile("inputs/day23");
        defer input_.deinit();

        const result = try part2(&input_);
        try stdout.print("23b: {}\n", .{ result });
        std.debug.assert(result == 49180);
    }
}

fn part1(input_: anytype) !u64 {
    var state = try State.init(input_);

    var cost: u64 = 0;
    move(&state, .{ .room = state.d_room[0..], .pos = 0 }, .{ .room = state.hallway[0..], .pos = 5 }, &cost);
    move(&state, .{ .room = state.d_room[0..], .pos = 1 }, .{ .room = state.hallway[0..], .pos = 4 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 4 }, .{ .room = state.hallway[0..], .pos = 0 }, &cost);
    move(&state, .{ .room = state.b_room[0..], .pos = 0 }, .{ .room = state.hallway[0..], .pos = 2 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 2 }, .{ .room = state.hallway[0..], .pos = 1 }, &cost);
    move(&state, .{ .room = state.b_room[0..], .pos = 1 }, .{ .room = state.hallway[0..], .pos = 3 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 3 }, .{ .room = state.hallway[0..], .pos = 4 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 4 }, .{ .room = state.d_room[0..], .pos = 1 }, &cost);
    move(&state, .{ .room = state.c_room[0..], .pos = 0 }, .{ .room = state.hallway[0..], .pos = 3 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 3 }, .{ .room = state.b_room[0..], .pos = 1 }, &cost);
    move(&state, .{ .room = state.c_room[0..], .pos = 1 }, .{ .room = state.hallway[0..], .pos = 4 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 4 }, .{ .room = state.d_room[0..], .pos = 0 }, &cost);
    move(&state, .{ .room = state.a_room[0..], .pos = 0 }, .{ .room = state.hallway[0..], .pos = 2 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 2 }, .{ .room = state.b_room[0..], .pos = 0 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 5 }, .{ .room = state.hallway[0..], .pos = 4 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 4 }, .{ .room = state.c_room[0..], .pos = 1 }, &cost);
    move(&state, .{ .room = state.a_room[0..], .pos = 1 }, .{ .room = state.hallway[0..], .pos = 2 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 2 }, .{ .room = state.hallway[0..], .pos = 3 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 3 }, .{ .room = state.c_room[0..], .pos = 0 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 1 }, .{ .room = state.a_room[0..], .pos = 1 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 0 }, .{ .room = state.hallway[0..], .pos = 1 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 1 }, .{ .room = state.a_room[0..], .pos = 0 }, &cost);

    std.debug.assert(isSolved1(state));

    return cost;
}

fn part2(input_: anytype) !u64 {
    var state = try State.init(input_);
    state.a_room[3] = state.a_room[1];
    state.a_room[2] = .d;
    state.a_room[1] = .d;

    state.b_room[3] = state.b_room[1];
    state.b_room[2] = .b;
    state.b_room[1] = .c;

    state.c_room[3] = state.c_room[1];
    state.c_room[2] = .a;
    state.c_room[1] = .b;

    state.d_room[3] = state.d_room[1];
    state.d_room[2] = .c;
    state.d_room[1] = .a;

    var cost: u64 = 0;
    move(&state, .{ .room = state.b_room[0..], .pos = 0 }, .{ .room = state.hallway[0..], .pos = 2 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 2 }, .{ .room = state.hallway[0..], .pos = 0 }, &cost);
    move(&state, .{ .room = state.b_room[0..], .pos = 1 }, .{ .room = state.hallway[0..], .pos = 3 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 3 }, .{ .room = state.hallway[0..], .pos = 6 }, &cost);
    move(&state, .{ .room = state.c_room[0..], .pos = 0 }, .{ .room = state.hallway[0..], .pos = 4 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 4 }, .{ .room = state.hallway[0..], .pos = 5 }, &cost);
    move(&state, .{ .room = state.c_room[0..], .pos = 1 }, .{ .room = state.hallway[0..], .pos = 4 }, &cost);
    move(&state, .{ .room = state.c_room[0..], .pos = 2 }, .{ .room = state.hallway[0..], .pos = 3 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 3 }, .{ .room = state.hallway[0..], .pos = 1 }, &cost);
    move(&state, .{ .room = state.b_room[0..], .pos = 2 }, .{ .room = state.hallway[0..], .pos = 3 }, &cost);
    move(&state, .{ .room = state.b_room[0..], .pos = 3 }, .{ .room = state.hallway[0..], .pos = 2 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 3 }, .{ .room = state.b_room[0..], .pos = 3 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 4 }, .{ .room = state.hallway[0..], .pos = 3 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 3 }, .{ .room = state.b_room[0..], .pos = 2 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 5 }, .{ .room = state.hallway[0..], .pos = 3 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 3 }, .{ .room = state.b_room[0..], .pos = 1 }, &cost);
    move(&state, .{ .room = state.c_room[0..], .pos = 3 }, .{ .room = state.hallway[0..], .pos = 3 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 6 }, .{ .room = state.hallway[0..], .pos = 4 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 4 }, .{ .room = state.c_room[0..], .pos = 3 }, &cost);
    move(&state, .{ .room = state.d_room[0..], .pos = 0 }, .{ .room = state.hallway[0..], .pos = 4 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 4 }, .{ .room = state.c_room[0..], .pos = 2 }, &cost);
    move(&state, .{ .room = state.d_room[0..], .pos = 1 }, .{ .room = state.hallway[0..], .pos = 5 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 5 }, .{ .room = state.hallway[0..], .pos = 6 }, &cost);
    move(&state, .{ .room = state.d_room[0..], .pos = 2 }, .{ .room = state.hallway[0..], .pos = 4 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 4 }, .{ .room = state.c_room[0..], .pos = 1 }, &cost);
    move(&state, .{ .room = state.d_room[0..], .pos = 3 }, .{ .room = state.hallway[0..], .pos = 5 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 3 }, .{ .room = state.hallway[0..], .pos = 4 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 4 }, .{ .room = state.d_room[0..], .pos = 3 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 2 }, .{ .room = state.hallway[0..], .pos = 4 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 4 }, .{ .room = state.d_room[0..], .pos = 2 }, &cost);
    move(&state, .{ .room = state.a_room[0..], .pos = 0 }, .{ .room = state.hallway[0..], .pos = 2 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 2 }, .{ .room = state.b_room[0..], .pos = 0 }, &cost);
    move(&state, .{ .room = state.a_room[0..], .pos = 1 }, .{ .room = state.hallway[0..], .pos = 2 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 2 }, .{ .room = state.hallway[0..], .pos = 4 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 4 }, .{ .room = state.d_room[0..], .pos = 1 }, &cost);
    move(&state, .{ .room = state.a_room[0..], .pos = 2 }, .{ .room = state.hallway[0..], .pos = 2 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 2 }, .{ .room = state.hallway[0..], .pos = 4 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 4 }, .{ .room = state.d_room[0..], .pos = 0 }, &cost);
    move(&state, .{ .room = state.a_room[0..], .pos = 3 }, .{ .room = state.hallway[0..], .pos = 2 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 2 }, .{ .room = state.hallway[0..], .pos = 3 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 3 }, .{ .room = state.c_room[0..], .pos = 0 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 1 }, .{ .room = state.a_room[0..], .pos = 3 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 0 }, .{ .room = state.hallway[0..], .pos = 1 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 1 }, .{ .room = state.a_room[0..], .pos = 2 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 5 }, .{ .room = state.hallway[0..], .pos = 2 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 2 }, .{ .room = state.a_room[0..], .pos = 1 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 6 }, .{ .room = state.hallway[0..], .pos = 2 }, &cost);
    move(&state, .{ .room = state.hallway[0..], .pos = 2 }, .{ .room = state.a_room[0..], .pos = 0 }, &cost);

    std.debug.assert(isSolved2(state));

    return cost;
}

const Spot = enum {
    a,
    b,
    c,
    d,
    empty,

    fn init(c: u8) !@This() {
        return switch (c) {
            'A' => Spot.a,
            'B' => Spot.b,
            'C' => Spot.c,
            'D' => Spot.d,
            else => return error.InvalidInput,
        };
    }
};

const State = struct {
    hallway: [7]Spot,
    a_room: [4]Spot,
    b_room: [4]Spot,
    c_room: [4]Spot,
    d_room: [4]Spot,

    fn init(input_: anytype) !@This() {
        var state = State {
            .hallway = [_]Spot { .empty } ** 7,
            .a_room = [_]Spot { .empty } ** 4,
            .b_room = [_]Spot { .empty } ** 4,
            .c_room = [_]Spot { .empty } ** 4,
            .d_room = [_]Spot { .empty } ** 4,
        };

        {
            const line = (try input_.next()) orelse return error.InvalidInput;
            if (!std.mem.eql(u8, line, "#############")) {
                return error.InvalidInput;
            }
        }

        {
            const line = (try input_.next()) orelse return error.InvalidInput;
            if (!std.mem.eql(u8, line, "#...........#")) {
                return error.InvalidInput;
            }
        }

        {
            const line = (try input_.next()) orelse return error.InvalidInput;
            if (
                line.len != 13 or
                !std.mem.eql(u8, line[0..3], "###") or
                line[4] != '#' or
                line[6] != '#' or
                line[8] != '#' or
                !std.mem.eql(u8, line[10..13], "###")
            ) {
                return error.InvalidInput;
            }

            state.a_room[0] = try Spot.init(line[3]);
            state.b_room[0] = try Spot.init(line[5]);
            state.c_room[0] = try Spot.init(line[7]);
            state.d_room[0] = try Spot.init(line[9]);
        }

        {
            const line = (try input_.next()) orelse return error.InvalidInput;
            if (
                line.len != 11 or
                !std.mem.eql(u8, line[0..3], "  #") or
                line[4] != '#' or
                line[6] != '#' or
                line[8] != '#' or
                line[10] != '#'
            ) {
                return error.InvalidInput;
            }

            state.a_room[1] = try Spot.init(line[3]);
            state.b_room[1] = try Spot.init(line[5]);
            state.c_room[1] = try Spot.init(line[7]);
            state.d_room[1] = try Spot.init(line[9]);
        }

        return state;
    }
};

fn isSolved1(state: State) bool {
    return
        isA(state.a_room[0]) and isA(state.a_room[1]) and
        isB(state.b_room[0]) and isB(state.b_room[1]) and
        isC(state.c_room[0]) and isC(state.c_room[1]) and
        isD(state.d_room[0]) and isD(state.d_room[1]);
}

fn isSolved2(state: State) bool {
    return
        isSolved1(state) and
        isA(state.a_room[2]) and isA(state.a_room[3]) and
        isB(state.b_room[2]) and isB(state.b_room[3]) and
        isC(state.c_room[2]) and isC(state.c_room[3]) and
        isD(state.d_room[2]) and isD(state.d_room[3]);
}

fn isA(spot: Spot) bool {
    return switch (spot) {
        .a => true,
        else => false,
    };
}

fn isB(spot: Spot) bool {
    return switch (spot) {
        .b => true,
        else => false,
    };
}

fn isC(spot: Spot) bool {
    return switch (spot) {
        .c => true,
        else => false,
    };
}

fn isD(spot: Spot) bool {
    return switch (spot) {
        .d => true,
        else => false,
    };
}

fn isEmpty(spot: Spot) bool {
    return switch (spot) {
        .empty => true,
        else => false,
    };
}

const Position = struct {
    room: []Spot,
    pos: usize,
};

fn move(state: *State, start: Position, end: Position, cost: *u64) void {
    if (&start.room[0] != &state.hallway[0] and &end.room[0] == &state.hallway[0]) {
        // Room to hallway

        // All positions above start are clear
        {
            var i: usize = 0;
            while (i < start.pos) : (i += 1) {
                std.debug.assert(isEmpty(start.room[i]));
                cost.* += moveCost(start.room[start.pos]);
            }
        }

        // End position is outside room
        const hallway_positions_outside_room = hallwayPositionsOutsideRoom(state, start.room);
        std.debug.assert(end.pos == hallway_positions_outside_room.left_pos or end.pos == hallway_positions_outside_room.right_pos);
        cost.* += moveCost(start.room[start.pos]) * 2;
    }
    else if (&start.room[0] == &state.hallway[0] and &end.room[0] != &state.hallway[0]) {
        // Hallway to room

        // Start position is outside room
        const hallway_positions_outside_room = hallwayPositionsOutsideRoom(state, end.room);
        std.debug.assert(start.pos == hallway_positions_outside_room.left_pos or start.pos == hallway_positions_outside_room.right_pos);

        cost.* += moveCost(start.room[start.pos]);

        // All positions until end are clear
        {
            var i: usize = 0;
            while (i <= end.pos) : (i += 1) {
                std.debug.assert(isEmpty(end.room[i]));
                cost.* += moveCost(start.room[start.pos]);
            }
        }
    }
    else if (&start.room[0] == &state.hallway[0] and &end.room[0] == &state.hallway[0]) {
        // Hallway to hallway

        switch (std.math.order(start.pos, end.pos)) {
            .lt => {
                var i = start.pos + 1;
                while (i <= end.pos) : (i += 1) {
                    std.debug.assert(isEmpty(state.hallway[i]));
                    cost.* += moveCost(start.room[start.pos]);
                    switch (i) {
                        2, 3, 4, 5 => cost.* += moveCost(start.room[start.pos]),
                        else => {},
                    }
                }
            },
            .eq => unreachable,
            .gt => {
                var i = end.pos;
                while (i < start.pos) : (i += 1) {
                    std.debug.assert(isEmpty(state.hallway[i]));
                    cost.* += moveCost(start.room[start.pos]);
                    switch (i) {
                        1, 2, 3, 4 => cost.* += moveCost(start.room[start.pos]),
                        else => {},
                    }
                }
            },
        }
    }
    else {
        unreachable;
    }

    end.room[end.pos] = start.room[start.pos];
    start.room[start.pos] = .empty;
}

fn moveCost(spot: Spot) u64 {
    return switch (spot) {
        .a => 1,
        .b => 10,
        .c => 100,
        .d => 1000,
        else => unreachable,
    };
}

const HallwayPositionOutsideRoomResult = struct {
    left_pos: usize,
    right_pos: usize,
};

fn hallwayPositionsOutsideRoom(state: *const State, room: []const Spot) HallwayPositionOutsideRoomResult {
    return
        if (&room[0] == &state.a_room[0]) HallwayPositionOutsideRoomResult { .left_pos = 1, .right_pos = 2 }
        else if (&room[0] == &state.b_room[0]) HallwayPositionOutsideRoomResult { .left_pos = 2, .right_pos = 3 }
        else if (&room[0] == &state.c_room[0]) HallwayPositionOutsideRoomResult { .left_pos = 3, .right_pos = 4 }
        else if (&room[0] == &state.d_room[0]) HallwayPositionOutsideRoomResult { .left_pos = 4, .right_pos = 5 }
        else unreachable;
}
