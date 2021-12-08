const std = @import("std");

pub fn main() anyerror!void {
    var allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = allocator.deinit();
        if (leaked) {
            @panic("memory leaked");
        }
    }

    const stdout = std.io.getStdOut().writer();

    try @import("day1.zig").run(&stdout);
    try @import("day2.zig").run(&stdout);
    try @import("day3.zig").run(&allocator.allocator, &stdout);
    try @import("day4.zig").run(&allocator.allocator, &stdout);
    try @import("day5.zig").run(&stdout);
    try @import("day6.zig").run(&stdout);
    try @import("day7.zig").run(&stdout);
    try @import("day8.zig").run(&stdout);
}

test "sub-tests" {
    std.testing.refAllDecls(@This());
}
