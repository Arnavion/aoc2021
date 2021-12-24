const std = @import("std");

const Digit = std.math.IntFittingRange(0, 9);

pub fn evaluate(inputs: [14]Digit) i64 {
    var w: i64 = 0;
    _ = w;
    var x: i64 = 0;
    _ = x;
    var y: i64 = 0;
    _ = y;
    var z: i64 = 0;
    _ = z;

    y = inputs[0];
    y += 12;
    z = y;
    z *= 26;
    y = inputs[1];
    y += 10;
    z += y;
    z *= 26;
    y = inputs[2];
    y += 8;
    z += y;
    z *= 26;
    y = inputs[3];
    y += 4;
    z += y;
    x = z;
    x = @mod(x, 26);
    z = @divTrunc(z, 26);
    x = @boolToInt(x != inputs[4]);
    y = 25;
    y *= x;
    y += 1;
    z *= y;
    y = inputs[4];
    y += 3;
    y *= x;
    z += y;
    z *= 26;
    y = inputs[5];
    y += 10;
    z += y;
    z *= 26;
    y = inputs[6];
    y += 6;
    z += y;
    x = z;
    x = @mod(x, 26);
    z = @divTrunc(z, 26);
    x += -12;
    x = @boolToInt(x != inputs[7]);
    y = 25;
    y *= x;
    y += 1;
    z *= y;
    y = inputs[7];
    y += 13;
    y *= x;
    z += y;
    x = z;
    x = @mod(x, 26);
    z = @divTrunc(z, 26);
    x += -15;
    x = @boolToInt(x != inputs[8]);
    y = 25;
    y *= x;
    y += 1;
    z *= y;
    y = inputs[8];
    y += 8;
    y *= x;
    z += y;
    x = z;
    x = @mod(x, 26);
    z = @divTrunc(z, 26);
    x += -15;
    x = @boolToInt(x != inputs[9]);
    y = 25;
    y *= x;
    y += 1;
    z *= y;
    y = inputs[9];
    y += 1;
    y *= x;
    z += y;
    x = z;
    x = @mod(x, 26);
    z = @divTrunc(z, 26);
    x += -4;
    x = @boolToInt(x != inputs[10]);
    y = 25;
    y *= x;
    y += 1;
    z *= y;
    y = inputs[10];
    y += 7;
    y *= x;
    z += y;
    z *= 26;
    y = inputs[11];
    y += 6;
    z += y;
    x = z;
    x = @mod(x, 26);
    z = @divTrunc(z, 26);
    x += -5;
    x = @boolToInt(x != inputs[12]);
    y = 25;
    y *= x;
    y += 1;
    z *= y;
    y = inputs[12];
    y += 9;
    y *= x;
    z += y;
    x = z;
    x = @mod(x, 26);
    z = @divTrunc(z, 26);
    x += -12;
    x = @boolToInt(x != inputs[13]);
    y = 25;
    y *= x;
    y += 1;
    z *= y;
    y = inputs[13];
    y += 9;
    y *= x;
    z += y;

    return z;
}

