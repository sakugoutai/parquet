const std = @import("std");
const mem = std.mem;
const heap = std.heap;
const testing = std.testing;

const ariadne = @import("ariadne");
const parquet = @import("parquet");


test "Analyte.ok; ArenaAllocator" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    const s = try ariadne.String.init(arena.allocator(), "test");
    defer s.deinit();
    const analyte: parquet.Analyte = try parquet.Analyte.ok(arena.allocator(), s);
    defer analyte.deinit();

    try testing.expect(analyte.answer == parquet.Analyte.Answer.ok);
    try testing.expect(analyte.parsed.empty());
}

test "Analyte constructors; DebugAllocator" {
	var da = heap.DebugAllocator(.{}){};
	defer _ = da.deinit();

    const s = try ariadne.String.init(da.allocator(), "test");
    defer s.deinit();

    var analyte1 = try parquet.Analyte.ok(da.allocator(), s);
    defer analyte1.deinit();

    const analyte2 = try parquet.Analyte.err(da.allocator(), s);
    defer analyte2.deinit();

    const analyte3 = try parquet.Analyte.consumed(s, da.allocator(), s);
    defer analyte3.deinit();

    try testing.expect(analyte1.answer == parquet.Analyte.Answer.ok);
    try testing.expect(analyte2.answer == parquet.Analyte.Answer.err);
    try testing.expect(analyte3.answer == parquet.Analyte.Answer.ok);

    try analyte1.merge(analyte3);

    try testing.expect(analyte1.subsequent.empty());
}
