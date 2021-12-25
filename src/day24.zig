const builtin = @import("builtin");
const std = @import("std");

const day24_compiled = @import("day24_compiled.zig");
const input = @import("input.zig");

pub fn run(stdout: anytype) anyerror!void {
    if (builtin.mode == .Debug) {
        var program = std.BoundedArray(Op, 252).init(0) catch unreachable;
        {
            var input_ = try input.readFile("inputs/day24");
            defer input_.deinit();

            var input_i: usize = 0;
            while (try input_.next()) |line| {
                try program.append(try Op.init(line, &input_i));
            }
        }

        simplify(&program);

        const file = try std.fs.cwd().createFile("src/day24_compiled.zig", .{});
        defer file.close();
        const writer = file.writer();

        try writer.print("const std = @import(\"std\");\n\n", .{});
        try writer.print("const Digit = std.math.IntFittingRange(0, 9);\n\n", .{});

        try compileProgram(program.constSlice(), writer);

        try writer.print("\n", .{});

        try compileProgram2(program.constSlice(), writer);
    }

    {
        const result = part1();
        try stdout.print("24a: {}\n", .{ result });
        std.debug.assert(result == 93959993429899);
    }

    {
        const result = part2();
        try stdout.print("24b: {}\n", .{ result });
        std.debug.assert(result == 11815671117121);
    }
}

const Digit = std.math.IntFittingRange(0, 9);
const Answer = std.math.IntFittingRange(11111111111111, 99999999999999);

fn part1() Answer {
    var result_digits: [14]Digit = undefined;
    if (builtin.mode == .Debug) {
        result_digits = [_]Digit { 9, 3, 9, 5, 9, 9, 9, 3, 4, 2, 9, 8, 9, 9 };
        const z = day24_compiled.evaluate(result_digits);
        std.debug.assert(z == 0);
    }
    else {
        result_digits = day24_compiled.evaluate2(.{ 9, 8, 7, 6, 5, 4, 3, 2, 1 }) catch unreachable;
    }

    var result: Answer = 0;
    for (result_digits) |result_digit| {
        result = result * 10 + result_digit;
    }
    return result;
}

fn part2() Answer {
    var result_digits: [14]Digit = undefined;
    if (builtin.mode == .Debug) {
        result_digits = [_]Digit { 1, 1, 8, 1, 5, 6, 7, 1, 1, 1, 7, 1, 2, 1 };
        const z = day24_compiled.evaluate(result_digits);
        std.debug.assert(z == 0);
    }
    else {
        result_digits = day24_compiled.evaluate2(.{ 1, 2, 3, 4, 5, 6, 7, 8, 9 }) catch unreachable;
    }

    var result: Answer = 0;
    for (result_digits) |result_digit| {
        result = result * 10 + result_digit;
    }
    return result;
}

const Op = struct {
    code: OpCode,
    lhs: Reg,
    rhs: Rhs,

    fn init(line: []const u8, input_i: *usize) !@This() {
        var parts = std.mem.tokenize(u8, line, " ");

        const op_s = parts.next() orelse return error.InvalidInput;

        const lhs_s = parts.next() orelse return error.InvalidInput;
        const lhs = try Reg.init(lhs_s);

        if (std.mem.eql(u8, op_s, "inp")) {
            const result = Op {
                .code = .set,
                .lhs = lhs,
                .rhs = .{ .inp = input_i.* },
            };
            input_i.* += 1;
            return result;
        }
        else {
            const code = try OpCode.init(op_s);
            const rhs_s = parts.next() orelse return error.InvalidInput;
            const rhs = try Rhs.init(rhs_s);
            return Op {
                .code = code,
                .lhs = lhs,
                .rhs = rhs,
            };
        }
    }
};