pub fn evaluate2(digits: [9]Digit) [14]Digit {
    for (digits) |d0| {
        const y0: i64 = d0;
        const y1 = y0 + 12;
        const z0 = y1;
        const z1 = z0 * 26;
        for (digits) |d1| {
            const y2: i64 = d1;
            const y3 = y2 + 10;
            const z2 = z1 + y3;
            const z3 = z2 * 26;
            for (digits) |d2| {
                const y4: i64 = d2;
                const y5 = y4 + 8;
                const z4 = z3 + y5;
                const z5 = z4 * 26;
                for (digits) |d3| {
                    const y6: i64 = d3;
                    const y7 = y6 + 4;
                    const z6 = z5 + y7;
                    const x0 = z6;
                    const x1 = @mod(x0, 26);
                    const z7 = @divTrunc(z6, 26);
                    for (digits) |d4| {
                        const x2: i64 = @boolToInt(x1 != d4);
                        const y8 = 25;
                        const y9 = y8 * x2;
                        const y10 = y9 + 1;
                        const z8 = z7 * y10;
                        const y11: i64 = d4;
                        const y12 = y11 + 3;
                        const y13 = y12 * x2;
                        const z9 = z8 + y13;
                        const z10 = z9 * 26;
                        for (digits) |d5| {
                            const y14: i64 = d5;
                            const y15 = y14 + 10;
                            const z11 = z10 + y15;
                            const z12 = z11 * 26;
                            for (digits) |d6| {
                                const y16: i64 = d6;
                                const y17 = y16 + 6;
                                const z13 = z12 + y17;
                                const x3 = z13;
                                const x4 = @mod(x3, 26);
                                const z14 = @divTrunc(z13, 26);
                                const x5 = x4 + -12;
                                for (digits) |d7| {
                                    const x6: i64 = @boolToInt(x5 != d7);
                                    const y18 = 25;
                                    const y19 = y18 * x6;
                                    const y20 = y19 + 1;
                                    const z15 = z14 * y20;
                                    const y21: i64 = d7;
                                    const y22 = y21 + 13;
                                    const y23 = y22 * x6;
                                    const z16 = z15 + y23;
                                    const x7 = z16;
                                    const x8 = @mod(x7, 26);
                                    const z17 = @divTrunc(z16, 26);
                                    const x9 = x8 + -15;
                                    for (digits) |d8| {
                                        const x10: i64 = @boolToInt(x9 != d8);
                                        const y24 = 25;
                                        const y25 = y24 * x10;
                                        const y26 = y25 + 1;
                                        const z18 = z17 * y26;
                                        const y27: i64 = d8;
                                        const y28 = y27 + 8;
                                        const y29 = y28 * x10;
                                        const z19 = z18 + y29;
                                        const x11 = z19;
                                        const x12 = @mod(x11, 26);
                                        const z20 = @divTrunc(z19, 26);
                                        const x13 = x12 + -15;
                                        for (digits) |d9| {
                                            const x14: i64 = @boolToInt(x13 != d9);
                                            const y30 = 25;
                                            const y31 = y30 * x14;
                                            const y32 = y31 + 1;
                                            const z21 = z20 * y32;
                                            const y33: i64 = d9;
                                            const y34 = y33 + 1;
                                            const y35 = y34 * x14;
                                            const z22 = z21 + y35;
                                            const x15 = z22;
                                            const x16 = @mod(x15, 26);
                                            const z23 = @divTrunc(z22, 26);
                                            const x17 = x16 + -4;
                                            for (digits) |d10| {
                                                const x18: i64 = @boolToInt(x17 != d10);
                                                const y36 = 25;
                                                const y37 = y36 * x18;
                                                const y38 = y37 + 1;
                                                const z24 = z23 * y38;
                                                const y39: i64 = d10;
                                                const y40 = y39 + 7;
                                                const y41 = y40 * x18;
                                                const z25 = z24 + y41;
                                                const z26 = z25 * 26;
                                                for (digits) |d11| {
                                                    const y42: i64 = d11;
                                                    const y43 = y42 + 6;
                                                    const z27 = z26 + y43;
                                                    const x19 = z27;
                                                    const x20 = @mod(x19, 26);
                                                    const z28 = @divTrunc(z27, 26);
                                                    const x21 = x20 + -5;
                                                    for (digits) |d12| {
                                                        const x22: i64 = @boolToInt(x21 != d12);
                                                        const y44 = 25;
                                                        const y45 = y44 * x22;
                                                        const y46 = y45 + 1;
                                                        const z29 = z28 * y46;
                                                        const y47: i64 = d12;
                                                        const y48 = y47 + 9;
                                                        const y49 = y48 * x22;
                                                        const z30 = z29 + y49;
                                                        const x23 = z30;
                                                        const x24 = @mod(x23, 26);
                                                        const z31 = @divTrunc(z30, 26);
                                                        const x25 = x24 + -12;
                                                        for (digits) |d13| {
                                                            const x26: i64 = @boolToInt(x25 != d13);
                                                            const y50 = 25;
                                                            const y51 = y50 * x26;
                                                            const y52 = y51 + 1;
                                                            const z32 = z31 * y52;
                                                            const y53: i64 = d13;
                                                            const y54 = y53 + 9;
                                                            const y55 = y54 * x26;
                                                            const z33 = z32 + y55;

                                                            if (z33 == 0) {
                                                                return [_]Digit { d0, d1, d2, d3, d4, d5, d6, d7, d8, d9, d10, d11, d12, d13 };
                                                            }
                                                            else if (d5 == 1 and d6 == 1 and d7 == 1 and d8 == 1 and d9 == 1 and d10 == 1 and d11 == 1 and d12 == 1 and d13 == 1) {
                                                                const inputs = [_]Digit { d0, d1, d2, d3, d4, d5, d6, d7, d8, d9, d10, d11, d12, d13 };
                                                                std.debug.print("??? {any}\n", .{ inputs });
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    else unreachable;
}
