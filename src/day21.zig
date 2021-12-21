const std = @import("std");

const input = @import("input.zig");

pub fn run(allocator: std.mem.Allocator, stdout: anytype) anyerror!void {
    {
        var input_ = try input.readFile("inputs/day21");
        defer input_.deinit();

        const result = try part1(&input_);
        try stdout.print("21a: {}\n", .{ result });
        std.debug.assert(result == 864900);
    }

    {
        var input_ = try input.readFile("inputs/day21");
        defer input_.deinit();

        const result = try part2(allocator, &input_);
        try stdout.print("21b: {}\n", .{ result });
        std.debug.assert(result == 575111835924670);
    }
}

const max_position = 10;
const Position = std.math.IntFittingRange(1, max_position);

const num_dice_rolled_per_turn = 3;

fn Score(comptime max_score: comptime_int) type {
    return std.math.IntFittingRange(0, max_score + max_position);
}

fn part1(input_: anytype) !u64 {
    const max_dice_roll = 100;

    const max_score = 1000;

    var player1_pos: Position = player1_pos: {
        const line = (try input_.next()) orelse return error.InvalidInput;
        break :player1_pos try std.fmt.parseInt(Position, &[_]u8 { line[line.len - 1] }, 10);
    };
    var player1_score: Score(max_score) = 0;

    var player2_pos: Position = player2_pos: {
        const line = (try input_.next()) orelse return error.InvalidInput;
        break :player2_pos try std.fmt.parseInt(Position, &[_]u8 { line[line.len - 1] }, 10);
    };
    var player2_score: Score(max_score) = 0;

    var num_dice_rolls: usize = 0;
    const losing_player_score = losing_player_score:
        while (true) {
            {
                var roll_i: usize = 0;
                while (roll_i < num_dice_rolled_per_turn) : (roll_i += 1) {
                    const roll = part1_roll_dice(max_dice_roll, &num_dice_rolls);
                    player1_pos = movePlayer(max_dice_roll, player1_pos, roll);
                }
            }
            player1_score += player1_pos;
            if (player1_score >= max_score) {
                break :losing_player_score player2_score;
            }

            {
                var roll_i: usize = 0;
                while (roll_i < num_dice_rolled_per_turn) : (roll_i += 1) {
                    const roll = part1_roll_dice(max_dice_roll, &num_dice_rolls);
                    player2_pos = movePlayer(max_dice_roll, player2_pos, roll);
                }
            }
            player2_score += player2_pos;
            if (player2_score >= max_score) {
                break :losing_player_score player1_score;
            }
        }
        else {
            unreachable;
        };

    return num_dice_rolls * losing_player_score;
}

fn part1_roll_dice(
    comptime max_dice_roll: comptime_int,
    num_rolls: *usize,
) std.math.IntFittingRange(1, max_dice_roll) {
    const roll = num_rolls.* % max_dice_roll + 1;
    num_rolls.* += 1;
    return @intCast(std.math.IntFittingRange(1, max_dice_roll), roll);
}

fn part2(allocator: std.mem.Allocator, input_: anytype) !usize {
    const max_dice_roll = 3;

    const max_score = 21;

    var player1_pos: Position = player1_pos: {
        const line = (try input_.next()) orelse return error.InvalidInput;
        break :player1_pos try std.fmt.parseInt(Position, &[_]u8 { line[line.len - 1] }, 10);
    };
    var player1_score: Score(max_score) = 0;

    var player2_pos: Position = player2_pos: {
        const line = (try input_.next()) orelse return error.InvalidInput;
        break :player2_pos try std.fmt.parseInt(Position, &[_]u8 { line[line.len - 1] }, 10);
    };
    var player2_score: Score(max_score) = 0;

    var universes = Universes(max_score).init(allocator);
    defer universes.deinit();

    const num_victories = try part2_inner(
        max_dice_roll,
        max_score,
        .{
            .player1_pos = player1_pos, .player1_score = player1_score,
            .player2_pos = player2_pos, .player2_score = player2_score,
        },
        &universes,
    );

    return std.math.max(num_victories.player1, num_victories.player2);
}

fn Universe(comptime max_score: comptime_int) type {
    return struct {
        player1_pos: Position,
        player1_score: Score(max_score),
        player2_pos: Position,
        player2_score: Score(max_score),
    };
}

