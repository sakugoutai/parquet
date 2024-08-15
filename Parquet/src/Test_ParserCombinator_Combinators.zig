const std = @import("std");
const Allocator = std.mem.Allocator;
const heap = std.heap;
const mem = std.mem;
const testing = std.testing;

const Parquet = @import("Parquet.zig");
const String = Parquet.Base.String;
const Analyte = Parquet.ParserCombinator.Analyte;
const Parser = Parquet.ParserCombinator.Parser;
const Combinators = Parquet.ParserCombinator.Combinators;
const Parsers = Parquet.ParserCombinator.Parsers;


test "Combinators.sequence" {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

	const s: String = try String.init(gpa.allocator(), "test string");
	defer s.deinit();

	const _test = Parsers.match("test");
	const _space = Parsers.match(" ");
	const _string = Parsers.match("string");

	const test_space_string = Combinators.sequence3(_test, _space, _string);
	var a: Analyte = try test_space_string.body(gpa.allocator(), s);
	defer a.deinit();

	try testing.expect(a.consumed.equals(s));

	const test_space_string2 = Combinators.sequence(.{ _test, _space, _string });
	var a2: Analyte = try test_space_string2.body(gpa.allocator(), s);
	defer a2.deinit();

	try testing.expect(a2.consumed.equals(s));
}

test "Combinators.choice" {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

	const s: String = try String.init(gpa.allocator(), "test string");
	defer s.deinit();

	const t = Parsers.match("testa");
	const t2 = Parsers.match("test");

	const testa_or_test = Combinators.choice2(t, t2);
	var a: Analyte = try testa_or_test.body(gpa.allocator(), s);
	defer a.deinit();

	try testing.expect(mem.eql(u8, a.consumed.getPrimitive(), "test"));
	try testing.expect(!mem.eql(u8, a.subsequent.getPrimitive(), "  string"));

	const testa_or_test2 = Combinators.choice(.{ t, t2 });
	var a2: Analyte = try testa_or_test2.body(gpa.allocator(), s);
	defer a2.deinit();

	try testing.expect(mem.eql(u8, a2.consumed.getPrimitive(), "test"));
	try testing.expect(!mem.eql(u8, a2.subsequent.getPrimitive(), "  string"));
}

test "Combinators.{many0, many1}" {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

	const s: String = try String.init(gpa.allocator(), "tttt tttt");
	defer s.deinit();

	const a: Analyte = try Combinators.many0(Parsers.match("t")).body(gpa.allocator(), s);
	defer a.deinit();

	const a2: Analyte = try Combinators.many1(Parsers.match("t")).body(gpa.allocator(), s);
	defer a2.deinit();

	try testing.expect(mem.eql(u8, a.consumed.getPrimitive(), "tttt"));//ng
	try testing.expect(mem.eql(u8, a.subsequent.getPrimitive(), " tttt"));
	try testing.expect(mem.eql(u8, a2.consumed.getPrimitive(), "tttt"));//ng
	try testing.expect(mem.eql(u8, a2.subsequent.getPrimitive(), " tttt"));
}

test "Combinators.{optional, predict, notPredict}" {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

	const s: String = try String.init(gpa.allocator(), "test string");
	defer s.deinit();

	const a: Analyte = try Combinators.optional(Parsers.match("test")).body(gpa.allocator(), s);
	defer a.deinit();

	const a2: Analyte = try Combinators.predict(Parsers.match("test")).body(gpa.allocator(), s);
	defer a2.deinit();

	const a3: Analyte = try Combinators.notPredict(Parsers.match("test")).body(gpa.allocator(), s);
	defer a3.deinit();

	try testing.expect(mem.eql(u8, a.consumed.getPrimitive(), "test"));
	try testing.expect(!mem.eql(u8, a.consumed.getPrimitive(), "testa"));
	try testing.expect(mem.eql(u8, a.subsequent.getPrimitive(), " string"));
	try testing.expect(a2.answer == Analyte.Answer.ok);
	try testing.expect(a3.answer == Analyte.Answer.err);
}
