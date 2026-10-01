const std = @import("std");

pub fn Error(message: []const u8) void {
    std.debug.print("\x1b[1;31mutools: error:\x1b[0m {s}\n", .{message});
}

pub fn Errorf(comptime format: []const u8, args: anytype) void {
    std.debug.print("\x1b[1;31mutools: error:\x1b[0m " ++ format ++ "\n", args);
}

pub fn Warn(message: []const u8) void {
    std.debug.print("\x1b[1;33mutools: warning:\x1b[0m {s}\n", .{message});
}

pub fn Warnf(comptime format: []const u8, args: anytype) void {
    std.debug.print("\x1b[1;33mutools: warning:\x1b[0m " ++ format ++ "\n", args);
}

pub fn Info(message: []const u8) void {
    std.debug.print("\x1b[1;36mutools:\x1b[0m {s}\n", .{message});
}

pub fn Infof(comptime format: []const u8, args: anytype) void {
    std.debug.print("\x1b[1;36mutools:\x1b[0m " ++ format ++ "\n", args);
}
