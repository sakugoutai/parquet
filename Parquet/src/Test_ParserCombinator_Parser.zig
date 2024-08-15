const std = @import("std");
const heap = std.heap;
const io = std.io;
const Allocator = std.mem.Allocator;

const Parquet = @import("Parquet.zig");
const String = Parquet.Base.String;
const Analyte = Parquet.ParserCombinator.Analyte;
const Parser = Parquet.ParserCombinator.Parser;


test "Parser" {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

	const s: String = try String.init(gpa.allocator(), "test");
	defer s.deinit();

	const p = Parser(parsing_function);
	const a: Analyte = try p.body(gpa.allocator(), s);
	defer a.deinit();
}

fn parsing_function(allocator: Allocator, text: String) anyerror!Analyte {
	return try Analyte.initWithOk(allocator, text);
}