const OpCode = enum {
    add,
    mul,
    div,
    mod,
    eql,
    neq,
    set,

    fn init(op_s: []const u8) !@This() {
        if (std.mem.eql(u8, op_s, "add")) {
            return OpCode.add;
        }
        else if (std.mem.eql(u8, op_s, "mul")) {
            return OpCode.mul;
        }
        else if (std.mem.eql(u8, op_s, "div")) {
            return OpCode.div;
        }
        else if (std.mem.eql(u8, op_s, "mod")) {
            return OpCode.mod;
        }
        else if (std.mem.eql(u8, op_s, "eql")) {
            return OpCode.eql;
        }
        else {
            return error.InvalidInput;
        }
    }
};

const OpInp = struct {
    lhs: Reg,
    rhs: usize,
};

const OpBin = struct {
    lhs: Reg,
    rhs: Rhs,
};

const Reg = enum {
    w,
    x,
    y,
    z,

    fn init(arg: []const u8) !@This() {
        if (arg.len != 1) {
            return error.InvalidInput;
        }

        return switch (arg[0]) {
            'w' => .w,
            'x' => .x,
            'y' => .y,
            'z' => .z,
            else => error.InvalidInput,
        };
    }
};

const Rhs = union (enum) {
    reg: Reg,
    inp: usize,
    constant: i64,

    fn init(arg: []const u8) !@This() {
        return
            if (Reg.init(arg) catch null) |reg| .{ .reg = reg }
            else .{ .constant = try std.fmt.parseInt(i64, arg, 10) };
    }
};

const Value = union (enum) {
    constant: i64,
    inp: usize,
    unknown: ValueRange,

    fn asConstant(self: @This()) ?i64 {
        return switch (self) {
            .constant => |constant| constant,
            else => null,
        };
    }

    fn range(self: @This()) ValueRange {
        return switch (self) {
            .constant => |constant| .{ .min = constant, .max = constant },
            .inp => .{ .min = 1, .max = 9 },
            .unknown => |unknown| unknown,
        };
    }
};

const ValueRange = struct {
    min: i64,
    max: i64,
};

fn evalValue(variables: *const [4]Value, rhs: Rhs) Value {
    return switch (rhs) {
        .reg => |reg| switch (reg) {
            .w => variables[0],
            .x => variables[1],
            .y => variables[2],
            .z => variables[3],
        },
        .inp => |inp| .{ .inp = inp },
        .constant => |constant| .{ .constant = constant },
    };
}

fn setValue(variables: *[4]Value, reg: Reg, value: Value) void {
    switch (reg) {
        .w => variables[0] = value,
        .x => variables[1] = value,
        .y => variables[2] = value,
        .z => variables[3] = value,
    }
}

