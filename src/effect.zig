const std = @import("std");
const mem = std.mem;

const ariadne = @import("ariadne");
const Analyte = @import("analyte.zig").Analyte;
const ParsingFunction = @import("parser.zig").ParsingFunction;
const SemanticAction = @import("parser.zig").SemanticAction;
const Parser = @import("parser.zig").Parser;
const extractParsingFunction = @import("parser.zig").extractParsingFunction;
const Combinators = @import("combinators.zig");


pub fn attach(parser: anytype, action: SemanticAction) type {
    return Parser(struct {
        fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            const analyte = try extractParsingFunction(parser)(allocator, text);
            try action(analyte.parsed);
            return analyte;
        }
    }.anonymous);
}
