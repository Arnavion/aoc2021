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
}

test "sub-tests" {
    std.testing.refAllDecls(@This());
}
