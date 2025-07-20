const std = @import("std");
const mem = std.mem;

const ariadne = @import("ariadne");
const Analyte = @import("analyte.zig").Analyte;


/// definition of Parsing Function
pub const ParsingFunction = *const fn (allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte;


/// definition of Semantic Action
pub const SemanticAction = *const fn (consumed: ariadne.String) anyerror!void;


/// Parser Generator from Parsing Function
///
/// Parser in `parquet` is a function that returns
///   a struct that holds Function Pointer which type is
///     `body: ParsingFunction`.
pub fn Parser(function: anytype) type {
	switch (@typeInfo(@TypeOf(function))) {
		.@"fn" => return struct {
			pub const body = function;

			pub fn attach(action: SemanticAction) type {
				return Parser(struct {
					fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
						const analyte: Analyte = try extractParsingFunction(body)(allocator, text);
						try action(analyte.parsed);
						return analyte;
					}
				}.anonymous);
			}
		},

		else => @compileError("function of Parser(function) must be a Parsing Function."),
    }
}


/// Parser Generator from Parsing Function
///
/// another style of Parser in `parquet`
pub const ParserGenerator = *const fn () type;


/// returning ParsingFunction
pub fn extractParsingFunction(parser: anytype) ParsingFunction {
	return if (@typeInfo(@TypeOf(parser)) == .@"fn" and @typeInfo(@TypeOf(parser)).@"fn".params.len != 0)
		// ParsingFunction
		parser
	else if (@typeInfo(@TypeOf(parser)) == .@"fn")
		// ParserGenerator
		// fn () type { return struct { body: ParsingFunction }; }
		parser().body
	else
		// Parser(ParsingFunction)
		// struct { body: ParsingFunction }
		parser.body;
}
