const builtin = @import("builtin");
const std = @import("std");

const input = @import("input.zig");

pub fn run(stdout: anytype) anyerror!void {
    if (builtin.mode != .Debug) {
        var input_ = try input.readFile("inputs/day19");
        defer input_.deinit();
        var scanners = try parseInput(&input_);

        const next_beacon_id = identifyBeacons(scanners.slice());

        {
            const result = part1(next_beacon_id);
            try stdout.print("19a: {}\n", .{ result });
            std.debug.assert(result == 303);
        }

        identifyScanners(scanners.slice());

        {
            const result = try part2(scanners.constSlice());
            try stdout.print("19b: {}\n", .{ result });
            std.debug.assert(result == 9621);
        }
    }
}

const max_num_scanners = 25;
const max_num_beacons_per_scanner = 26;
const NumBeacons = u16;

fn parseInput(input_: anytype) !std.BoundedArray(Scanner, max_num_scanners) {
    var scanners = std.BoundedArray(Scanner, max_num_scanners).init(0) catch unreachable;

    while (try Scanner.init(input_)) |scanner| {
        try scanners.append(scanner);
    }

    scanners.slice()[0].pos = .{ .p = 0, .q = 0, .r = 0 };

    return scanners;
}

fn identifyBeacons(scanners: []Scanner) NumBeacons {
    var next_beacon_id: NumBeacons = 0;

    while (nextUnidentifiedBeacon(scanners)) |beacon1x| {
        const scanner1_i = beacon1x.scanner_i;
        const scanner1 = &scanners[scanner1_i];

        const beacon1a_i = beacon1x.beacon_i;
        const beacon1a = beacon1x.beacon;

        const beacon1a_id = next_beacon_id;
        next_beacon_id += 1;

        beacon1a.id = beacon1a_id;

        for (scanner1.beacons.constSlice()) |beacon1b, beacon1b_i| {
            if (beacon1b_i == beacon1a_i) {
                continue;
            }
            if (beacon1b.id == null) {
                continue;
            }

            for (scanner1.beacons.constSlice()[(beacon1b_i + 1)..]) |beacon1c, beacon1c_i_| {
                const beacon1c_i = beacon1b_i + 1 + beacon1c_i_;
                if (beacon1c_i == beacon1a_i) {
                    continue;
                }
                if (beacon1c.id == null) {
                    continue;
                }

                const distances1 = .{
                    scanner1.distances[beacon1a_i][beacon1b_i],
                    scanner1.distances[beacon1a_i][beacon1c_i],
                    scanner1.distances[beacon1b_i][beacon1c_i],
                };

                for (scanners[(scanner1_i + 1)..]) |*scanner2, scanner2_i_| {
                    const scanner2_i = scanner1_i + 1 + scanner2_i_;
                    for (scanner2.beacons.slice()) |*beacon2a, beacon2a_i| {
                        for (scanner2.beacons.slice()[(beacon2a_i + 1)..]) |*beacon2b, beacon2b_i_| {
                            const beacon2b_i = beacon2a_i + 1 + beacon2b_i_;

                            for (scanner2.beacons.slice()[(beacon2b_i + 1)..]) |*beacon2c, beacon2c_i_| {
                                const beacon2c_i = beacon2b_i + 1 + beacon2c_i_;

                                if (beacon2a.id != null and beacon2b.id != null and beacon2c.id != null) {
                                    continue;
                                }

                                const distances2 = .{
                                    scanner2.distances[beacon2a_i][beacon2b_i],
                                    scanner2.distances[beacon2a_i][beacon2c_i],
                                    scanner2.distances[beacon2b_i][beacon2c_i],
                                };

                                const congruent_i: ?[3]usize =
                                    if (distances1[0] == distances2[0] and distances1[1] == distances2[1] and distances1[2] == distances2[2])
                                        // 2a == 1a, 2b == 1b, 2c == 1c
                                        [_]usize { beacon1a_i, beacon1b_i, beacon1c_i }
                                    else if (distances1[0] == distances2[0] and distances1[1] == distances2[2] and distances1[2] == distances2[1])
                                        // 2a == 1b, 2b == 1a, 2c == 1c
                                        [_]usize { beacon1b_i, beacon1a_i, beacon1c_i }
                                    else if (distances1[0] == distances2[1] and distances1[1] == distances2[0] and distances1[2] == distances2[2])
                                        // 2a == 1a, 2b == 1c, 2c == 1b
                                        [_]usize { beacon1a_i, beacon1c_i, beacon1b_i }
                                    else if (distances1[0] == distances2[1] and distances1[1] == distances2[2] and distances1[2] == distances2[0])
                                        // 2a == 1b, 2b == 1c, 2c == 1a
                                        [_]usize { beacon1b_i, beacon1c_i, beacon1a_i }
                                    else if (distances1[0] == distances2[2] and distances1[1] == distances2[0] and distances1[2] == distances2[1])
                                        // 2a == 1c, 2b == 1a, 2c == 1b
                                        [_]usize { beacon1c_i, beacon1a_i, beacon1b_i }
                                    else if (distances1[0] == distances2[2] and distances1[1] == distances2[1] and distances1[2] == distances2[0])
                                        // 2a == 1c, 2b == 1b, 2c == 1a
                                        [_]usize { beacon1c_i, beacon1b_i, beacon1a_i }
                                    else null;

                                if (congruent_i) |congruent_i_| {
                                    const congruent: [3]Beacon = .{
                                        scanner1.beacons.constSlice()[congruent_i_[0]],
                                        scanner1.beacons.constSlice()[congruent_i_[1]],
                                        scanner1.beacons.constSlice()[congruent_i_[2]],
                                    };

                                    const congruent0_id = congruent[0].id.?;
                                    const congruent1_id = congruent[1].id.?;
                                    const congruent2_id = congruent[2].id.?;

                                    if (beacon2a.id) |beacon2a_id| {
                                        std.debug.assert(beacon2a_id == congruent0_id);
                                    }
                                    else {
                                        beacon2a.id = congruent0_id;
                                    }

                                    if (beacon2b.id) |beacon2b_id| {
                                        std.debug.assert(beacon2b_id == congruent1_id);
                                    }
                                    else {
                                        beacon2b.id = congruent1_id;
                                    }

                                    if (beacon2c.id) |beacon2c_id| {
                                        std.debug.assert(beacon2c_id == congruent2_id);
                                    }
                                    else {
                                        beacon2c.id = congruent2_id;
                                    }

                                    scanner1.known_congruents[scanner2_i] = KnownCongruent {
                                        .beacon1a_i = beacon2a_i,
                                        .beacon1b_i = beacon2b_i,
                                        .beacon1c_i = beacon2c_i,
                                        .beacon2a_i = congruent_i_[0],
                                        .beacon2b_i = congruent_i_[1],
                                        .beacon2c_i = congruent_i_[2],
                                    };

                                    scanner2.known_congruents[scanner1_i] = KnownCongruent {
                                        .beacon1a_i = congruent_i_[0],
                                        .beacon1b_i = congruent_i_[1],
                                        .beacon1c_i = congruent_i_[2],
                                        .beacon2a_i = beacon2a_i,
                                        .beacon2b_i = beacon2b_i,
                                        .beacon2c_i = beacon2c_i,
                                    };
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    return next_beacon_id;
}

fn part1(next_beacon_id: NumBeacons) NumBeacons {
    return next_beacon_id;
}

fn identifyScanners(scanners: []Scanner) void {
    while (true) {
        var updated_one_scanner = false;
        for (scanners) |*scanner2| {
            if (scanner2.pos != null) {
                continue;
            }

            for (scanner2.known_congruents) |known_congruent_, scanner1_i| {
                if (known_congruent_) |known_congruent| {
                    const scanner1 = scanners[scanner1_i];

                    if (scanner1.pos) |scanner1_pos| {
                        const beacon1a = scanner1.beacons.constSlice()[known_congruent.beacon1a_i];
                        const beacon1b = scanner1.beacons.constSlice()[known_congruent.beacon1b_i];
                        const beacon1c = scanner1.beacons.constSlice()[known_congruent.beacon1c_i];

                        const beacon2a = &scanner2.beacons.slice()[known_congruent.beacon2a_i];
                        const beacon2b = &scanner2.beacons.slice()[known_congruent.beacon2b_i];
                        const beacon2c = &scanner2.beacons.slice()[known_congruent.beacon2c_i];

                        var permute_i: usize = 0;
                        var temp_beacon2a_pos: Coord = undefined;
                        var temp_beacon2b_pos: Coord = undefined;
                        var temp_beacon2c_pos: Coord = undefined;
                        while (permute_i < 24) : (permute_i += 1) {
                            temp_beacon2a_pos = permuteCoord(beacon2a.pos, permute_i);
                            temp_beacon2b_pos = permuteCoord(beacon2b.pos, permute_i);
                            temp_beacon2c_pos = permuteCoord(beacon2c.pos, permute_i);

                            if (coordsLineUp(
                                beacon1a.pos, beacon1b.pos, beacon1c.pos,
                                temp_beacon2a_pos, temp_beacon2b_pos, temp_beacon2c_pos,
                            )) {
                                break;
                            }
                        }
                        else {
                            unreachable;
                        }

                        for (scanner2.beacons.slice()) |*beacon| {
                            // TODO:
                            // Can't write `beacon.pos = permuteCoord(beacon.pos, permute_i);` because it's miscompiled,
                            // likely due to https://github.com/ziglang/zig/issues/3696
                            const new_pos = permuteCoord(beacon.pos, permute_i);
                            beacon.pos = new_pos;
                        }

                        std.debug.assert(coordsLineUp(
                            beacon1a.pos, beacon1b.pos, beacon1c.pos,
                            beacon2a.pos, beacon2b.pos, beacon2c.pos,
                        ));

                        std.debug.assert(scanner1_pos.p + beacon1a.pos.p - beacon2a.pos.p == scanner1_pos.p + beacon1b.pos.p - beacon2b.pos.p);
                        std.debug.assert(scanner1_pos.p + beacon1a.pos.p - beacon2a.pos.p == scanner1_pos.p + beacon1c.pos.p - beacon2c.pos.p);
                        std.debug.assert(scanner1_pos.q + beacon1a.pos.q - beacon2a.pos.q == scanner1_pos.q + beacon1b.pos.q - beacon2b.pos.q);
                        std.debug.assert(scanner1_pos.q + beacon1a.pos.q - beacon2a.pos.q == scanner1_pos.q + beacon1c.pos.q - beacon2c.pos.q);
                        std.debug.assert(scanner1_pos.r + beacon1a.pos.r - beacon2a.pos.r == scanner1_pos.r + beacon1b.pos.r - beacon2b.pos.r);
                        std.debug.assert(scanner1_pos.r + beacon1a.pos.r - beacon2a.pos.r == scanner1_pos.r + beacon1c.pos.r - beacon2c.pos.r);

                        scanner2.pos = .{
                            .p = scanner1_pos.p + beacon1a.pos.p - beacon2a.pos.p,
                            .q = scanner1_pos.q + beacon1a.pos.q - beacon2a.pos.q,
                            .r = scanner1_pos.r + beacon1a.pos.r - beacon2a.pos.r,
                        };

                        updated_one_scanner = true;
                    }
                }
            }
        }
        if (!updated_one_scanner) {
            break;
        }
    }
}

fn part2(scanners: []const Scanner) !Dimension {
    var max_distance: Dimension = 0;
    for (scanners) |scanner1| {
        for (scanners) |scanner2| {
            max_distance = std.math.max(max_distance, try manhattanDistance(scanner1.pos.?, scanner2.pos.?));
        }
    }
    return max_distance;
}

const Scanner = struct {
    beacons: std.BoundedArray(Beacon, max_num_beacons_per_scanner),
    distances: [max_num_beacons_per_scanner][max_num_beacons_per_scanner]Dimension,
    known_congruents: [max_num_scanners]?KnownCongruent,
    pos: ?Coord,

    fn init(input_: anytype) !?@This() {
        var result = Scanner {
            .beacons = std.BoundedArray(Beacon, max_num_beacons_per_scanner).init(0) catch unreachable,
            .distances = undefined,
            .known_congruents = [_]?KnownCongruent { null } ** max_num_scanners,
            .pos = null,
        };

        if ((try input_.next()) == null) {
            return null;
        }

        while (try input_.next()) |line| {
            if (line.len == 0) {
                break;
            }

            var parts = std.mem.split(u8, line, ",");
            const p_s = parts.next() orelse return error.InvalidInput;
            const p = try std.fmt.parseInt(Dimension, p_s, 10);
            const q_s = parts.next() orelse return error.InvalidInput;
            const q = try std.fmt.parseInt(Dimension, q_s, 10);
            const r_s = parts.next() orelse return error.InvalidInput;
            const r = try std.fmt.parseInt(Dimension, r_s, 10);
            try result.beacons.append(.{
                .pos = .{ .p = p, .q = q, .r = r },
                .id = null,
            });
        }

        for (result.beacons.constSlice()) |beacon1, beacon1_i| {
            for (result.beacons.constSlice()) |beacon2, beacon2_i| {
                result.distances[beacon1_i][beacon2_i] = eulerDistance(beacon1.pos, beacon2.pos);
            }
        }

        return result;
    }
};

const Beacon = struct {
    pos: Coord,
    id: ?NumBeacons,
};

const Coord = struct {
    p: Dimension,
    q: Dimension,
    r: Dimension,
};

const Dimension = i32;

const KnownCongruent = struct {
    beacon1a_i: usize,
    beacon1b_i: usize,
    beacon1c_i: usize,
    beacon2a_i: usize,
    beacon2b_i: usize,
    beacon2c_i: usize,
};

fn eulerDistance(a: Coord, b: Coord) Dimension {
    return (a.p - b.p) * (a.p - b.p) + (a.q - b.q) * (a.q - b.q) + (a.r - b.r) * (a.r - b.r);
}

fn manhattanDistance(a: Coord, b: Coord) !Dimension {
    return (try std.math.absInt(a.p - b.p)) + (try std.math.absInt(a.q - b.q)) + (try std.math.absInt(a.r - b.r));
}

const UnidentifiedBeacon = struct {
    scanner_i: usize,
    beacon_i: usize,
    beacon: *Beacon,
};

fn nextUnidentifiedBeacon(scanners: []Scanner) ?UnidentifiedBeacon {
    for (scanners) |*scanner, scanner_i| {
        for (scanner.beacons.slice()) |*beacon, beacon_i| {
            if (beacon.id == null) {
                return UnidentifiedBeacon {
                    .scanner_i = scanner_i,
                    .beacon_i = beacon_i,
                    .beacon = beacon,
                };
            }
        }
    }

    return null;
}

fn coordsLineUp(
    a1: Coord, b1: Coord, c1: Coord,
    a2: Coord, b2: Coord, c2: Coord,
) bool {
    return
        (b1.p - a1.p == b2.p - a2.p) and
        (b1.q - a1.q == b2.q - a2.q) and
        (b1.r - a1.r == b2.r - a2.r) and
        (c1.p - a1.p == c2.p - a2.p) and
        (c1.q - a1.q == c2.q - a2.q) and
        (c1.r - a1.r == c2.r - a2.r) and
        (c1.p - b1.p == c2.p - b2.p) and
        (c1.q - b1.q == c2.q - b2.q) and
        (c1.r - b1.r == c2.r - b2.r);
}

fn permuteCoord(coord: Coord, i: usize) Coord {
    return switch (i) {
        // +x -> +x, +y -> +y, +z -> +z
        0 => .{ .p = coord.p, .q = coord.q, .r = coord.r },
        // +x -> -z, +y -> +y, +z -> +x
        1 => .{ .p = coord.r, .q = coord.q, .r = -coord.p },
        // +x -> -x, +y -> +y, +z -> -z
        2 => .{ .p = -coord.p, .q = coord.q, .r = -coord.r },
        // +x -> +z, +y -> +y, +z -> -x
        3 => .{ .p = -coord.r, .q = coord.q, .r = coord.p },
        // +x -> +x, +y -> -y, +z -> -z
        4 => .{ .p = coord.p, .q = -coord.q, .r = -coord.r },
        // +x -> -z, +y -> -y, +z -> -x
        5 => .{ .p = -coord.r, .q = -coord.q, .r = -coord.p },
        // +x -> -x, +y -> -y, +z -> +z
        6 => .{ .p = -coord.p, .q = -coord.q, .r = coord.r },
        // +x -> +z, +y -> -y, +z -> +x
        7 => .{ .p = coord.r, .q = -coord.q, .r = coord.p },
        // +x -> +z, +y -> +x, +z -> +y
        8 => .{ .p = coord.q, .q = coord.r, .r = coord.p },
        // +x -> -y, +y -> +x, +z -> +z
        9 => .{ .p = coord.q, .q = -coord.p, .r = coord.r },
        // +x -> -z, +y -> +x, +z -> -y
        10 => .{ .p = coord.q, .q = -coord.r, .r = -coord.p },
        // +x -> +y, +y -> +x, +z -> -z
        11 => .{ .p = coord.q, .q = coord.p, .r = -coord.r },
        // +x -> +z, +y -> -x, +z -> -y
        12 => .{ .p = -coord.q, .q = -coord.r, .r = coord.p },
        // +x -> -y, +y -> -x, +z -> -z
        13 => .{ .p = -coord.q, .q = -coord.p, .r = -coord.r },
        // +x -> -z, +y -> -x, +z -> +y
        14 => .{ .p = -coord.q, .q = coord.r, .r = -coord.p },
        // +x -> +y, +y -> -x, +z -> +z
        15 => .{ .p = -coord.q, .q = coord.p, .r = coord.r },
        // +x -> +x, +y -> +z, +z -> -y
        16 => .{ .p = coord.p, .q = -coord.r, .r = coord.q },
        // +x -> +y, +y -> +z, +z -> +x
        17 => .{ .p = coord.r, .q = coord.p, .r = coord.q },
        // +x -> -x, +y -> +z, +z -> +y
        18 => .{ .p = -coord.p, .q = coord.r, .r = coord.q },
        // +x -> -y, +y -> +z, +z -> -x
        19 => .{ .p = -coord.r, .q = -coord.p, .r = coord.q },
        // +x -> +x, +y -> -z, +z -> +y
        20 => .{ .p = coord.p, .q = coord.r, .r = -coord.q },
        // +x -> +y, +y -> -z, +z -> -x
        21 => .{ .p = -coord.r, .q = coord.p, .r = -coord.q },
        // +x -> -x, +y -> -z, +z -> -y
        22 => .{ .p = -coord.p, .q = -coord.r, .r = -coord.q },
        // +x -> -y, +y -> -z, +z -> +x
        23 => .{ .p = coord.r, .q = -coord.p, .r = -coord.q },
        else => unreachable,
    };
}

test "day 19 example 1" {
    const input_ =
        \\--- scanner 0 ---
        \\0,2,0
        \\4,1,0
        \\3,3,0
        \\
        \\--- scanner 1 ---
        \\-1,-1,0
        \\-5,0,0
        \\-2,1,0
        ;

    var scanners = try parseInput(&input.readString(input_));

    const next_beacon_id = identifyBeacons(scanners.slice());

    try std.testing.expectEqual(@as(NumBeacons, 3), part1(next_beacon_id));
}

test "day 19 example 2" {
    if (builtin.mode != .Debug) {
        const input_ =
            \\--- scanner 0 ---
            \\404,-588,-901
            \\528,-643,409
            \\-838,591,734
            \\390,-675,-793
            \\-537,-823,-458
            \\-485,-357,347
            \\-345,-311,381
            \\-661,-816,-575
            \\-876,649,763
            \\-618,-824,-621
            \\553,345,-567
            \\474,580,667
            \\-447,-329,318
            \\-584,868,-557
            \\544,-627,-890
            \\564,392,-477
            \\455,729,728
            \\-892,524,684
            \\-689,845,-530
            \\423,-701,434
            \\7,-33,-71
            \\630,319,-379
            \\443,580,662
            \\-789,900,-551
            \\459,-707,401
            \\
            \\--- scanner 1 ---
            \\686,422,578
            \\605,423,415
            \\515,917,-361
            \\-336,658,858
            \\95,138,22
            \\-476,619,847
            \\-340,-569,-846
            \\567,-361,727
            \\-460,603,-452
            \\669,-402,600
            \\729,430,532
            \\-500,-761,534
            \\-322,571,750
            \\-466,-666,-811
            \\-429,-592,574
            \\-355,545,-477
            \\703,-491,-529
            \\-328,-685,520
            \\413,935,-424
            \\-391,539,-444
            \\586,-435,557
            \\-364,-763,-893
            \\807,-499,-711
            \\755,-354,-619
            \\553,889,-390
            \\
            \\--- scanner 2 ---
            \\649,640,665
            \\682,-795,504
            \\-784,533,-524
            \\-644,584,-595
            \\-588,-843,648
            \\-30,6,44
            \\-674,560,763
            \\500,723,-460
            \\609,671,-379
            \\-555,-800,653
            \\-675,-892,-343
            \\697,-426,-610
            \\578,704,681
            \\493,664,-388
            \\-671,-858,530
            \\-667,343,800
            \\571,-461,-707
            \\-138,-166,112
            \\-889,563,-600
            \\646,-828,498
            \\640,759,510
            \\-630,509,768
            \\-681,-892,-333
            \\673,-379,-804
            \\-742,-814,-386
            \\577,-820,562
            \\
            \\--- scanner 3 ---
            \\-589,542,597
            \\605,-692,669
            \\-500,565,-823
            \\-660,373,557
            \\-458,-679,-417
            \\-488,449,543
            \\-626,468,-788
            \\338,-750,-386
            \\528,-832,-391
            \\562,-778,733
            \\-938,-730,414
            \\543,643,-506
            \\-524,371,-870
            \\407,773,750
            \\-104,29,83
            \\378,-903,-323
            \\-778,-728,485
            \\426,699,580
            \\-438,-605,-362
            \\-469,-447,-387
            \\509,732,623
            \\647,635,-688
            \\-868,-804,481
            \\614,-800,639
            \\595,780,-596
            \\
            \\--- scanner 4 ---
            \\727,592,562
            \\-293,-554,779
            \\441,611,-461
            \\-714,465,-776
            \\-743,427,-804
            \\-660,-479,-426
            \\832,-632,460
            \\927,-485,-438
            \\408,393,-506
            \\466,436,-512
            \\110,16,151
            \\-258,-428,682
            \\-393,719,612
            \\-211,-452,876
            \\808,-476,-593
            \\-575,615,604
            \\-485,667,467
            \\-680,325,-822
            \\-627,-443,-432
            \\872,-547,-609
            \\833,512,582
            \\807,604,487
            \\839,-516,451
            \\891,-625,532
            \\-652,-548,-490
            \\30,-46,-14
            ;

        var scanners = try parseInput(&input.readString(input_));

        const next_beacon_id = identifyBeacons(scanners.slice());

        try std.testing.expectEqual(@as(NumBeacons, 79), part1(next_beacon_id));

        identifyScanners(scanners.slice());

        try std.testing.expectEqual(@as(Dimension, 1197 + 1175 + 1249), try part2(scanners.constSlice()));
    }
}
