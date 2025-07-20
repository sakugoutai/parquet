const std = @import("std");
const heap = std.heap;
const io = std.io;
const mem = std.mem;
const testing = std.testing;

const ariadne = @import("ariadne");
const parquet = @import("parquet");


test "parser" {
    var da = heap.DebugAllocator(.{}){};
    defer _ = da.deinit();

	const s = try ariadne.String.init(da.allocator(), "test");
	defer s.deinit();

	const p = parquet.Parser(parsing_function);
	const a = try p.body(da.allocator(), s);
	defer a.deinit();

	try testing.expect(a.answer == parquet.Analyte.Answer.ok);
}

fn parsing_function(allocator: mem.Allocator, text: ariadne.String) anyerror!parquet.Analyte {
	return try parquet.Analyte.ok(allocator, text);
}
