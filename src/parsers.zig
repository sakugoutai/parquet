const std = @import("std");
const mem = std.mem;

const ariadne = @import("ariadne");
const Analyte = @import("analyte.zig").Analyte;
const ParsingFunction = @import("parser.zig").ParsingFunction;
const Parser = @import("parser.zig").Parser;
const Combinators = @import("combinators.zig");


pub fn through() type {
    return Parser(struct {
        fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            return Analyte.ok(allocator, text);
        }
    }.anonymous);
}

pub fn fail() type {
    return Parser(struct {
        fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            return Analyte.err(allocator, text);
        }
    }.anonymous);
}

pub fn match(pattern: []const u8) type {
    return Parser(struct {
        fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            const pattern_string = try ariadne.String.init(allocator, pattern);
            defer pattern_string.deinit();

            if (text.empty())
                return try Analyte.err(allocator, text);

            if (!text.starts(pattern_string))
                return try Analyte.err(allocator, text);

            return try Analyte.consumed(pattern_string, allocator, text);
        }
    }.anonymous);
}

pub fn notMatch(pattern: []const u8) type {
    return Parser(struct {
        fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            const pattern_string = try ariadne.String.init(allocator, pattern);
            defer pattern_string.deinit();

            if (text.empty())
                return try Analyte.err(allocator, text);

            if (text.starts(pattern_string))
                return try Analyte.err(allocator, text);

            return try Analyte.consumed(try text.substring(0, 1), allocator, text);
        }
    }.anonymous);
}

pub fn oneOf(patterns: []const []const u8) type {
    return Parser(struct {
        fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            for (patterns) |pattern| {
                if (pattern.len > text.getLength())
                    continue;

                const pattern_string = try ariadne.String.init(allocator, pattern);
                defer pattern_string.deinit();

                if (text.startsWith(pattern_string)) {
                    return try Analyte.consumed(pattern_string, allocator, text);
                }
            }

            return try Analyte.err(allocator, text);
        }
    }.anonymous);
}

pub fn noneOf(patterns: []const []const u8) type {
    return Parser(struct {
        fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            for (patterns) |pattern| {
                if (pattern.len > text.length())
                    continue;

                const pattern_string = try ariadne.String.init(allocator, pattern);
                defer pattern_string.deinit();

                if (text.starts(pattern_string))
                    return try Analyte.err(allocator, text);
            }

            const tmp: ariadne.String = try text.substring(0, 1);
            defer tmp.deinit();
            return try Analyte.consumed(tmp, allocator, text);
        }
    }.anonymous);
}


fn upperCase(c: u8) bool {
    return 'A' <= c and c <= 'Z';
}

pub fn upper() type {
    return Parser(struct {
        fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            if (text.empty())
                return try Analyte.err(allocator, text);

            if (!upperCase(try text.charAt(0)))
                return try Analyte.err(allocator, text);

            const s = ariadne.String.char(try text.charAt(0));
            defer s.deinit();

            return try Analyte.consumed(s, allocator, text);
        }
    }.anonymous);
}

fn lowerCase(c: u8) bool {
    return 'a' <= c and c <= 'z';
}

pub fn lower() type {
    return Parser(struct {
        pub fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            if (text.empty())
                return try Analyte.err(allocator, text);

            if (!lowerCase(try text.charAt(0)))
                return try Analyte.err(allocator, text);

            const s = ariadne.String.char(try text.charAt(0));
            defer s.deinit();

            return try Analyte.consumed(s, allocator, text);
        }
    }.anonymous);
}

fn alphabet(c: u8) bool {
    return upperCase(c) or lowerCase(c);
}

pub fn letter() type {
    return Parser(struct {
        pub fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            if (!alphabet(try text.charAt(0)))
                return try Analyte.err(allocator, text);

            const s = ariadne.String.char(try text.charAt(0));
            defer s.deinit();

            return try Analyte.consumed(s, allocator, text);
        }
    }.anonymous);
}

fn digit_(c: u8) bool {
    return '0' <= c and c <= '9';
}

pub fn digit() type {
    return Parser(struct {
        pub fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            if (text.empty())
                return try Analyte.err(allocator, text);

            if (!digit_(try text.charAt(0)))
                return try Analyte.err(allocator, text);

            const s = ariadne.String.char(try text.charAt(0));
            defer s.deinit();

            return try Analyte.consumed(s, allocator, text);
        }
    }.anonymous);
}

fn alphabetOrNumber_(c: u8) bool {
    return alphabet(c) or digit_(c);
}

pub fn alphabetOrNumber() type {
    return Parser(struct {
        pub fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            if (text.empty())
                return try Analyte.err(allocator, text);

            if (!alphabetOrNumber_(try text.charAt(0)))
                return try Analyte.err(allocator, text);

            const s = ariadne.String.char(try text.charAt(0));
            defer s.deinit();

            return try Analyte.consumed(s, allocator, text);
        }
    }.anonymous);
}

fn alphabetOrNumbers() type {
    return Combinators.many1(alphabetOrNumber());
}

fn hexDigit_(c: u8) bool {
    return digit_(c) or ('A' <= c and c <= 'F') or ('a' <= c and c <= 'f');
}

pub fn hexDigit() type {
    return Parser(struct {
        pub fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            if (text.empty())
                return try Analyte.err(allocator, text);

            if (!hexDigit_(try text.charAt(0)))
                return try Analyte.err(allocator, text);

            const s = try ariadne.String.char(allocator, try text.charAt(0));
            defer s.deinit();

            return try Analyte.consumed(s, allocator, text);
        }
    }.anonymous);
}

fn octDigit_(c: u8) bool {
    return '0' <= c and c <= '7';
}

pub fn octDigit() type {
    return Parser(struct {
        pub fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            if (text.empty())
                return try Analyte.err(allocator, text);

            if (!octDigit_(try text.charAt(0)))
                return try Analyte.err(allocator, text);

            const s = ariadne.String.char(try text.charAt(0));
            defer s.deinit();

            return try Analyte.consumed(s, allocator, text);
        }
    }.anonymous);
}

pub fn any() type {
    return Parser(struct {
        pub fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            if (text.empty())
                return try Analyte.err(allocator, text);

            const s = ariadne.String.char(try text.charAt(0));
            defer s.deinit();

            return try Analyte.consumed(s, allocator, text);
        }
    }.anonymous);
}

pub fn satisfy(judger: fn (ariadne.String) bool) type {
    return Parser(struct {
        pub fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            if (text.empty())
                return try Analyte.err(allocator, text);

            if (!judger(text))
                return try Analyte.err(allocator, text);

            const s = ariadne.String.char(try text.charAt(0));
            defer s.deinit();

            return try Analyte.consumed(s, allocator, text);
        }
    }.anonymous);
}

pub fn space() type {
    return match(" ");
}

pub fn spaces0() type {
    return Combinators.many0(space());
}

pub fn spaces1() type {
    return Combinators.many1(space());
}

pub fn tab() type {
    return match("\t");
}

pub fn lf() type {
    return match("\n");
}

pub fn crlf() type {
    return match("\r\n");
}

pub fn eol() type {
    return Combinators.choice2(
        lf(), crlf()
    );
}

pub fn sep() type {
    return Combinators.choice3(
        space(), tab(), eol()
    );
}

pub fn seps0() type {
    return Combinators.many0(sep());
}

pub fn seps1() type {
    return Combinators.many0(sep());
}
