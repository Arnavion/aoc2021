const std = @import("std");

const input = @import("input.zig");

pub fn run(stdout: anytype) anyerror!void {
    {
        var input_ = try input.readFile("inputs/day9");
        defer input_.deinit();

        const result = try part1(&input_);
        try stdout.print("9a: {}\n", .{ result });
        std.debug.assert(result == 570);
    }

    {
        var input_ = try input.readFile("inputs/day9");
        defer input_.deinit();

        const result = try part2(&input_);
        try stdout.print("9b: {}\n", .{ result });
        std.debug.assert(result == 899392);
    }
}

const num_input_rows = 100;
const num_input_cols = 100;

const Part1Result = std.math.IntFittingRange(0, num_input_rows * num_input_cols * (1 + 9));

fn part1(input_: anytype) !Part1Result {
    var map_view: [3][1 + num_input_cols + 1]u8 = [_][1 + num_input_cols + 1]u8 {
        [_]u8 { '9' } ** (1 + num_input_cols + 1),
    } ** 3;
    var first_row: usize = 0;

    var result: Part1Result = 0;

    while (true) {
        if (try input_.next()) |line| {
            std.mem.copy(u8, map_view[(first_row + 2) % 3][1..(1 + num_input_cols)], line);
            part1_inner(map_view, first_row, &result);
        }
        else {
            std.mem.set(u8, map_view[(first_row + 2) % 3][1..(1 + num_input_cols)], '9');
            part1_inner(map_view, first_row, &result);
            break;
        }

        first_row = (first_row + 1) % 3;
    }

    return result;
}

fn part1_inner(
    map_view: [3][1 + num_input_cols + 1]u8,
    first_row: usize,
    result: *Part1Result,
) void {
    const prev_row = &map_view[first_row];
    const curr_row = &map_view[(first_row + 1) % 3];
    const next_row = &map_view[(first_row + 2) % 3];

    for (curr_row[1..(1 + num_input_cols)]) |height, col_i| {
        if (height < curr_row[col_i] and height < curr_row[col_i + 2] and height < prev_row[col_i + 1] and height < next_row[col_i + 1]) {
            result.* += 1 + (height - '0');
        }
    }
}

const Part2Result = std.math.IntFittingRange(0, (num_input_rows * num_input_cols / 3) * (num_input_rows * num_input_cols / 3) * (num_input_rows * num_input_cols / 3));

fn part2(input_: anytype) !Part2Result {
    const BasinSize = std.math.IntFittingRange(0, num_input_rows * num_input_cols);

    const Spot = enum {
        wall,
        basin_unmarked,
        basin_marked,
    };

    var map: [1 + num_input_rows + 1][1 + num_input_cols + 1]Spot = [_][1 + num_input_cols + 1]Spot {
        [_]Spot { .wall } ** (1 + num_input_cols + 1)
    } ** (1 + num_input_rows + 1);

    {
        var row_i: usize = 1;
        while (try input_.next()) |line| {
            for (line) |c, col_i| {
                if (c != '9') {
                    map[row_i][col_i + 1] = .basin_unmarked;
                }
            }

            row_i += 1;
        }
    }

    var basins = [_]BasinSize { 1 } ** 4;
    var smallest_basin_i: usize = 0;

    var find_new_basin_row_i: usize = 1;
    var find_new_basin_col_i: usize = 1;

    while (find_new_basin_row_i < (1 + num_input_rows)) : (find_new_basin_row_i += 1) {
        const find_new_basin_row = &map[find_new_basin_row_i];

        while (find_new_basin_col_i < (1 + num_input_cols)) : (find_new_basin_col_i += 1) {
            const find_new_basin_spot = &find_new_basin_row[find_new_basin_col_i];

            if (find_new_basin_spot.* != .basin_unmarked) {
                continue;
            }

            // Found an unmarked basin spot. This is the first spot in a new basin.
            find_new_basin_spot.* = .basin_marked;

            basins[smallest_basin_i] = 1;

            // Find all other spots in this basin
            while (true) {
                var found_another_spot = false;

                var row_i = find_new_basin_row_i;
                var col_i = find_new_basin_col_i;

                while (row_i < (1 + num_input_rows)) : (row_i += 1) {
                    const row = &map[row_i];

                    while (col_i < (1 + num_input_cols)) : (col_i += 1) {
                        const spot = &row[col_i];

                        if (spot.* != .basin_unmarked) {
                            continue;
                        }

                        if (
                            map[row_i][col_i - 1] == .basin_marked or
                            map[row_i][col_i + 1] == .basin_marked or
                            map[row_i - 1][col_i] == .basin_marked or
                            map[row_i + 1][col_i] == .basin_marked
                        ) {
                            spot.* = .basin_marked;
                            basins[smallest_basin_i] += 1;
                            found_another_spot = true;
                        }
                    }

                    col_i = 1;
                }

                if (!found_another_spot) {
                    // No more spots in this basin
                    break;
                }
            }

            smallest_basin_i = std.sort.argMin(BasinSize, basins[0..], {}, comptime std.sort.asc(BasinSize)).?;
        }

        find_new_basin_col_i = 1;
    }

    var result: Part2Result = 1;
    for (basins) |basin, basin_i| {
        if (basin_i != smallest_basin_i) {
            result *= basin;
        }
    }
    return result;
}

test "day 9 example 1" {
    const input_ =
        \\2199943210
        \\3987894921
        \\9856789892
        \\8767896789
        \\9899965678
        ;

    try std.testing.expectEqual(@as(Part1Result, 2 + 1 + 6 + 6), try part1(&input.readString(input_)));
    try std.testing.expectEqual(@as(Part2Result, 9 * 14 * 9), try part2(&input.readString(input_)));
}
