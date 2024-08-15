const std = @import("std");
const io = std.io;
const Allocator = std.mem.Allocator;

const Base = @import("../Base.zig");
const String = Base.String;
const Analyte = @import("Analyte.zig").Analyte;
const Retriever = @import("Parser.zig").Retriever;


pub fn parse(parser: anytype, allocator: Allocator, text: String) anyerror!Analyte {
    return try Retriever.get(parser)(allocator, text);
}

pub fn parseTest(parser: anytype, allocator: Allocator, text: String) anyerror!void {
    const analyte: Analyte = try parse(parser, allocator, text);
    if (analyte.answer == Analyte.Answer.err) {
        try io.getStdOut().writer().writeAll("Invoker.parserTest: parse failed.\n");
        return;
    }

    if (!analyte.subsequent.isEmpty()) {
        try io.getStdOut().writer().writeAll("Invoker.parserTest: parse incorrect.\n");
        try io.getStdOut().writer().print("\"{s}\" [{s}]\n", .{
            analyte.consumed.getPrimitive(),
            analyte.subsequent.getPrimitive()
        });
        return;
    }

    try io.getStdOut().writer().print("\"{s}\"\n", .{
        analyte.consumed.getPrimitive()
    });
}
