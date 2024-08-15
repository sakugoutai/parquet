const std = @import("std");
const heap = std.heap;
const io = std.io;

const Parquet = @import("Parquet.zig");
const String = Parquet.Base.String;
const Analyte = Parquet.ParserCombinator.Analyte;
const Parser = Parquet.ParserCombinator.Parser;
const Combinators = Parquet.ParserCombinator.Combinators;
const Collector = Parquet.ParserCombinator.Collector;
const Parsers = Parquet.ParserCombinator.Parsers;
const Invoker = Parquet.ParserCombinator.Invoker;


pub fn main() anyerror!void {
    //var gpa = heap.GeneralPurposeAllocator(.{}){};
    //defer _ = gpa.deinit();
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    const text_1: String = try String.init(arena.allocator(), "#aabbcc");
    defer text_1.deinit();
    Collector.init(arena.allocator());
    try Invoker.parseTest(rgb, arena.allocator(), text_1);
    for (Collector.get()) |token| {
        try io.getStdOut().writer().print("{s}\n", .{ token.getPrimitive() });
    }
    Collector.deinit();

    const text_2: String = try String.init(arena.allocator(), "#abc");
    defer text_2.deinit();
    Collector.init(arena.allocator());
    try Invoker.parseTest(rgb, arena.allocator(), text_2);
    for (Collector.get()) |token| {
        try io.getStdOut().writer().print("{s}\n", .{ token.getPrimitive() });
    }
    Collector.deinit();

    const text_3: String = try String.init(arena.allocator(), "#000000");
    defer text_3.deinit();
    Collector.init(arena.allocator());
    try Invoker.parseTest(rgb, arena.allocator(), text_3);
    for (Collector.get()) |token| {
        try io.getStdOut().writer().print("{s}\n", .{ token.getPrimitive() });
    }
    Collector.deinit();

    const text_4: String = try String.init(arena.allocator(), "#000");
    defer text_4.deinit();
    Collector.init(arena.allocator());
    try Invoker.parseTest(rgb, arena.allocator(), text_4);
    for (Collector.get()) |token| {
        try io.getStdOut().writer().print("{s}\n", .{ token.getPrimitive() });
    }
    Collector.deinit();
}

fn rgb() type {
    return Combinators.choice2(
        css_rrggbb, css_rgb
    );
}

fn css_rrggbb() type {
    return Combinators.sequence4(
        Parsers.match("#"), Collector.this(rr), Collector.this(gg), Collector.this(bb)
    );
}

fn css_rgb() type {
    return Combinators.sequence5(
        Parsers.match("#"), Collector.backtrack(3), Collector.this(r), Collector.this(g), Collector.this(b)
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
