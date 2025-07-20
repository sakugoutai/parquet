const std = @import("std");
const heap = std.heap;
const io = std.io;

const String = @import("ariadne").String;
const parquet = @import("parquet");
const Analyte = parquet.Analyte;
const Parser = parquet.Parser;
const Combinators = parquet.Combinators;
const Parsers = parquet.Parsers;
const Effect = parquet.Effect;
const Invoker = parquet.Invoker;


pub fn main() anyerror!void {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    try Invoker.parseTest(css_rgb_parser, arena.allocator(), try String.init(arena.allocator(), "#aabbcc"));
    var rgb = try RGBBuilder.get();
    try io.getStdOut().writer().print("R: {s}, G: {s}, B: {s}\n\n", .{ rgb.r.text, rgb.g.text, rgb.b.text });

    try Invoker.parseTest(css_rgb_parser, arena.allocator(), try String.init(arena.allocator(), "#abc"));
    rgb = try RGBBuilder.get();
    try io.getStdOut().writer().print("R: {s}, G: {s}, B: {s}\n\n", .{ rgb.r.text, rgb.g.text, rgb.b.text });

    try Invoker.parseTest(css_rgb_parser, arena.allocator(), try String.init(arena.allocator(), "#000000"));
    rgb = try RGBBuilder.get();
    try io.getStdOut().writer().print("R: {s}, G: {s}, B: {s}\n\n", .{ rgb.r.text, rgb.g.text, rgb.b.text });

    try Invoker.parseTest(css_rgb_parser, arena.allocator(), try String.init(arena.allocator(), "#000"));
    rgb = try RGBBuilder.get();
    try io.getStdOut().writer().print("R: {s}, G: {s}, B: {s}\n\n", .{ rgb.r.text, rgb.g.text, rgb.b.text });
}

fn css_rgb_parser() type {
    return Combinators.choice2(
        css_rrggbb, css_rgb
    );
}

fn css_rrggbb() type {
    return Combinators.sequence4(
        Parsers.match("#"), Effect.attach(rr, RGBBuilder.setR), Effect.attach(gg, RGBBuilder.setG), Effect.attach(bb, RGBBuilder.setB)
    );
}

fn css_rgb() type {
    return Combinators.sequence4(
        Parsers.match("#"), r().attach(RGBBuilder.setR), g().attach(RGBBuilder.setG), b().attach(RGBBuilder.setB)
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
        RGBBuilder.r = try consumed.dup();
    }

    pub fn setG(consumed: String) anyerror!void {
        RGBBuilder.g = try consumed.dup();
    }

    pub fn setB(consumed: String) anyerror!void {
        RGBBuilder.b = try consumed.dup();
    }

    pub fn get() anyerror!RGB {
        return RGB {
            .r = try RGBBuilder.r.dup(),
            .g = try RGBBuilder.g.dup(),
            .b = try RGBBuilder.b.dup(),
        };
    }

};