const NumVictories = struct {
    player1: usize,
    player2: usize,
};

fn Universes(comptime max_score: comptime_int) type {
    return std.AutoHashMap(Universe(max_score), NumVictories);
}

fn part2_dice_rolls(comptime max_dice_roll: comptime_int) [1 + max_dice_roll * num_dice_rolled_per_turn]usize {
    var result = [_]usize { 0 } ** (1 + max_dice_roll * num_dice_rolled_per_turn);

    result[0] = 1;

    comptime var roll_i = 1;
    inline while (roll_i <= num_dice_rolled_per_turn) : (roll_i += 1) {
        var new_result = [_]usize { 0 } ** (1 + max_dice_roll * num_dice_rolled_per_turn);

        comptime var roll_j = 1;
        inline while (roll_j <= max_dice_roll) : (roll_j += 1) {
            comptime var prev_i = 0;
            inline while (prev_i <= max_dice_roll * (roll_i - 1)) : (prev_i += 1) {
                new_result[prev_i + roll_j] += result[prev_i];
            }
        }

        result = new_result;
    }

    return result;
}

fn part2_inner(
    comptime max_dice_roll: comptime_int,
    comptime max_score: comptime_int,
    universe: Universe(max_score),
    universes: *Universes(max_score),
) @TypeOf(universes.allocator).Error!NumVictories {
    const DiceRoll = std.math.IntFittingRange(1 * num_dice_rolled_per_turn, max_dice_roll * num_dice_rolled_per_turn);

    if (universes.get(universe)) |num_victories| {
        return num_victories;
    }

    var num_victories = NumVictories {
        .player1 = 0,
        .player2 = 0,
    };

    for (part2_dice_rolls(max_dice_roll)) |dice1_count, dice1_roll_| {
        if (dice1_count == 0) {
            continue;
        }

        const dice1_roll = @intCast(DiceRoll, dice1_roll_);

        var player1_pos_new = movePlayer(max_dice_roll * num_dice_rolled_per_turn, universe.player1_pos, dice1_roll);
        var player1_score_new = universe.player1_score + player1_pos_new;
        if (player1_score_new >= max_score) {
            num_victories.player1 += dice1_count;
            continue;
        }

        for (part2_dice_rolls(max_dice_roll)) |dice2_count, dice2_roll_| {
            if (dice2_count == 0) {
                continue;
            }

            const dice2_roll = @intCast(DiceRoll, dice2_roll_);

            var player2_pos_new = movePlayer(max_dice_roll * num_dice_rolled_per_turn, universe.player2_pos, dice2_roll);
            var player2_score_new = universe.player2_score + player2_pos_new;
            if (player2_score_new >= max_score) {
                num_victories.player2 += dice2_count;
                continue;
            }

            const sub_num_victories = try part2_inner(
                max_dice_roll,
                max_score,
                .{
                    .player1_pos = player1_pos_new, .player1_score = player1_score_new,
                    .player2_pos = player2_pos_new, .player2_score = player2_score_new,
                },
                universes,
            );
            num_victories.player1 += sub_num_victories.player1 * dice1_count * dice2_count;
            num_victories.player2 += sub_num_victories.player2 * dice1_count * dice2_count;
        }
    }

    const entry = try universes.getOrPutValue(universe, .{ .player1 = 0, .player2 = 0 });
    entry.value_ptr.player1 += num_victories.player1;
    entry.value_ptr.player2 += num_victories.player2;
    return num_victories;
}

fn movePlayer(
    comptime max_dice_roll: comptime_int,
    pos: Position,
    roll: std.math.IntFittingRange(1, max_dice_roll),
) Position {
    const TempPosition = std.math.IntFittingRange(0, std.math.max(max_position, max_position - 1 + max_dice_roll));

    const temp_pos: TempPosition = pos - 1;
    const new_temp_pos: TempPosition = ((temp_pos + roll) % max_position) + 1;
    return @intCast(Position, new_temp_pos);
}

test "day 21 example 1" {
    const input_ =
        \\Player 1 starting position: 4
        \\Player 2 starting position: 8
        ;

    try std.testing.expectEqual(@as(u64, 745 * 993), try part1(&input.readString(input_)));
    try std.testing.expectEqual(@as(usize, std.math.max(444356092776315, 341960390180808)), try part2(std.testing.allocator, &input.readString(input_)));
}
