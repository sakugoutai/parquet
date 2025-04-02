const std = @import("std");
const heap = std.heap;
const io = std.io;
const mem = std.mem;
const Allocator = mem.Allocator;

const Parquet = @import("Parquet.zig");
const String = Parquet.Base.String;
const Analyte = Parquet.ParserCombinator.Analyte;
const Parser = Parquet.ParserCombinator.Parser;
const Retriever = Parquet.ParserCombinator.Retriever;
const Combinators = Parquet.ParserCombinator.Combinators;
const Parsers = Parquet.ParserCombinator.Parsers;
const Effect = Parquet.ParserCombinator.Effect;
const Invoker = Parquet.ParserCombinator.Invoker;


pub fn main() anyerror!void {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    try Invoker.parseTest(css_rgb_parser, arena.allocator(), try String.init(arena.allocator(), "#aabbcc"));
    var rgb = try RGBBuilder.get();
    try io.getStdOut().writer().print("R: {s}, G: {s}, B: {s}\n\n", .{ rgb.r.getPrimitive(), rgb.g.getPrimitive(), rgb.b.getPrimitive() });

    try Invoker.parseTest(css_rgb_parser, arena.allocator(), try String.init(arena.allocator(), "#abc"));
    rgb = try RGBBuilder.get();
    try io.getStdOut().writer().print("R: {s}, G: {s}, B: {s}\n\n", .{ rgb.r.getPrimitive(), rgb.g.getPrimitive(), rgb.b.getPrimitive() });

    try Invoker.parseTest(css_rgb_parser, arena.allocator(), try String.init(arena.allocator(), "#000000"));
    rgb = try RGBBuilder.get();
    try io.getStdOut().writer().print("R: {s}, G: {s}, B: {s}\n\n", .{ rgb.r.getPrimitive(), rgb.g.getPrimitive(), rgb.b.getPrimitive() });

    try Invoker.parseTest(css_rgb_parser, arena.allocator(), try String.init(arena.allocator(), "#000"));
    rgb = try RGBBuilder.get();
    try io.getStdOut().writer().print("R: {s}, G: {s}, B: {s}\n\n", .{ rgb.r.getPrimitive(), rgb.g.getPrimitive(), rgb.b.getPrimitive() });
}

fn css_rgb_parser() type {
    return Combinators.choice(.{
        css_rrggbb, css_rgb
    });
}

fn css_rrggbb() type {
    return Combinators.sequence(.{
        Parsers.match("#"), rr().attach(RGBBuilder.setR), gg().attach(RGBBuilder.setG), bb().attach(RGBBuilder.setB)
    });
}

fn css_rgb() type {
    return Combinators.sequence4(
        Parsers.match("#"), Effect.attach(r, RGBBuilder.setR), Effect.attach(g, RGBBuilder.setG), Effect.attach(b, RGBBuilder.setB)
    );
}

fn rr() type {
    return vv();
}

fn gg() type {
    return vv();
}

fn bb() type {
    return vv();
}

fn r() type {
    return v();
}

fn g() type {
    return v();
}

fn b() type {
    return v();
}

fn vv() type {
    return Combinators.sequence2(
        Parsers.hexadecimalDigit, Parsers.hexadecimalDigit
    );
}

fn v() type {
    return Parsers.hexadecimalDigit();
}

const RGB = struct {
    r: String,
    g: String,
    b: String,
};

const RGBBuilder = struct {

    var r: String = undefined;
    var g: String = undefined;
    var b: String = undefined;

    pub fn setR(consumed: String) anyerror!void {
        RGBBuilder.r = try String.initCopy(consumed);
    }

    pub fn setG(consumed: String) anyerror!void {
        RGBBuilder.g = try String.initCopy(consumed);
    }

    pub fn setB(consumed: String) anyerror!void {
        RGBBuilder.b = try String.initCopy(consumed);
    }

    pub fn get() anyerror!RGB {
        return RGB {
            .r = try String.initCopy(RGBBuilder.r),
            .g = try String.initCopy(RGBBuilder.g),
            .b = try String.initCopy(RGBBuilder.b),
        };
    }

};
