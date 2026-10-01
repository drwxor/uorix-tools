const std = @import("std");

const Lexer = @import("lexer.zig");
const Ast = @import("ast.zig");

pub const Parser = struct {
    lexer: Lexer.Lexer,
    currentToken: Lexer.Token,

    pub fn New(source: []const u8) !Parser {
        var lexer = Lexer.Lexer.New(source);
        const currentToken = try lexer.Next();

        return .{
            .lexer = lexer,
            .currentToken = currentToken,
        };
    }

    pub fn Parse(self: *Parser, allocator: std.mem.Allocator) !Ast.Ast {
        var ast = Ast.Ast.New(allocator);

        errdefer ast.Deinit();

        while (self.currentToken.kind != .eof) {
            if (self.currentToken.kind == .newline) {
                try self.Advance();
                continue;
            }

            const node = try self.ParseDeclaration();
            try ast.nodes.append(allocator, node);
        }

        return ast;
    }

    fn ParseDeclaration(self: *Parser) !Ast.Node {
        if (self.currentToken.kind != .identifier) {
            return error.ExpectedDeclaration;
        }

        if (std.mem.eql(u8, self.currentToken.text, "shell")) {
            return self.ParseShell();
        }

        if (std.mem.eql(u8, self.currentToken.text, "tool")) {
            return self.ParseTool();
        }

        return error.UnknownDeclaration;
    }

    fn ParseShell(self: *Parser) !Ast.Node {
        try self.Advance();

        try self.Expect(.equal);
        try self.Advance();

        const command = try self.ExpectText(.string);
        try self.Advance();

        return .{
            .shell = command,
        };
    }

    fn ParseTool(self: *Parser) !Ast.Node {
        try self.Advance();

        const name = try self.ExpectText(.identifier);
        try self.Advance();

        try self.Expect(.equal);
        try self.Advance();

        const command = try self.ExpectText(.string);
        try self.Advance();

        return .{
            .tool = .{
                .name = name,
                .command = command,
            },
        };
    }

    fn Expect(self: *Parser, kind: Lexer.TokenKind) !void {
        if (self.currentToken.kind != kind) {
            return error.UnexpectedToken;
        }
    }

    fn ExpectText(self: *Parser, kind: Lexer.TokenKind) ![]const u8 {
        if (self.currentToken.kind != kind) {
            return error.UnexpectedToken;
        }

        return self.currentToken.text;
    }

    fn Advance(self: *Parser) !void {
        self.currentToken = try self.lexer.Next();
    }
};
