const std = @import("std");

const input = @import("input.zig");

pub fn run(allocator: std.mem.Allocator, stdout: anytype) anyerror!void {
    var input_ = try input.readFile("inputs/day4");
    defer input_.deinit();

    var input_parsed = try Input.init(allocator, &input_);
    defer input_parsed.deinit();

    {
        const result = try part1(&input_parsed);
        try stdout.print("4a: {}\n", .{ result });
        std.debug.assert(result == 11774);
    }

    for (input_parsed.boards.items) |*board| {
        board.resetMarked();
    }

    {
        const result = try part2(&input_parsed);
        try stdout.print("4b: {}\n", .{ result });
        std.debug.assert(result == 4495);
    }
}

const Input = struct {
    nums: std.ArrayList(BoardSpot.Type),
    boards: std.ArrayList(Board),

    fn init(allocator: std.mem.Allocator, input_: anytype) !@This() {
        var nums = std.ArrayList(BoardSpot.Type).init(allocator);
        errdefer nums.deinit();
        {
            const line = (try input_.next()) orelse return error.InvalidInput;
            var nums_iterator = std.mem.split(u8, line, ",");
            while (nums_iterator.next()) |num| {
                try nums.append(try std.fmt.parseInt(BoardSpot.Type, num, 10));
            }
        }

        var boards = std.ArrayList(Board).init(allocator);
        errdefer boards.deinit();
        while (try Board.init(input_)) |board| {
            try boards.append(board);
        }

        return Input {
            .nums = nums,
            .boards = boards,
        };
    }

    fn deinit(self: @This()) void {
        self.nums.deinit();
        self.boards.deinit();
    }
};

const Board = struct {
    const rows = 5;
    const cols = 5;
    const Sum = std.math.IntFittingRange(0, BoardSpot.max * cols * rows);
    const Score = std.math.IntFittingRange(0, BoardSpot.max * cols * rows * BoardSpot.max);

    spots: [rows][cols]BoardSpot = [_][cols]BoardSpot { [_]BoardSpot { .{ .num = 0, .marked = false } } ** cols } ** rows,
    unmarked_sum: Sum = 0,

    fn init(input_: anytype) !?@This() {
        var nums = std.BoundedArray(BoardSpot.Type, cols * rows).init(0) catch unreachable;

        while (try input_.next()) |line| {
            var nums_iterator = std.mem.tokenize(u8, line, " ");
            while (nums_iterator.next()) |num_s| {
                const num = try std.fmt.parseInt(BoardSpot.Type, num_s, 10);
                try nums.append(num);
            }

            if (nums.len == cols * rows) {
                var result = Board {};
                for (nums.constSlice()) |num, i| {
                    result.spots[i / cols][i % cols].num = num;
                    result.unmarked_sum += num;
                }
                return result;
            }
        }

        if (nums.len > 0) {
            return error.InvalidInput;
        }

        return null;
    }

    fn resetMarked(self: *@This()) void {
        for (self.spots) |*row| {
            for (row) |*spot| {
                if (spot.marked) {
                    spot.marked = false;
                    self.unmarked_sum += spot.num;
                }
            }
        }
    }

    fn mark(self: *@This(), num: BoardSpot.Type) ?Score {
        const marked_spot =
            marked_spot: for (self.spots) |*row, row_num| {
                for (row) |*spot, col_num| {
                    if (spot.num == num) {
                        spot.marked = true;
                        self.unmarked_sum -= num;
                        break :marked_spot .{ .row_num = row_num, .col_num = col_num };
                    }
                }
            }
            else return null;

        const row_num = marked_spot.row_num;
        const col_num = marked_spot.col_num;

        const has_won = has_won: {
            var allRowMarked = true;
            for (self.spots[row_num]) |*spot| {
                if (!spot.marked) {
                    allRowMarked = false;
                    break;
                }
            }
            if (allRowMarked) {
                break :has_won true;
            }

            var allColMarked = true;
            for (self.spots) |*row| {
                if (!row[col_num].marked) {
                    allColMarked = false;
                    break;
                }
            }
            if (allColMarked) {
                break :has_won true;
            }

            break :has_won false;
        };
        return
            if (has_won) @as(Score, self.unmarked_sum) * @as(Score, num)
            else null;
    }
};

const BoardSpot = struct {
    const max = 99;
    const Type = std.math.IntFittingRange(0, max);

    num: Type,
    marked: bool,
};

fn part1(input_: *Input) !Board.Score {
    for (input_.nums.items) |num| {
        for (input_.boards.items) |*board| {
            return board.mark(num) orelse continue;
        }
    }

    return error.NoBoardsWon;
}

fn part2(input_: *Input) !Board.Score {
    for (input_.nums.items) |num| {
        var board_i: usize = 0;
        while (board_i < input_.boards.items.len) {
            const board = &input_.boards.items[board_i];

            if (board.mark(num)) |score| {
                if (input_.boards.items.len == 1) {
                    return score;
                }

                _ = input_.boards.swapRemove(board_i);
            }
            else {
                board_i += 1;
            }
        }
    }

    return error.NotAllBoardsWon;
}

test "day 4 example 1" {
    const input_ =
        \\7,4,9,5,11,17,23,2,0,14,21,24,10,16,13,6,15,25,12,22,18,20,8,19,3,26,1
        \\
        \\22 13 17 11  0
        \\ 8  2 23  4 24
        \\21  9 14 16  7
        \\ 6 10  3 18  5
        \\ 1 12 20 15 19
        \\
        \\ 3 15  0  2 22
        \\ 9 18 13 17  5
        \\19  8  7 25 23
        \\20 11 10 24  4
        \\14 21 16 12  6
        \\
        \\14 21 17 24  4
        \\10 16 15  9 19
        \\18  8 23 26 20
        \\22 11 13  6  5
        \\ 2  0 12  3  7
        ;

    var input__ = input.readString(input_);
    var input_parsed = try Input.init(std.testing.allocator, &input__);
    defer input_parsed.deinit();

    try std.testing.expectEqual(@as(Board.Score, 188 * 24), try part1(&input_parsed));

    for (input_parsed.boards.items) |*board| {
        board.resetMarked();
    }

    try std.testing.expectEqual(@as(Board.Score, 148 * 13), try part2(&input_parsed));
}
