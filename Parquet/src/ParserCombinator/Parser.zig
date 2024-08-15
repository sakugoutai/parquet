const std = @import("std");
const Allocator = std.mem.Allocator;

const Base = @import("../Base.zig");
const String = Base.String;
const Analyte = @import("Analyte.zig").Analyte;


/// Definition of Parsing Function
pub const ParsingFunction = *const fn (allocator: Allocator, text: String) anyerror!Analyte;


/// Parser Generator from Parsing Function
///
/// Parser in `Parquet` is a function that returns
///   a struct that holds Function Pointer which type is
///     `body: ParsingFunction`.
pub fn Parser(function: anytype) type {
	switch (@typeInfo(@TypeOf(function))) {
		.Fn => return struct {
			pub const body = function;
		},

		else => @compileError("function of Parser(function) must be a parsing function."),
    }
}


/// Parser Generator from Parsing Function
///
/// another style of Parser in `Parquet`
pub const ParserGenerator = *const fn () type;


/// returning ParsingFunction
pub const Retriever = struct {
	pub fn get(parser: anytype) ParsingFunction {
		return if (@typeInfo(@TypeOf(parser)) == .Fn and @typeInfo(@TypeOf(parser)).Fn.params.len == 1)
			// ParsingFunction
			parser
		else if (@typeInfo(@TypeOf(parser)) == .Fn)
			// ParserGenerator
			// fn () type { return struct { body: ParsingFunction }; }
			parser().body
		else
			// Parser(ParsingFunction)
			// struct { body: ParsingFunction }
			parser.body;
	}
};
