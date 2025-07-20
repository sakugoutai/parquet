const std = @import("std");
const heap = std.heap;
const mem = std.mem;
const testing = std.testing;

const ariadne = @import("ariadne");
const parquet = @import("parquet");


test "Combinators sequence" {
    var da = heap.DebugAllocator(.{}){};
    defer _ = da.deinit();

	const s = try ariadne.String.init(da.allocator(), "test string");
	defer s.deinit();

	const _test = parquet.Parsers.match("test");
	const _space = parquet.Parsers.match(" ");
	const _string = parquet.Parsers.match("string");

	const test_space_string = parquet.Combinators.sequence3(_test, _space, _string);
	var a = try test_space_string.body(da.allocator(), s);
	defer a.deinit();

	try testing.expect(a.parsed.eql(s));

	const test_space_string2 = parquet.Combinators.sequence(.{ _test, _space, _string });
	var a2 = try test_space_string2.body(da.allocator(), s);
	defer a2.deinit();

	try testing.expect(a2.parsed.eql(s));
}

test "Combinators choice" {
    var da = heap.DebugAllocator(.{}){};
    defer _ = da.deinit();

	const s = try ariadne.String.init(da.allocator(), "test string");
	defer s.deinit();

	const t = parquet.Parsers.match("testa");
	const t2 = parquet.Parsers.match("test");

	const testa_or_test = parquet.Combinators.choice2(t, t2);
	var a = try testa_or_test.body(da.allocator(), s);
	defer a.deinit();

	try testing.expect(mem.eql(u8, a.parsed.text, "test"));
	try testing.expect(!mem.eql(u8, a.subsequent.text, "  string"));

	const testa_or_test2 = parquet.Combinators.choice(.{ t, t2 });
	var a2 = try testa_or_test2.body(da.allocator(), s);
	defer a2.deinit();

	try testing.expect(mem.eql(u8, a2.parsed.text, "test"));
	try testing.expect(!mem.eql(u8, a2.subsequent.text, "  string"));
}

test "Combinators {many0, many1}" {
    var da = heap.DebugAllocator(.{}){};
    defer _ = da.deinit();

	const s = try ariadne.String.init(da.allocator(), "tttt tttt");
	defer s.deinit();

	const a = try parquet.Combinators.many0(parquet.Parsers.match("t")).body(da.allocator(), s);
	defer a.deinit();

	const a2 = try parquet.Combinators.many1(parquet.Parsers.match("t")).body(da.allocator(), s);
	defer a2.deinit();

	try testing.expect(mem.eql(u8, a.parsed.text, "tttt"));
	try testing.expect(mem.eql(u8, a.subsequent.text, " tttt"));
	try testing.expect(mem.eql(u8, a2.parsed.text, "tttt"));
	try testing.expect(mem.eql(u8, a2.subsequent.text, " tttt"));
}

test "Combinators {optional, predict, notPredict}" {
    var da = heap.DebugAllocator(.{}){};
    defer _ = da.deinit();

	const s = try ariadne.String.init(da.allocator(), "test string");
	defer s.deinit();

	const a = try parquet.Combinators.optional(parquet.Parsers.match("test")).body(da.allocator(), s);
	defer a.deinit();

	const a2 = try parquet.Combinators.predict(parquet.Parsers.match("test")).body(da.allocator(), s);
	defer a2.deinit();

	const a3 = try parquet.Combinators.notPredict(parquet.Parsers.match("test")).body(da.allocator(), s);
	defer a3.deinit();

	try testing.expect(mem.eql(u8, a.parsed.text, "test"));
	try testing.expect(!mem.eql(u8, a.parsed.text, "testa"));
	try testing.expect(mem.eql(u8, a.subsequent.text, " string"));
	try testing.expect(a2.answer == parquet.Analyte.Answer.ok);
	try testing.expect(a3.answer == parquet.Analyte.Answer.err);
}
