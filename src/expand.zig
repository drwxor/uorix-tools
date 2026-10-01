const std = @import("std");

const Args = @import("args.zig");
const Project = @import("project.zig");

pub const ExpandError = struct {
    expression: []const u8,
    position: usize,
};

pub fn Expand(allocator: std.mem.Allocator, project: Project.Project, command: []const u8, invocation: *const Args.Invocation, errorInfo: *?ExpandError) ![]u8 {
    var result = std.ArrayList(u8).empty;
    errdefer result.deinit(allocator);

    var index: usize = 0;

    while (index < command.len) {
        if (command[index] == '@' and index + 1 < command.len and command[index + 1] == '(') {
            const end = std.mem.indexOfScalar(u8, command[index + 2 ..], ')') orelse {
                return error.UnclosedArgument;
            };

            const expression = command[index + 2 .. index + 2 + end];

            const separator = std.mem.indexOfScalar(u8, expression, '|');

            const name = if (separator) |i|
                expression[0..i]
            else
                expression;

            var value: []const u8 = undefined;

            if (std.mem.eql(u8, name, "root")) {
                value = project.path;
            } else {
                const defaultValue = if (separator) |i|
                    expression[i + 1 ..]
                else
                    "";

                value = invocation.args.get(name) orelse defaultValue;
            }

            if (value.len == 0) {
                errorInfo.* = .{
                    .expression = expression,
                    .position = index,
                };

                return error.UnknownExpansion;
            }

            try result.appendSlice(allocator, value);

            index += end + 3;
        } else {
            try result.append(allocator, command[index]);
            index += 1;
        }
    }

    return result.toOwnedSlice(allocator);
}
