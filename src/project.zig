const std = @import("std");

pub const Project = struct {
    dir: std.Io.Dir,
    path: []const u8,

    pub fn Deinit(self: *Project, io: std.Io, allocator: std.mem.Allocator) void {
        self.dir.close(io);
        allocator.free(self.path);
    }
};

pub fn Find(io: std.Io, allocator: std.mem.Allocator) !Project {
    const pathBuffer = try std.process.currentPathAlloc(io, allocator);
    defer allocator.free(pathBuffer);

    var path: []const u8 = pathBuffer;

    while (true) {
        const utoolsPath = try std.Io.Dir.path.join(
            allocator,
            &.{ path, ".utools" },
        );
        defer allocator.free(utoolsPath);

        std.Io.Dir.accessAbsolute(io, utoolsPath, .{}) catch |err| switch (err) {
            error.FileNotFound => {
                const parent = std.Io.Dir.path.dirname(path) orelse {
                    return error.ProjectNotFound;
                };

                if (std.mem.eql(u8, parent, path)) {
                    return error.ProjectNotFound;
                }

                path = parent;
                continue;
            },

            else => return err,
        };

        return .{
            .dir = try std.Io.Dir.openDirAbsolute(io, path, .{}),
            .path = try allocator.dupe(u8, path),
        };
    }
}
