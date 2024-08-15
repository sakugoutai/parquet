const std = @import("std");
const Allocator = std.mem.Allocator;

const Base = @import("../Base.zig");
const String = Base.String;


/// Transfer Data between Parsing Functions which Combinated
pub const Analyte = struct {

    // Allocator for #deinit
    allocator: Allocator,

    // Answer of the Parsing
    answer: Answer,

    // Parsed Text
    consumed: String,

    // Subsequent Text
    subsequent: String,


    pub const Answer = enum { ok, err };

    // Utilities of Returning Analyte
    pub fn initWithOk(allocator: Allocator, text: String) Allocator.Error!Analyte {
        return Analyte {
            .allocator = allocator,

            .answer = Answer.ok,

            .consumed = try String.init(allocator, ""),
            .subsequent = try String.initFromString(allocator, text),
        };
    }

    pub fn initWithErr(allocator: Allocator, text: String) Allocator.Error!Analyte {
        return Analyte {
            .allocator = allocator,

            .answer = Answer.err,

            .consumed = try String.init(allocator, ""),
            .subsequent = try String.initFromString(allocator, text),
        };
    }

    pub fn initWithConsumed(consumed: String, allocator: Allocator, text: String) (Allocator.Error || String.Error)!Analyte {
        const subsequent: String = try text.substring(consumed.getLength(), text.getLength());
        defer subsequent.deinit();

        return Analyte {
            .allocator = allocator,

            .answer = Answer.ok,

            .consumed = try String.initFromString(allocator, consumed),
            .subsequent = try String.initFromString(allocator, subsequent),
        };
    }

    pub fn initWithConsumedChar(allocator: Allocator, text: String) (Allocator.Error || String.Error)!Analyte {
        const consumed: String = try text.substring(0, 1);
        defer consumed.deinit();

        return initWithConsumed(consumed, allocator, text);
    }

    pub fn initWithAbsorb(self: Analyte, next: Analyte) Allocator.Error!Analyte {
        return Analyte {
            .allocator = next.allocator,

            .answer = next.answer,

            .consumed = try self.consumed.initWithSuffixString(next.consumed),
            .subsequent = try next.subsequent.initCopy(),
        };
    }

    pub fn deinit(self: Analyte) void {
        self.consumed.deinit();
        self.subsequent.deinit();
    }
};
