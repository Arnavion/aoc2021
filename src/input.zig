const std = @import("std");

pub fn readFile(path: []const u8) !ReaderIterator {
    const file = try std.fs.cwd().openFile(path, .{});
    const reader = file.reader();
    // TODO: Can't return .{ ... } because of https://github.com/ziglang/zig/issues/3662
    return ReaderIterator {
        .file = file,
        .reader = std.io.bufferedReader(reader),
    };
}

pub const ReaderIterator = struct {
    file: std.fs.File,
    reader: std.io.BufferedReader(4096, std.fs.File.Reader),
    buf: [4096]u8 = undefined,

    pub fn next(self: *@This()) !?[]const u8 {
        return try self.reader.reader().readUntilDelimiterOrEof(&self.buf, '\n');
    }

    pub fn deinit(self: @This()) void {
        self.file.close();
    }
};

pub fn readString(s: []const u8) StringIterator {
    return .{
        .inner = std.mem.split(u8, s, "\n"),
    };
}

pub const StringIterator = struct {
    inner: std.mem.SplitIterator(u8),

    pub fn next(self: *@This()) !?[]const u8 {
        return self.inner.next();
    }
};
