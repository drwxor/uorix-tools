const std = @import("std");

pub const Tool = struct {
    name: []const u8,
    command: []const u8,
};

pub const Node = union(enum) {
    shell: []const u8,
    tool: Tool,
};

pub const Ast = struct {
    nodes: std.ArrayList(Node),
    allocator: std.mem.Allocator,

    pub fn New(allocator: std.mem.Allocator) Ast {
        return .{
            .nodes = .empty,
            .allocator = allocator,
        };
    }

    pub fn Deinit(self: *Ast) void {
        self.nodes.deinit(self.allocator);
    }
};
