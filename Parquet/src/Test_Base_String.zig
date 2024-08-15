const std = @import("std");
const heap = std.heap;
const mem = std.mem;
const testing = std.testing;

const Parquet = @import("Parquet.zig");
const String = Parquet.Base.String;

test "String.init,String#GetPrimitive;ArenaAllocator" {
	var arena = heap.ArenaAllocator.init(heap.page_allocator);
	defer arena.deinit();

	const s: String = try String.init(arena.allocator(), "test");
	defer s.deinit();

	try testing.expect(mem.eql(u8, s.getPrimitive(), "test"));
	// testing.expectEqual
}

test "String.init,String#GetPrimitive;GeneralPurposeAllocator" {
	var gpa = heap.GeneralPurposeAllocator(.{}){};
	defer _ = gpa.deinit();

	const s: String = try String.init(gpa.allocator(), "test");
	defer s.deinit();

	try testing.expect(mem.eql(u8, s.getPrimitive(), "test"));
}

test "String.init*" {
	var gpa = heap.GeneralPurposeAllocator(.{}){};
	defer _ = gpa.deinit();

	const s1: String = try String.init(gpa.allocator(), "test1");
	defer s1.deinit();
	try testing.expect(mem.eql(u8, s1.getPrimitive(), "test1"));

	const s2: String = try String.initWithConcat(gpa.allocator(), "test2", "test3");
	defer s2.deinit();
	try testing.expect(mem.eql(u8, s2.getPrimitive(), "test2test3"));

	const s3: String = try String.initWithNonConst(gpa.allocator(), s1.getPrimitive());
	defer s3.deinit();
	try testing.expect(mem.eql(u8, s3.getPrimitive(), "test1"));

	const s4: String = try String.initWithConcatNonConst(gpa.allocator(), s1.getPrimitive(), s2.getPrimitive());
	defer s4.deinit();
	try testing.expect(mem.eql(u8, s4.getPrimitive(), "test1test2test3"));

	const s5: String = try String.initFromString(gpa.allocator(), s4);
	defer s5.deinit();
	try testing.expect(mem.eql(u8, s5.getPrimitive(), "test1test2test3"));

	const s6: String = try String.initFromChar(gpa.allocator(), 'A');
	defer s6.deinit();
	try testing.expect(mem.eql(u8, s6.getPrimitive(), "A"));

	const s7: String = try String.initFromFile(gpa.allocator(), "src/Test_Base_String_Text.txt");
	defer s7.deinit();
	try testing.expect(mem.eql(u8, s7.getPrimitive(), "Test\r\nString\r\nParquet!"));
	try testing.expect(!mem.eql(u8, s7.getPrimitive(), "test string parquet?"));
}

test "String#{function}" {
	var gpa = heap.GeneralPurposeAllocator(.{}){};
	defer _ = gpa.deinit();

	const s1: String = try String.init(gpa.allocator(), "test1");
	defer s1.deinit();

	try testing.expect(s1.getLength() == 5);
	try testing.expect(try s1.getCharAt(2) == 's');
	try testing.expect(try s1.getHeadChar() == 't');

	const s2: String = try s1.substring(1, 4);
	defer s2.deinit();
	try testing.expect(mem.eql(u8, s2.getPrimitive(), "est"));

	const s3: String = try String.init(gpa.allocator(), "test2");
	defer s3.deinit();
	const s4: String = try s1.initWithSuffixString(s3);
	defer s4.deinit();
	try testing.expect(mem.eql(u8,
		s4.getPrimitive(),
		"test1test2"
	));

	const s5: String = try s1.initCopy();
	defer s5.deinit();
	try testing.expect(mem.eql(u8, s5.getPrimitive(), "test1"));
}

test "String#{predicate}" {
	var gpa = heap.GeneralPurposeAllocator(.{}){};
	defer _ = gpa.deinit();

	const s1: String = try String.init(gpa.allocator(), "test1");
	defer s1.deinit();

	try testing.expect(!s1.isEmpty());

	const s2: String = try String.init(gpa.allocator(), "test1");
	defer s2.deinit();
	try testing.expect(s1.equals(s2));

	const s3: String = try String.init(gpa.allocator(), "te");
	defer s3.deinit();
	try testing.expect(s1.startsWith(s3));

	try testing.expect(s1.startsWithChar('t'));
	try testing.expect(try s1.firstIndexOf('t') == 0);
	try testing.expect(try s1.lastIndexOf('t') == 3);
}
