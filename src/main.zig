const std = @import("std");
const print = std.debug.print;

const File = @import("file.zig");
const Ast = @import("ast.zig");
const Args = @import("args.zig");
const Parser = @import("parser.zig");
const Project = @import("project.zig");
const Expand = @import("expand.zig");
const Log = @import("log.zig");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const allocator = init.gpa;

    var project: Project.Project = try Project.Find(io, allocator);
    defer project.Deinit(io, allocator);

    const args = try init.minimal.args.toSlice(init.arena.allocator());
    var invocations = try Args.Parse(args, allocator);
    defer invocations.deinit(allocator);

    defer {
        for (invocations.items) |*invocation| {
            invocation.Deinit();
        }
    }

    var configBuffer: [4096]u8 = undefined;
    var config = try File.OpenFileFromDirectory(io, project.dir, ".utools/config.uc", &configBuffer);
    defer config.Close(io);

    var configReader = &config.reader.interface;

    const configSource = try configReader.allocRemaining(allocator, .limited(1024 * 1024));
    defer allocator.free(configSource);

    var parser = try Parser.Parser.New(configSource);
    var ast = try parser.Parse(allocator);
    defer ast.Deinit();

    var currentShell: []const u8 = "sh";

    var tools = std.ArrayList(Ast.Tool).empty;
    defer tools.deinit(allocator);

    for (ast.nodes.items) |node| {
        switch (node) {
            .shell => |shell| {
                currentShell = shell;
            },

            .tool => |tool| {
                try tools.append(allocator, tool);
            },
        }
    }

    print("shell is {s}\n", .{currentShell});
    for (tools.items) |tool| {
        print("{s} runs \"{s}\"\n", .{ tool.name, tool.command });
    }

    InvocationLoop: for (invocations.items) |invocation| {
        var found = false;

        for (tools.items) |tool| {
            if (!std.mem.eql(u8, tool.name, invocation.tool)) {
                continue;
            }

            found = true;

            var expandError: ?Expand.ExpandError = null;

            const command = Expand.Expand(allocator, project, tool.command, &invocation, &expandError) catch |err| {
                switch (err) {
                    error.UnknownExpansion => {
                        const info = expandError.?;

                        Log.Errorf("unknown expansion '@({s})'", .{info.expression});

                        Log.Errorf("tool '{s}'", .{tool.name});
                        print("\t|\n", .{});
                        print("\t| {s}\n", .{tool.command});

                        print("\t| ", .{});

                        var i: usize = 0;
                        while (i < info.position) : (i += 1) {
                            print(" ", .{});
                        }

                        var j: usize = 0;
                        while (j < info.expression.len + 3) : (j += 1) {
                            print("^", .{});
                        }

                        print("\n", .{});
                    },

                    else => {
                        Log.Errorf("{s}", .{@errorName(err)});
                    },
                }

                continue :InvocationLoop;
            };

            defer allocator.free(command);

            const result = try std.process.run(allocator, io, .{
                .argv = &.{ currentShell, "-c", command },
            });

            defer allocator.free(result.stdout);
            defer allocator.free(result.stderr);

            print("{s}", .{result.stdout});
            print("{s}", .{result.stderr});

            break;
        }

        if (!found) {
            Log.Errorf("unknown tool '{s}'", .{invocation.tool});
        }
    }
}