fn simplify(program: *std.BoundedArray(Op, 252)) void {
    loop: while (true) {
        var variables = [_]Value { .{ .constant = 0 } } ** 4;

        for (program.slice()) |*op, i| {
            const evaled_rhs = evalValue(&variables, op.rhs);
            {
                const new_rhs = switch (evaled_rhs) {
                    .constant => |constant_rhs| switch (op.rhs) {
                        .constant => |constant|
                            if (constant != constant_rhs) Rhs { .constant = constant_rhs }
                            else null,
                        else => Rhs { .constant = constant_rhs },
                    },
                    .inp => |inp_rhs| switch (op.rhs) {
                        .inp => |inp|
                            if (inp != inp_rhs) Rhs { .inp = inp_rhs }
                            else null,
                        else => Rhs { .inp = inp_rhs },
                    },
                    .unknown => null,
                };
                if (new_rhs) |new_rhs_| {
                    op.* = .{
                        .code = op.code,
                        .lhs = op.lhs,
                        .rhs = new_rhs_,
                    };
                    continue :loop;
                }
            }
            const evaled_rhs_range = evaled_rhs.range();

            const evaled_lhs = evalValue(&variables, .{ .reg = op.lhs });
            const evaled_lhs_range = evaled_lhs.range();

            var new_min: ?i64 = null;
            var new_max: ?i64 = null;

            switch (op.code) {
                .add => {
                    if (evaled_lhs.asConstant()) |constant_lhs| {
                        if (constant_lhs == 0) {
                            // a = 0 => add a b -> set a b
                            op.* = .{
                                .code = .set,
                                .lhs = op.lhs,
                                .rhs = op.rhs,
                            };
                            continue :loop;
                        }
                    }

                    if (evaled_rhs.asConstant()) |constant_rhs| {
                        if (constant_rhs == 0) {
                            // add a 0 -> X
                            _ = program.orderedRemove(i);
                            continue :loop;
                        }

                        if (evaled_lhs.asConstant()) |constant_lhs| {
                            // a = M => add a N -> set a (M + N)
                            op.* = .{
                                .code = .set,
                                .lhs = op.lhs,
                                .rhs = .{ .constant = constant_lhs + constant_rhs },
                            };
                            continue :loop;
                        }
                    }

                    new_min = evaled_lhs_range.min +| evaled_rhs_range.min;
                    new_max = evaled_lhs_range.max +| evaled_rhs_range.max;
                },

                .mul => {
                    if (evaled_lhs.asConstant()) |constant_lhs| {
                        if (constant_lhs == 0) {
                            // a = 0 => mul a b -> X
                            _ = program.orderedRemove(i);
                            continue :loop;
                        }

                        if (constant_lhs == 1) {
                            // a = 1 => mul a b -> set a b
                            op.* = .{
                                .code = .set,
                                .lhs = op.lhs,
                                .rhs = op.rhs,
                            };
                            continue :loop;
                        }
                    }

                    if (evaled_rhs.asConstant()) |constant_rhs| {
                        if (constant_rhs == 0) {
                            // mul a 0 -> set a 0
                            op.* = .{
                                .code = .set,
                                .lhs = op.lhs,
                                .rhs = .{ .constant = 0 },
                            };
                            continue :loop;
                        }

                        if (constant_rhs == 1) {
                            // mul a 1 -> X
                            _ = program.orderedRemove(i);
                            continue :loop;
                        }

                        if (evaled_lhs.asConstant()) |constant_lhs| {
                            // a = M => mul a N -> set a (M * N)
                            op.* = .{
                                .code = .set,
                                .lhs = op.lhs,
                                .rhs = .{ .constant = constant_lhs * constant_rhs },
                            };
                            continue :loop;
                        }
                    }

                    new_min =
                        std.math.min(
                            std.math.min(evaled_lhs_range.min *| evaled_rhs_range.min, evaled_lhs_range.max *| evaled_rhs_range.max),
                            std.math.min(evaled_lhs_range.min *| evaled_rhs_range.max, evaled_lhs_range.max *| evaled_rhs_range.min),
                        );
                    new_max =
                        std.math.max(
                            std.math.max(evaled_lhs_range.min *| evaled_rhs_range.min, evaled_lhs_range.max *| evaled_rhs_range.max),
                            std.math.max(evaled_lhs_range.min *| evaled_rhs_range.max, evaled_lhs_range.max *| evaled_rhs_range.min),
                        );
                },

                .div => {
                    if (evaled_lhs.asConstant()) |constant_lhs| {
                        if (constant_lhs == 0) {
                            // a = 0 => div a N -> X
                            _ = program.orderedRemove(i);
                            continue :loop;
                        }
                    }

                    if (evaled_rhs.asConstant()) |constant_rhs| {
                        if (constant_rhs == 1) {
                            // div a 1 -> X
                            _ = program.orderedRemove(i);
                            continue :loop;
                        }

                        if (evaled_lhs.asConstant()) |constant_lhs| {
                            // a = M => div a N -> set a (M / N)
                            op.* = .{
                                .code = .set,
                                .lhs = op.lhs,
                                .rhs = .{ .constant = @divTrunc(constant_lhs, constant_rhs) },
                            };
                            continue :loop;
                        }
                    }

                    new_min =
                        std.math.min(
                            std.math.min(@divTrunc(evaled_lhs_range.min, evaled_rhs_range.min), @divTrunc(evaled_lhs_range.max, evaled_rhs_range.max)),
                            std.math.min(@divTrunc(evaled_lhs_range.min, evaled_rhs_range.max), @divTrunc(evaled_lhs_range.max, evaled_rhs_range.min)),
                        );
                    new_max =
                        std.math.max(
                            std.math.max(@divTrunc(evaled_lhs_range.min, evaled_rhs_range.min), @divTrunc(evaled_lhs_range.max, evaled_rhs_range.max)),
                            std.math.max(@divTrunc(evaled_lhs_range.min, evaled_rhs_range.max), @divTrunc(evaled_lhs_range.max, evaled_rhs_range.min)),
                        );
                },

                .mod => {
                    if (evaled_lhs.asConstant()) |constant_lhs| {
                        if (constant_lhs == 0) {
                            // a = 0 => mod a N -> X
                            _ = program.orderedRemove(i);
                            continue :loop;
                        }
                    }

                    if (evaled_rhs.asConstant()) |constant_rhs| {
                        std.debug.assert(constant_rhs > 0);
                        if (evaled_lhs.asConstant()) |constant_lhs| {
                            // a = M => mod a N -> set a (M % N)
                            op.* = .{
                                .code = .set,
                                .lhs = op.lhs,
                                .rhs = .{ .constant = @mod(constant_lhs, constant_rhs) },
                            };
                            continue :loop;
                        }

                        if (evaled_lhs_range.min >= 0 and evaled_lhs_range.min < constant_rhs and evaled_lhs_range.max >= 0 and evaled_lhs_range.max < constant_rhs) {
                            new_min = evaled_lhs_range.min;
                            new_max = evaled_lhs_range.max;
                        }
                        else {
                            new_min = 0;
                            new_max = constant_rhs - 1;
                        }
                    }
                },

                .eql => {
                    if (i < program.len) {
                        const next_op = program.constSlice()[i + 1];
                        switch (next_op.code) {
                            .eql => {
                                if (evalValue(&variables, next_op.rhs).asConstant()) |constant_rhs| {
                                    if (constant_rhs == 0) {
                                        // eql a b; eql a 0 -> neq a b
                                        op.* = .{
                                            .code = .neq,
                                            .lhs = op.lhs,
                                            .rhs = op.rhs,
                                        };
                                        _ = program.orderedRemove(i + 1);
                                        continue :loop;
                                    }
                                }
                            },

                            else => {},
                        }
                    }

                    if (evaled_lhs_range.max < evaled_rhs_range.min or evaled_rhs_range.max < evaled_lhs_range.min) {
                        // a and b are disjoint => eql a b -> set a 0
                        op.* = .{
                            .code = .set,
                            .lhs = op.lhs,
                            .rhs = .{ .constant = 0 },
                        };
                        continue :loop;
                    }

                    new_min = 0;
                    new_max = 1;
                },

                .neq => {
                    if (evaled_lhs_range.max < evaled_rhs_range.min or evaled_rhs_range.max < evaled_lhs_range.min) {
                        // a and b are disjoint => neq a b -> set a 1
                        op.* = .{
                            .code = .set,
                            .lhs = op.lhs,
                            .rhs = .{ .constant = 1 },
                        };
                        continue :loop;
                    }

                    new_min = 0;
                    new_max = 1;
                },

                .set => {
                    if (i > 0) {
                        // ... does not use a => a = b; ...; set a N -> set a N
                        var j = i - 1;
                        while (true) : (j -= 1) {
                            const prev_op = program.constSlice()[j];
                            if (prev_op.lhs == op.lhs) {
                                _ = program.orderedRemove(j);
                                continue :loop;
                            }
                            switch (prev_op.rhs) {
                                .reg => |reg| {
                                    if (reg == op.lhs) {
                                        break;
                                    }
                                },

                                else => {},
                            }

                            if (j == 0) {
                                break;
                            }
                        }
                    }

                    // ... does not use a => set a N; ...; $ -> ...; $
                    for (program.constSlice()[(i + 1)..]) |next_op| {
                        switch (next_op.rhs) {
                            .reg => |reg| if (reg == op.lhs) {
                                break;
                            },
                            else => {},
                        }
                    }
                    else {
                        _ = program.orderedRemove(i);
                        continue :loop;
                    }

                    if (evaled_rhs.asConstant()) |constant_rhs| {
                        if (evaled_lhs.asConstant()) |constant_lhs| {
                            // a = N => set a N -> X
                            if (constant_lhs == constant_rhs) {
                                _ = program.orderedRemove(i);
                                continue :loop;
                            }
                        }
                    }
                },
            }

            if (op.code == .set) {
                setValue(&variables, op.lhs, evaled_rhs);
            }
            else {
                const new_min_ = new_min.?;
                const new_max_ = new_max.?;
                std.debug.assert(new_min_ < new_max_);
                setValue(&variables, op.lhs, .{ .unknown = .{ .min = new_min_, .max = new_max_ } });
            }
        }

        break;
    }
}

