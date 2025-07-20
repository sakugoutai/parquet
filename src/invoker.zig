const std = @import("std");
const io = std.io;
const mem = std.mem;

const ariadne = @import("ariadne");
const Analyte = @import("analyte.zig").Analyte;
const ParsingFunction = @import("parser.zig").ParsingFunction;
const SemanticAction = @import("parser.zig").SemanticAction;
const Parser = @import("parser.zig").Parser;
const extractParsingFunction = @import("parser.zig").extractParsingFunction;
const Combinators = @import("combinators.zig");


pub fn parse(parser: anytype, allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
    return try extractParsingFunction(parser)(allocator, text);
}

pub fn parseTest(parser: anytype, allocator: mem.Allocator, text: ariadne.String) anyerror!void {
    const analyte: Analyte = try parse(parser, allocator, text);
    if (analyte.answer == Analyte.Answer.err) {
        try io.getStdOut().writer().writeAll("Invoker.parserTest: parse failed.\n");
        return;
    }

    if (!analyte.subsequent.empty()) {
        try io.getStdOut().writer().writeAll("Invoker.parserTest: parse incorrect.\n");
        try io.getStdOut().writer().print("\"{s}\" [{s}]\n", .{
            analyte.parsed.text,
            analyte.subsequent.text
        });
        return;
    }

    try io.getStdOut().writer().print("\"{s}\"\n", .{
        analyte.parsed.text
    });
}
