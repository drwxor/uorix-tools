const std = @import("std");

pub const Invocation = struct {
    tool: []const u8,
    args: std.StringHashMap([]const u8),

    pub fn Deinit(self: *Invocation) void {
        self.args.deinit();
    }
};

pub fn Parse(argv: []const [:0]const u8, allocator: std.mem.Allocator) !std.ArrayList(Invocation) {
    var invocations = std.ArrayList(Invocation).empty;
    errdefer {
        for (invocations.items) |*invocation| {
            invocation.Deinit();
        }
        invocations.deinit(allocator);
    }

    var index: usize = 1;

    while (index < argv.len) : (index += 1) {
        const argument = argv[index];

        if (argument.len < 2 or argument[0] != '-') {
            return error.InvalidArgument;
        }

        const value = argument[1..];

        var tool: []const u8 = undefined;
        var rawArgs: []const u8 = "";

        if (std.mem.indexOfScalar(u8, value, '=')) |equalIndex| {
            tool = value[0..equalIndex];
            rawArgs = value[equalIndex + 1 ..];
        } else {
            tool = value;
        }

        if (tool.len == 0) {
            return error.EmptyTool;
        }

        var invocation = Invocation{
            .tool = tool,
            .args = std.StringHashMap([]const u8).init(allocator),
        };

        errdefer invocation.Deinit();

        if (rawArgs.len != 0) {
            var iterator = std.mem.splitScalar(u8, rawArgs, ',');

            while (iterator.next()) |pair| {
                const colonIndex = std.mem.indexOfScalar(u8, pair, ':') orelse {
                    return error.InvalidToolArgument;
                };

                const name = pair[0..colonIndex];
                const argValue = pair[colonIndex + 1 ..];

                if (name.len == 0) {
                    return error.EmptyArgumentName;
                }

                try invocation.args.put(name, argValue);
            }
        }

        try invocations.append(allocator, invocation);
    }

    return invocations;
}
