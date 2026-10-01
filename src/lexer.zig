const std = @import("std");

pub const TokenKind = enum {
    identifier,
    string,
    equal,
    newline,
    eof,
};

pub const Token = struct {
    kind: TokenKind,
    text: []const u8,
    line: usize,
    column: usize,
};

pub const Lexer = struct {
    source: []const u8,
    position: usize = 0,
    line: usize = 1,
    column: usize = 1,

    pub fn New(source: []const u8) Lexer {
        return .{
            .source = source,
        };
    }

    pub fn Next(self: *Lexer) !Token {
        while (true) {
            if (self.position >= self.source.len) {
                return .{
                    .kind = .eof,
                    .text = "",
                    .line = self.line,
                    .column = self.column,
                };
            }

            const char = self.source[self.position];

            switch (char) {
                ' ', '\t', '\r' => {
                    self.Advance();
                },

                '#' => {
                    while (self.position < self.source.len and self.source[self.position] != '\n') {
                        self.Advance();
                    }
                },

                '\n' => {
                    const token = Token{
                        .kind = .newline,
                        .text = self.source[self.position .. self.position + 1],
                        .line = self.line,
                        .column = self.column,
                    };

                    self.Advance();

                    return token;
                },

                '=' => {
                    const token = Token{
                        .kind = .equal,
                        .text = self.source[self.position .. self.position + 1],
                        .line = self.line,
                        .column = self.column,
                    };

                    self.Advance();

                    return token;
                },

                '"' => return self.ReadString(),

                else => return self.ReadIdentifier(),
            }
        }
    }

    fn ReadIdentifier(self: *Lexer) !Token {
        const start = self.position;
        const line = self.line;
        const column = self.column;

        while (self.position < self.source.len) {
            const char = self.source[self.position];

            if (char == ' ' or
                char == '\t' or
                char == '\r' or
                char == '\n' or
                char == '=' or
                char == '"' or
                char == '#')
            {
                break;
            }

            self.Advance();
        }

        if (start == self.position) {
            return error.InvalidCharacter;
        }

        return .{
            .kind = .identifier,
            .text = self.source[start..self.position],
            .line = line,
            .column = column,
        };
    }

    fn ReadString(self: *Lexer) !Token {
        const quote_position = self.position;
        _ = quote_position;

        const line = self.line;
        const column = self.column;

        self.Advance();

        const start = self.position;

        while (self.position < self.source.len) {
            const char = self.source[self.position];

            if (char == '"') {
                const text = self.source[start..self.position];
                self.Advance();

                return .{
                    .kind = .string,
                    .text = text,
                    .line = line,
                    .column = column,
                };
            }

            if (char == '\n') {
                return error.UnterminatedString;
            }

            self.Advance();
        }

        return error.UnterminatedString;
    }

    fn Advance(self: *Lexer) void {
        if (self.position >= self.source.len) {
            return;
        }

        if (self.source[self.position] == '\n') {
            self.line += 1;
            self.column = 1;
        } else {
            self.column += 1;
        }

        self.position += 1;
    }
};
