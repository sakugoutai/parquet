const std = @import("std");
const heap = std.heap;

const String = @import("ariadne").String;
const parquet = @import("parquet");
const Analyte = parquet.Analyte;
const Parser = parquet.Parser;
const Combinators = parquet.Combinators;
const Parsers = parquet.Parsers;
const Invoker = parquet.Invoker;


pub fn main() anyerror!void {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    try Invoker.parseTest(css_rgb_parser, arena.allocator(), try String.init(arena.allocator(), "#aabbcc"));
    try Invoker.parseTest(css_rgb_parser, arena.allocator(), try String.init(arena.allocator(), "#abc"));
    try Invoker.parseTest(css_rgb_parser, arena.allocator(), try String.init(arena.allocator(), "#000000"));
    try Invoker.parseTest(css_rgb_parser, arena.allocator(), try String.init(arena.allocator(), "#000"));
}

fn css_rgb_parser() type {
    return Combinators.choice2(
        css_rrggbb, css_rgb
    );
}

fn css_rrggbb() type {
    return Combinators.sequence4(
        Parsers.match("#"), rr, gg, bb
    );
}

fn css_rgb() type {
    return Combinators.sequence4(
        Parsers.match("#"), r, g, b
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
        Parsers.hexDigit, Parsers.hexDigit
    );
}

fn v() type {
    return Parsers.hexDigit();
}