fn compileProgram(program: []const Op, writer: anytype) !void {
    try writer.print(
        \\pub fn evaluate(inputs: [14]Digit) i64 {{
        \\    var w: i64 = 0;
        \\    _ = w;
        \\    var x: i64 = 0;
        \\    _ = x;
        \\    var y: i64 = 0;
        \\    _ = y;
        \\    var z: i64 = 0;
        \\    _ = z;
        \\
        \\
        ,
        .{},
    );

    for (program) |op| {
        try writer.print("    ", .{});
        try printOp(op, writer);
    }

    try writer.print(
        \\
        \\    return z;
        \\}}
        \\
        ,
        .{},
    );
}

fn printOp(op: Op, writer: anytype) !void {
    try printReg(op.lhs, writer);

    switch (op.code) {
        .add => {
            try writer.print(" += ", .{});
            try printRhs(op.rhs, writer);
        },

        .mul => {
            try writer.print(" *= ", .{});
            try printRhs(op.rhs, writer);
        },

        .div => {
            try writer.print(" = @divTrunc(", .{});
            try printReg(op.lhs, writer);
            try writer.print(", ", .{});
            try printRhs(op.rhs, writer);
            try writer.print(")", .{});
        },

        .mod => {
            try writer.print(" = @mod(", .{});
            try printReg(op.lhs, writer);
            try writer.print(", ", .{});
            try printRhs(op.rhs, writer);
            try writer.print(")", .{});
        },

        .eql => {
            try writer.print(" = @boolToInt(", .{});
            try printReg(op.lhs, writer);
            try writer.print(" == ", .{});
            try printRhs(op.rhs, writer);
            try writer.print(")", .{});
        },

        .neq => {
            try writer.print(" = @boolToInt(", .{});
            try printReg(op.lhs, writer);
            try writer.print(" != ", .{});
            try printRhs(op.rhs, writer);
            try writer.print(")", .{});
        },

        .set => {
            try writer.print(" = ", .{});
            try printRhs(op.rhs, writer);
        },
    }
    try writer.print(";\n", .{});
}

