const std = @import("std");
const Allocator = std.mem.Allocator;
const heap = std.heap;
const testing = std.testing;

const Parquet = @import("Parquet.zig");
const String = Parquet.Base.String;
const Analyte = Parquet.ParserCombinator.Analyte;


test "Analyte.initWithOk;ArenaAllocator" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    const s: String = try String.init(arena.allocator(), "test");
    defer s.deinit();
    const analyte: Analyte = try Analyte.initWithOk(arena.allocator(), s);
    defer analyte.deinit();
}

test "Analyte.init*;GeneralPurposeAllocator" {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const s: String = try String.init(gpa.allocator(), "test");
    defer s.deinit();

    const analyte1: Analyte = try Analyte.initWithOk(gpa.allocator(), s);
    defer analyte1.deinit();

    const analyte2: Analyte = try Analyte.initWithErr(gpa.allocator(), s);
    defer analyte2.deinit();

    const analyte3: Analyte = try Analyte.initWithConsumed(s, gpa.allocator(), s);
    defer analyte3.deinit();
}

test "Analyte.initWithAbsorb" {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const s: String = try String.init(gpa.allocator(), "test string");
    defer s.deinit();

    const _test: String = try String.init(gpa.allocator(), "test");
    defer _test.deinit();

    const analyte: Analyte = try Analyte.initWithOk(gpa.allocator(), s);
    defer analyte.deinit();

    const analyte2: Analyte = try Analyte.initWithConsumed(_test, gpa.allocator(), s);
    defer analyte2.deinit();

    const _analyte: Analyte = try analyte.initWithAbsorb(analyte2);
    defer _analyte.deinit();

    const _analyte2: Analyte = try analyte.initWithAbsorb(analyte2);
    defer _analyte2.deinit();

    const _analyte3: Analyte = try analyte.initWithAbsorb(analyte2);
    defer _analyte3.deinit();
}
