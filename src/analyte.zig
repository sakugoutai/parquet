const std = @import("std");
const mem = std.mem;

const ariadne = @import("ariadne");


/// Transfer Data between Parsing Functions which Combinated
pub const Analyte = struct {

    // Allocator
    allocator: mem.Allocator,

    // Answer of the Parsing
    answer: Answer,

    // Parsed Text
    parsed: ariadne.String,

    // Subsequent Text
    subsequent: ariadne.String,


    pub const Answer = enum {
        ok,
        err,
    };

    pub fn deinit(self: Analyte) void {
        self.parsed.deinit();
        self.subsequent.deinit();
    }

    // Utilities of Returning Analyte
    pub fn ok(allocator: mem.Allocator, text: ariadne.String) mem.Allocator.Error!Analyte {
        return Analyte {
            .allocator = allocator,
            .answer = Answer.ok,
            .parsed = try ariadne.String.init(allocator, ""),
            .subsequent = try text.dup(),
        };
    }

    pub fn err(allocator: mem.Allocator, text: ariadne.String) mem.Allocator.Error!Analyte {
        return Analyte {
            .allocator = allocator,
            .answer = Answer.err,
            .parsed = try ariadne.String.init(allocator, ""),
            .subsequent = try text.dup(),
        };
    }

    pub fn consumed(parsed: ariadne.String, allocator: mem.Allocator, text: ariadne.String) (mem.Allocator.Error || ariadne.String.Error)!Analyte {
        return Analyte {
            .allocator = allocator,
            .answer = Answer.ok,
            .parsed = try parsed.dup(),
            .subsequent = try text.substring(parsed.length(), text.length()),
        };
    }

    pub fn merge(self: *Analyte, next: Analyte) mem.Allocator.Error!void {
        self.answer = next.answer;
        try self.parsed.append(next.parsed);
        self.subsequent.deinit();
        self.subsequent = try next.subsequent.dup();
    }

};
