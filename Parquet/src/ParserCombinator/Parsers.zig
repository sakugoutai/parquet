const std = @import("std");
const mem = std.mem;
const Allocator = std.mem.Allocator;

const Base = @import("../Base.zig");
const String = Base.String;
const Analyte = @import("Analyte.zig").Analyte;
const Combinators = @import("Combinators.zig");
const Parser = @import("Parser.zig").Parser;
const Retriever = @import("Parser.zig").Retriever;


pub fn through() type {
    return Parser(struct {
        fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            return Analyte.initWithOk(allocator, text);
        }
    }.anonymous);
}

pub fn fail() type {
    return Parser(struct {
        fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            return Analyte.initWithErr(allocator, text);
        }
    }.anonymous);
}

pub fn match(pattern: []const u8) type {
    return Parser(struct {
        fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            const pattern_string: String = try String.init(allocator, pattern);
            defer pattern_string.deinit();

            if (text.isEmpty())
                return try Analyte.initWithErr(allocator, text);

            if (!text.startsWith(pattern_string))
                return try Analyte.initWithErr(allocator, text);

            return try Analyte.initWithConsumed(pattern_string, allocator, text);
        }
    }.anonymous);
}

pub fn unMatch(pattern: []const u8) type {
    return Parser(struct {
        fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            const pattern_string: String = try String.init(allocator, pattern);
            defer pattern_string.deinit();

            if (text.isEmpty())
                return try Analyte.initWithErr(allocator, text);

            if (text.startsWith(pattern_string))
                return try Analyte.initWithErr(allocator, text);

            return try Analyte.initWithConsumed(try text.substring(allocator, 0, 1), allocator, text);
        }
    }.anonymous);
}

pub fn oneOf(patterns: []const []const u8) type {
    return Parser(struct {
        fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            for (patterns) |pattern| {
                if (pattern.len > text.getLength())
                    continue;

                const pattern_string: String = try String.init(allocator, pattern);
                defer pattern_string.deinit();

                if (text.startsWith(pattern_string)) {
                    return try Analyte.initWithConsumed(pattern_string, allocator, text);
                }
            }

            return try Analyte.initWithErr(allocator, text);
        }
    }.anonymous);
}

pub fn noneOf(patterns: []const []const u8) type {
    return Parser(struct {
        fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            for (patterns) |pattern| {
                if (pattern.len > text.getLength())
                    continue;

                const pattern_string: String = try String.init(allocator, pattern);
                defer pattern_string.deinit();

                if (text.startsWith(pattern_string))
                    return try Analyte.initWithErr(allocator, text);
            }

            const tmp: String = try text.substring(allocator, 0, 1);
            defer tmp.deinit();
            return try Analyte.initWithConsumed(tmp, allocator, text);
        }
    }.anonymous);
}


fn isUpperCase(c: u8) bool {
    return 'A' <= c and c <= 'Z';
}

pub fn upper() type {
    return Parser(struct {
        fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            if (text.isEmpty())
                return try Analyte.initWithErr(allocator, text);

            if (!isUpperCase(try text.getHeadChar()))
                return try Analyte.initWithErr(allocator, text);

            return try Analyte.initWithConsumedChar(allocator, text);
        }
    }.anonymous);
}

fn isLowerCase(c: u8) bool {
    return 'a' <= c and c <= 'z';
}

pub fn lower() type {
    return Parser(struct {
        pub fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            if (text.isEmpty())
                return try Analyte.initWithErr(allocator, text);

            if (!isLowerCase(try text.getHeadChar()))
                return try Analyte.initWithErr(allocator, text);

            return try Analyte.initWithConsumedChar(allocator, text);
        }
    }.anonymous);
}

fn isAlphabet(c: u8) bool {
    return isUpperCase(c) or isLowerCase(c);
}

pub fn letter() type {
    return Parser(struct {
        pub fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            if (!isAlphabet(try text.getHeadChar()))
                return try Analyte.initWithErr(allocator, text);

            return try Analyte.initWithConsumedChar(allocator, text);
        }
    }.anonymous);
}

fn isDigit(c: u8) bool {
    return '0' <= c and c <= '9';
}

pub fn digit() type {
    return Parser(struct {
        pub fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            if (text.isEmpty())
                return try Analyte.initWithErr(allocator, text);

            if (!isDigit(try text.getHeadChar()))
                return try Analyte.initWithErr(allocator, text);

            return try Analyte.initWithConsumedChar(allocator, text);
        }
    }.anonymous);
}

fn isAlphabetOrNumber(c: u8) bool {
    return isAlphabet(c) or isDigit(c);
}

pub fn alphabetOrNumber() type {
    return Parser(struct {
        pub fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            if (text.isEmpty())
                return try Analyte.initWithErr(allocator, text);

            if (!isAlphabetOrNumber(try text.getHeadChar()))
                return try Analyte.initWithErr(allocator, text);

            return try Analyte.initWithConsumedChar(allocator, text);
        }
    }.anonymous);
}

fn alphabetOrNumbers() type {
    return Combinators.many1(alphabetOrNumber());
}

fn isHexadecimalDigit(c: u8) bool {
    return isDigit(c) or ('A' <= c and c <= 'F') or ('a' <= c and c <= 'f');
}

pub fn hexadecimalDigit() type {
    return Parser(struct {
        pub fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            if (text.isEmpty())
                return try Analyte.initWithErr(allocator, text);

            if (!isHexadecimalDigit(try text.getHeadChar()))
                return try Analyte.initWithErr(allocator, text);

            return try Analyte.initWithConsumedChar(allocator, text);
        }
    }.anonymous);
}

fn isOctalDigit(c: u8) bool {
    return '0' <= c and c <= '7';
}

pub fn octalDigit() type {
    return Parser(struct {
        pub fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            if (text.isEmpty())
                return try Analyte.initWithErr(allocator, text);

            if (!isOctalDigit(try text.getHeadChar()))
                return try Analyte.initWithErr(allocator, text);

            return try Analyte.initWithConsumedChar(allocator, text);
        }
    }.anonymous);
}

pub fn any() type {
    return Parser(struct {
        pub fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            if (text.isEmpty())
                return try Analyte.initWithErr(allocator, text);

            return try Analyte.initWithConsumedChar(allocator, text);
        }
    }.anonymous);
}

pub fn satisfy(judger: fn (String) bool) type {
    return Parser(struct {
        pub fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            if (text.isEmpty())
                return try Analyte.initWithErr(allocator, text);

            if (!judger(text))
                return try Analyte.initWithErr(allocator, text);

            return try Analyte.initWithConsumedChar(allocator, text);
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

pub fn endOfLine() type {
    return Combinators.choice2(
        lf(), crlf()
    );
}

pub fn separator() type {
    return Combinators.choice3(
        space(), tab(), endOfLine()
    );
}

pub fn separators0() type {
    return Combinators.many0(separator());
}

pub fn separators1() type {
    return Combinators.many0(separator());
}
