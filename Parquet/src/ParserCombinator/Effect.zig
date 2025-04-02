const std = @import("std");
const mem = std.mem;
const Allocator = std.mem.Allocator;

const Base = @import("../Base.zig");
const String = Base.String;
const Analyte = @import("Analyte.zig").Analyte;
const SemanticAction = @import("Parser.zig").SemanticAction;
const Parser = @import("Parser.zig").Parser;
const Retriever = @import("Parser.zig").Retriever;


pub fn attach(parser: anytype, action: SemanticAction) type {
    return Parser(struct {
        fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            const analyte: Analyte = try Retriever.get(parser)(allocator, text);

            try action(analyte.consumed);

            return analyte;
        }
    }.anonymous);
}
