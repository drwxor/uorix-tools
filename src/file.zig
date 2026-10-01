const std = @import("std");

pub const OpenedFileReader = struct {
    file: std.Io.File,
    reader: std.Io.File.Reader,

    pub fn Close(self: *OpenedFileReader, io: std.Io) void {
        self.file.close(io);
    }
};

pub fn OpenFile(io: std.Io, path: []const u8, buffer: []u8) !OpenedFileReader {
    const file = try std.Io.Dir.cwd().openFile(io, path, .{ .mode = .read_only });

    return .{
        .file = file,
        .reader = file.reader(io, buffer),
    };
}

pub fn OpenFileFromDirectory(io: std.Io, dir: std.Io.Dir, path: []const u8, buffer: []u8) !OpenedFileReader {
    const file = try dir.openFile(io, path, .{ .mode = .read_only });

    return .{
        .file = file,
        .reader = file.reader(io, buffer),
    };
}