fn printReg(reg: Reg, writer: anytype) !void {
    switch (reg) {
        .w => try writer.print("w", .{}),
        .x => try writer.print("x", .{}),
        .y => try writer.print("y", .{}),
        .z => try writer.print("z", .{}),
    }
}

fn printRhs(rhs: Rhs, writer: anytype) !void {
    switch (rhs) {
        .reg => |reg| try printReg(reg, writer),
        .inp => |inp| try printInp(inp, writer),
        .constant => |constant| try writer.print("{}", .{ constant }),
    }
}

fn printInp(inp: usize, writer: anytype) !void {
    try writer.print("inputs[{}]", .{ inp });
}

fn compileProgram2(program: []const Op, writer: anytype) !void {
    var depths = [_]usize { 0 } ** 4;

    try writer.print(
        \\pub fn evaluate2(digits: [9]Digit) [14]Digit {{
        \\
        ,
        .{},
    );

    var next_inp: usize = 0;

    for (program) |op| {
        try printOp2(op, writer, &depths, &next_inp);
    }

    try writer.print("\n", .{});
    try indent(next_inp, writer);
    try writer.print("if (", .{});
    try printReg2(.z, writer, &depths, .input);
    try writer.print(" == 0) {{\n", .{});
    try indent(next_inp, writer);
    try writer.print("    return [_]Digit {{ d0, d1, d2, d3, d4, d5, d6, d7, d8, d9, d10, d11, d12, d13 }};\n", .{});
    try indent(next_inp, writer);
    try writer.print("}}\n", .{});
    try indent(next_inp, writer);
    try writer.print("else if (d5 == 1 and d6 == 1 and d7 == 1 and d8 == 1 and d9 == 1 and d10 == 1 and d11 == 1 and d12 == 1 and d13 == 1) {{\n", .{});
    try indent(next_inp, writer);
    try writer.print("    const inputs = [_]Digit {{ d0, d1, d2, d3, d4, d5, d6, d7, d8, d9, d10, d11, d12, d13 }};\n", .{});
    try indent(next_inp, writer);
    try writer.print("    std.debug.print(\"??? {{any}}\\n\", .{{ inputs }});\n", .{});
    try indent(next_inp, writer);
    try writer.print("}}\n", .{});

    while (next_inp >= 1) {
        next_inp -= 1;
        try indent(next_inp, writer);
        try writer.print("}}\n", .{});
    }

    try indent(next_inp, writer);
    try writer.print("else unreachable;\n}}\n", .{});
}

fn printOp2(op: Op, writer: anytype, depths: *[4]usize, next_inp: *usize) !void {
    try indent(next_inp.*, writer);

    switch (op.code) {
        .add => {
            var new_depths = depths.*;
            try writer.print("const ", .{});
            try printReg2(op.lhs, writer, &new_depths, .output);
            try writer.print(" = ", .{});
            try printReg2(op.lhs, writer, depths, .input);
            try writer.print(" + ", .{});
            try printRhs2(op.rhs, writer, depths);
            try writer.print(";\n", .{});
            depths.* = new_depths;
        },

        .mul => {
            var new_depths = depths.*;
            try writer.print("const ", .{});
            try printReg2(op.lhs, writer, &new_depths, .output);
            try writer.print(" = ", .{});
            try printReg2(op.lhs, writer, depths, .input);
            try writer.print(" * ", .{});
            try printRhs2(op.rhs, writer, depths);
            try writer.print(";\n", .{});
            depths.* = new_depths;
        },

        .div => {
            var new_depths = depths.*;
            try writer.print("const ", .{});
            try printReg2(op.lhs, writer, &new_depths, .output);
            try writer.print(" = @divTrunc(", .{});
            try printReg2(op.lhs, writer, depths, .input);
            try writer.print(", ", .{});
            try printRhs2(op.rhs, writer, depths);
            try writer.print(");\n", .{});
            depths.* = new_depths;
        },

        .mod => {
            var new_depths = depths.*;
            try writer.print("const ", .{});
            try printReg2(op.lhs, writer, &new_depths, .output);
            try writer.print(" = @mod(", .{});
            try printReg2(op.lhs, writer, depths, .input);
            try writer.print(", ", .{});
            try printRhs2(op.rhs, writer, depths);
            try writer.print(");\n", .{});
            depths.* = new_depths;
        },

        .eql => {
            var new_depths = depths.*;
            try writer.print("const ", .{});
            try printReg2(op.lhs, writer, &new_depths, .output);
            try writer.print(": i64 = @boolToInt(", .{});
            try printReg2(op.lhs, writer, depths, .input);
            try writer.print(" == ", .{});
            try printRhs2(op.rhs, writer, depths);
            try writer.print(");\n", .{});
            depths.* = new_depths;
        },

        .neq => switch (op.rhs) {
            .inp => |inp| {
                if (inp == next_inp.*) {
                    try writer.print("for (digits) |", .{});
                    try printInp2(inp, writer);
                    try writer.print("| {{\n", .{});
                    try indent(next_inp.*, writer);
                    try writer.print("    ", .{});
                    next_inp.* += 1;
                }

                var new_depths = depths.*;
                try writer.print("const ", .{});
                try printReg2(op.lhs, writer, &new_depths, .output);
                try writer.print(": i64 = @boolToInt(", .{});
                try printReg2(op.lhs, writer, depths, .input);
                try writer.print(" != ", .{});
                try printRhs2(op.rhs, writer, depths);
                try writer.print(");\n", .{});
                depths.* = new_depths;
            },
            else => {
                var new_depths = depths.*;
                try writer.print("const ", .{});
                try printReg2(op.lhs, writer, &new_depths, .output);
                try writer.print(": i64 = if (", .{});
                try printReg2(op.lhs, writer, depths, .input);
                try writer.print(" == ", .{});
                try printRhs2(op.rhs, writer, depths);
                try writer.print(") 0 else 1;\n", .{});
                depths.* = new_depths;
            },
        },

        .set => switch (op.rhs) {
            .inp => |inp| {
                if (inp == next_inp.*) {
                    try writer.print("for (digits) |", .{});
                    try printInp2(inp, writer);
                    try writer.print("| {{\n", .{});
                    try indent(next_inp.*, writer);
                    try writer.print("    ", .{});
                    next_inp.* += 1;
                }

                var new_depths = depths.*;
                try writer.print("const ", .{});
                try printReg2(op.lhs, writer, &new_depths, .output);
                try writer.print(": i64 = ", .{});
                try printRhs2(op.rhs, writer, depths);
                try writer.print(";\n", .{});
                depths.* = new_depths;
            },
            else => {
                var new_depths = depths.*;
                try writer.print("const ", .{});
                try printReg2(op.lhs, writer, &new_depths, .output);
                try writer.print(" = ", .{});
                try printRhs2(op.rhs, writer, depths);
                try writer.print(";\n", .{});
                depths.* = new_depths;
            },
        },
    }
}

const PrintReg2Options = enum {
    input,
    output,
};

fn printReg2(reg: Reg, writer: anytype, depths: *[4]usize, options: PrintReg2Options) !void {
    const current_depth = switch (reg) {
        .w => &depths[0],
        .x => &depths[1],
        .y => &depths[2],
        .z => &depths[3],
    };

    switch (options) {
        .input => {},
        .output => {
            current_depth.* += 1;
        },
    }

    switch (reg) {
        .w => try writer.print("w{}", .{ current_depth.* - 1 }),
        .x => try writer.print("x{}", .{ current_depth.* - 1 }),
        .y => try writer.print("y{}", .{ current_depth.* - 1 }),
        .z => try writer.print("z{}", .{ current_depth.* - 1 }),
    }
}

fn printRhs2(rhs: Rhs, writer: anytype, depths: *[4]usize) !void {
    switch (rhs) {
        .reg => |reg| try printReg2(reg, writer, depths, .input),
        .inp => |inp| try printInp2(inp, writer),
        .constant => |constant| try writer.print("{}", .{ constant }),
    }
}

fn printInp2(inp: usize, writer: anytype) !void {
    try writer.print("d{}", .{ inp });
}

fn indent(next_inp: usize, writer: anytype) !void {
    var i: usize = 0;
    while (i <= next_inp) : (i += 1) {
        try writer.print("    ", .{});
    }
}
