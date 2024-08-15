const std = @import("std");
const Allocator = std.mem.Allocator;

const Base = @import("../Base.zig");
const String = Base.String;
const Analyte = @import("Analyte.zig").Analyte;
const ParsingFunction = @import("Parser.zig").ParsingFunction;
const Parser = @import("Parser.zig").Parser;
const Retriever = @import("Parser.zig").Retriever;


/// p1 >> ... >> pn
pub fn sequence(parsers: anytype) type {
    if (@typeInfo(@TypeOf(parsers)) != .Struct)
		@compileError("parsers as .{ Parser(ParsingFunction), ... } must be a struct.");

    return struct {
        const parsingFunctions: [@typeInfo(@TypeOf(parsers)).Struct.fields.len]ParsingFunction = blk: {
            var fnPtrs: [@typeInfo(@TypeOf(parsers)).Struct.fields.len]ParsingFunction = undefined;
            for (parsers, 0..) |parser, i| {
                fnPtrs[i] = Retriever.get(parser);
            }
            break :blk fnPtrs;
        };

        pub const body = struct {
            fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
                var analyte: Analyte = try Analyte.initWithOk(allocator, text);

                //inline for (parsers) |parser| {
                for (parsingFunctions) |parsingFunction| {
                    const analyte2: Analyte = try parsingFunction(allocator, analyte.subsequent);

                    if (analyte2.answer == Analyte.Answer.err) {
                        defer analyte.deinit();
                        return Analyte.initWithErr(allocator, text);
                    }

                    defer analyte2.deinit();
                    const tmp: Analyte = analyte;
                    defer tmp.deinit();
                    analyte = try analyte.initWithAbsorb(analyte2);
                }

                return analyte;
            }
        }.anonymous;
    };
}

/// p1 / ... / pn
pub fn choice(parsers: anytype) type {
    if (@typeInfo(@TypeOf(parsers)) != .Struct)
		@compileError("parsers as .{ Parser(ParsingFunction), ... } must be a struct.");

    return struct {
        const parsingFunctions: [@typeInfo(@TypeOf(parsers)).Struct.fields.len]ParsingFunction = blk: {
            var fnPtrs: [@typeInfo(@TypeOf(parsers)).Struct.fields.len]ParsingFunction = undefined;
            for (parsers, 0..) |parser, i| {
                fnPtrs[i] = Retriever.get(parser);
            }
            break :blk fnPtrs;
        };

        pub const body = struct {
            fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
                //inline for (parsers) |parser| {
                for (parsingFunctions) |parsingFunction| {
                    const analyte: Analyte = try parsingFunction(allocator, text);

                    if (analyte.answer == Analyte.Answer.ok)
                        return analyte;

                    defer analyte.deinit();
                }

                return Analyte.initWithErr(allocator, text);
            }
        }.anonymous;
    };
}

/// p*
pub fn many0(parser: anytype) type {
    return struct {
        const parsingFunction: ParsingFunction = Retriever.get(parser);

        pub const body = struct {
            fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
                var analyte: Analyte = try parsingFunction(allocator, text);

                if (analyte.answer == Analyte.Answer.err) {
                    defer analyte.deinit();
                    return Analyte.initWithOk(allocator, text);
                }

                while (true) {
                    const analyte2: Analyte = try parsingFunction(allocator, analyte.subsequent);
                    defer analyte2.deinit();

                    if (analyte2.answer == Analyte.Answer.err)
                        break;

                    const tmp: Analyte = analyte;
                    analyte = try analyte.initWithAbsorb(analyte2);
                    tmp.deinit();
                }

                return analyte;
            }
        }.anonymous;
    };
}

/// p+
pub fn many1(parser: anytype) type {
    return struct {
        const parsingFunction: ParsingFunction = Retriever.get(parser);

        pub const body = struct {
            fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
                var analyte: Analyte = try parsingFunction(allocator, text);

                if (analyte.answer == Analyte.Answer.err)
                    return analyte;

                while (true) {
                    const analyte2: Analyte = try parsingFunction(allocator, analyte.subsequent);
                    defer analyte2.deinit();

                    if (analyte2.answer == Analyte.Answer.err)
                        break;

                    const tmp: Analyte = analyte;
                    analyte = try analyte.initWithAbsorb(analyte2);
                    tmp.deinit();
                }

                return analyte;
            }
        }.anonymous;
    };
}

/// p^N
pub fn manyN(parser: anytype, count: usize) type {
    return struct {
        const parsingFunction: ParsingFunction = Retriever.get(parser);

        pub const body = struct {
            fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
                var analyte: Analyte = try Analyte.initWithOk(allocator, text);

                for (0..count) |i| {
                    _ = i;

                    const tmp: Analyte = analyte;
                    analyte = try parsingFunction(allocator, analyte.subsequent);
                    tmp.deinit();

                    if (analyte.answer == Analyte.Answer.err) {
                        analyte.deinit();
                        return try Analyte.initWithErr(allocator, text);
                    }
                }

                while (true) {
                    const analyte2: Analyte = try parsingFunction(allocator, analyte.subsequent);
                    defer analyte2.deinit();

                    if (analyte2.answer == Analyte.Answer.err)
                        break;

                    const tmp: Analyte = analyte;
                    analyte = try analyte.initWithAbsorb(analyte2);
                    tmp.deinit();
                }

                return analyte;
            }
        }.anonymous;
    };
}

/// p?
pub fn optional(parser: anytype) type {
    return struct {
        const parsingFunction: ParsingFunction = Retriever.get(parser);

        pub const body = struct {
            fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
                const analyte: Analyte = try parsingFunction(allocator, text);

                return if (analyte.answer == Analyte.Answer.ok)
                    analyte
                else blk: {
                    defer analyte.deinit();
                    break :blk try Analyte.initWithOk(allocator, text);
                };
            }
        }.anonymous;
    };
}

/// &p
pub fn predict(parser: anytype) type {
    return struct {
        const parsingFunction: ParsingFunction = Retriever.get(parser);

        pub const body = struct {
            fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
                const analyte: Analyte = try parsingFunction(allocator, text);
                defer analyte.deinit();

                return if (analyte.answer == Analyte.Answer.ok)
                    Analyte.initWithOk(allocator, text)
                else
                    Analyte.initWithErr(allocator, text);
            }
        }.anonymous;
    };
}

/// !p
pub fn notPredict(parser: anytype) type {
    return struct {
        const parsingFunction: ParsingFunction = Retriever.get(parser);

        pub const body = struct {
            fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
                const analyte: Analyte = try parsingFunction(allocator, text);
                defer analyte.deinit();

                return if (analyte.answer == Analyte.Answer.ok)
                    Analyte.initWithErr(allocator, text)
                else
                    Analyte.initWithOk(allocator, text);
            }
        }.anonymous;
    };
}


/// p1 >> p2
pub fn sequence2(parser1: anytype, parser2: anytype) type {
    return struct {
        const parser1_parsingFunction: ParsingFunction = Retriever.get(parser1);
        const parser2_parsingFunction: ParsingFunction = Retriever.get(parser2);

        pub const body = struct {
            fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
                const analyte: Analyte = try parser1_parsingFunction(allocator, text);
                if (analyte.answer == Analyte.Answer.err)
                    return analyte;
                defer analyte.deinit();

                const analyte2: Analyte = try parser2_parsingFunction(allocator, analyte.subsequent);
                defer analyte2.deinit();

                return try analyte.initWithAbsorb(analyte2);
            }
        }.anonymous;
    };
}

/// p1 >> p2 >> p3
pub fn sequence3(parser1: anytype, parser2: anytype, parser3: anytype) type {
    return struct {
        const parser3_parsingFunction: ParsingFunction = Retriever.get(parser3);

        pub const body = struct {
            fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
                const analyte: Analyte = try sequence2(parser1, parser2).body(allocator, text);
                if (analyte.answer == Analyte.Answer.err)
                    return analyte;
                defer analyte.deinit();

                const analyte2: Analyte = try parser3_parsingFunction(allocator, analyte.subsequent);
                defer analyte2.deinit();

                return try analyte.initWithAbsorb(analyte2);
            }
        }.anonymous;
    };
}

/// p1 >> p2 >> p3 >> p4
pub fn sequence4(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype) type {
    return struct {
        const parser4_parsingFunction: ParsingFunction = Retriever.get(parser4);

        pub const body = struct {
            fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
                const analyte: Analyte = try sequence3(parser1, parser2, parser3).body(allocator, text);
                if (analyte.answer == Analyte.Answer.err)
                    return analyte;
                defer analyte.deinit();

                const analyte2: Analyte = try parser4_parsingFunction(allocator, analyte.subsequent);
                defer analyte2.deinit();

                return try analyte.initWithAbsorb(analyte2);
            }
        }.anonymous;
    };
}

/// p1 >> p2 >> p3 >> p4 >> p5
pub fn sequence5(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype) type {
    return struct {
        const parser5_parsingFunction: ParsingFunction = Retriever.get(parser5);

        pub const body = struct {
            fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
                const analyte: Analyte = try sequence4(parser1, parser2, parser3, parser4).body(allocator, text);
                if (analyte.answer == Analyte.Answer.err)
                    return analyte;
                defer analyte.deinit();

                const analyte2: Analyte = try parser5_parsingFunction(allocator, analyte.subsequent);
                defer analyte2.deinit();

                return try analyte.initWithAbsorb(analyte2);
            }
        }.anonymous;
    };
}

/// p1 >> p2 >> p3 >> p4 >> p5 >> p6
pub fn sequence6(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype) type {
    return struct {
        const parser6_parsingFunction: ParsingFunction = Retriever.get(parser6);

        pub const body = struct {
            fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
                const analyte: Analyte = try sequence5(parser1, parser2, parser3, parser4, parser5).body(allocator, text);
                if (analyte.answer == Analyte.Answer.err)
                    return analyte;
                defer analyte.deinit();

                const analyte2: Analyte = try parser6_parsingFunction(allocator, analyte.subsequent);
                defer analyte2.deinit();

                return try analyte.initWithAbsorb(analyte2);
            }
        }.anonymous;
    };
}

/// p1 >> p2 >> p3 >> p4 >> p5 >> p6 >> p7
pub fn sequence7(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype) type {
    return struct {
        const parser7_parsingFunction: ParsingFunction = Retriever.get(parser7);

        pub const body = struct {
            fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
                const analyte: Analyte = try sequence6(parser1, parser2, parser3, parser4, parser5, parser6).body(allocator, text);
                if (analyte.answer == Analyte.Answer.err)
                    return analyte;
                defer analyte.deinit();

                const analyte2: Analyte = try parser7_parsingFunction(allocator, analyte.subsequent);
                defer analyte2.deinit();

                return try analyte.initWithAbsorb(analyte2);
            }
        }.anonymous;
    };
}

/// p1 >> p2 >> p3 >> p4 >> p5 >> p6 >> p7 >> p8
pub fn sequence8(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype, parser8: anytype) type {
    return struct {
        const parser8_parsingFunction: ParsingFunction = Retriever.get(parser8);

        pub const body = struct {
            fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
                const analyte: Analyte = try sequence7(parser1, parser2, parser3, parser4, parser5, parser6, parser7).body(allocator, text);
                if (analyte.answer == Analyte.Answer.err)
                    return analyte;
                defer analyte.deinit();

                const analyte2: Analyte = try parser8_parsingFunction(allocator, analyte.subsequent);
                defer analyte2.deinit();

                return try analyte.initWithAbsorb(analyte2);
            }
        }.anonymous;
    };
}

/// p1 >> p2 >> p3 >> p4 >> p5 >> p6 >> p7 >> p8 >> p9
pub fn sequence9(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype, parser8: anytype, parser9: anytype) type {
    return struct {
        const parser9_parsingFunction: ParsingFunction = Retriever.get(parser9);

        pub const body = struct {
            fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
                const analyte: Analyte = try sequence8(parser1, parser2, parser3, parser4, parser5, parser6, parser7, parser8).body(allocator, text);
                if (analyte.answer == Analyte.Answer.err)
                    return analyte;
                defer analyte.deinit();

                const analyte2: Analyte = try parser9_parsingFunction(allocator, analyte.subsequent);
                defer analyte2.deinit();

                return try analyte.initWithAbsorb(analyte2);
            }
        }.anonymous;
    };
}

/// p1 >> p2 >> p3 >> p4 >> p5 >> p6 >> p7 >> p8 >> p9 >> p10
pub fn sequence10(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype, parser8: anytype, parser9: anytype, parser10: anytype) type {
    return struct {
        const parser10_parsingFunction: ParsingFunction = Retriever.get(parser10);

        pub const body = struct {
            fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
                const analyte: Analyte = try sequence9(parser1, parser2, parser3, parser4, parser5, parser6, parser7, parser8, parser9).body(allocator, text);
                if (analyte.answer == Analyte.Answer.err)
                    return analyte;
                defer analyte.deinit();

                const analyte2: Analyte = try parser10_parsingFunction(allocator, analyte.subsequent);
                defer analyte2.deinit();

                return try analyte.initWithAbsorb(analyte2);
            }
        }.anonymous;
    };
}

/// p1 >> p2 >> p3 >> p4 >> p5 >> p6 >> p7 >> p8 >> p9 >> p10 >> p11
pub fn sequence11(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype, parser8: anytype, parser9: anytype, parser10: anytype, parser11: anytype) type {
    return struct {
        const parser11_parsingFunction: ParsingFunction = Retriever.get(parser11);

        pub const body = struct {
            fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
                const analyte: Analyte = try sequence10(parser1, parser2, parser3, parser4, parser5, parser6, parser7, parser8, parser9, parser10).body(allocator, text);
                if (analyte.answer == Analyte.Answer.err)
                    return analyte;
                defer analyte.deinit();

                const analyte2: Analyte = try parser11_parsingFunction(allocator, analyte.subsequent);
                defer analyte2.deinit();

                return try analyte.initWithAbsorb(analyte2);
            }
        }.anonymous;
    };
}

/// p1 / p2
pub fn choice2(parser1: anytype, parser2: anytype) type {
    return struct {
        const parser1_parsingFunction: ParsingFunction = Retriever.get(parser1);
        const parser2_parsingFunction: ParsingFunction = Retriever.get(parser2);

        pub const body = struct {
            fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
                const analyte: Analyte = try parser1_parsingFunction(allocator, text);
                if (analyte.answer == Analyte.Answer.ok)
                    return analyte;

                defer analyte.deinit();
                return try parser2_parsingFunction(allocator, text);
            }
        }.anonymous;
    };
}

/// p1 / p2 / p3
pub fn choice3(parser1: anytype, parser2: anytype, parser3: anytype) type {
    return struct {
        const parser3_parsingFunction: ParsingFunction = Retriever.get(parser3);

        pub const body = struct {
            fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
                const analyte: Analyte = try choice2(parser1, parser2).body(allocator, text);
                if (analyte.answer == Analyte.Answer.ok)
                    return analyte;

                defer analyte.deinit();
                return try parser3_parsingFunction(allocator, text);
            }
        }.anonymous;
    };
}

/// p1 / p2 / p3 / p4
pub fn choice4(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype) type {
    return struct {
        const parser4_parsingFunction: ParsingFunction = Retriever.get(parser4);

        pub const body = struct {
            fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
                const analyte: Analyte = try choice3(parser1, parser2, parser3).body(allocator, text);
                if (analyte.answer == Analyte.Answer.ok)
                    return analyte;

                defer analyte.deinit();
                return try parser4_parsingFunction(allocator, text);
            }
        }.anonymous;
    };
}

/// p1 / p2 / p3 / p4 / p5
pub fn choice5(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype) type {
    return struct {
        const parser5_parsingFunction: ParsingFunction = Retriever.get(parser5);

        pub const body = struct {
            fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
                const analyte: Analyte = try choice4(parser1, parser2, parser3, parser4).body(allocator, text);
                if (analyte.answer == Analyte.Answer.ok)
                    return analyte;

                defer analyte.deinit();
                return try parser5_parsingFunction(allocator, text);
            }
        }.anonymous;
    };
}

/// p1 / p2 / p3 / p4 / p5 / p6
pub fn choice6(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype) type {
    return struct {
        const parser6_parsingFunction: ParsingFunction = Retriever.get(parser6);

        pub const body = struct {
            fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
                const analyte: Analyte = try choice5(parser1, parser2, parser3, parser4, parser5).body(allocator, text);
                if (analyte.answer == Analyte.Answer.ok)
                    return analyte;

                defer analyte.deinit();
                return try parser6_parsingFunction(allocator, text);
            }
        }.anonymous;
    };
}

/// p1 / p2 / p3 / p4 / p5 / p6 / p7
pub fn choice7(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype) type {
    return struct {
        const parser7_parsingFunction: ParsingFunction = Retriever.get(parser7);

        pub const body = struct {
            fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
                const analyte: Analyte = try choice6(parser1, parser2, parser3, parser4, parser5, parser6).body(allocator, text);
                if (analyte.answer == Analyte.Answer.ok)
                    return analyte;

                defer analyte.deinit();
                return try parser7_parsingFunction(allocator, text);
            }
        }.anonymous;
    };
}

/// p1 / p2 / p3 / p4 / p5 / p6 / p7 / p8
pub fn choice8(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype, parser8: anytype) type {
    return struct {
        const parser8_parsingFunction: ParsingFunction = Retriever.get(parser8);

        pub const body = struct {
            fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
                const analyte: Analyte = try choice7(parser1, parser2, parser3, parser4, parser5, parser6, parser7).body(allocator, text);
                if (analyte.answer == Analyte.Answer.ok)
                    return analyte;

                defer analyte.deinit();
                return try parser8_parsingFunction(allocator, text);
            }
        }.anonymous;
    };
}

/// p1 / p2 / p3 / p4 / p5 / p6 / p7 / p8 / p9
pub fn choice9(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype, parser8: anytype, parser9: anytype) type {
    return struct {
        const parser9_parsingFunction: ParsingFunction = Retriever.get(parser9);

        pub const body = struct {
            fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
                const analyte: Analyte = try choice8(parser1, parser2, parser3, parser4, parser5, parser6, parser7, parser8).body(allocator, text);
                if (analyte.answer == Analyte.Answer.ok)
                    return analyte;

                defer analyte.deinit();
                return try parser9_parsingFunction(allocator, text);
            }
        }.anonymous;
    };
}

/// p1 / p2 / p3 / p4 / p5 / p6 / p7 / p8 / p9 / p10
pub fn choice10(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype, parser8: anytype, parser9: anytype, parser10: anytype) type {
    return struct {
        const parser10_parsingFunction: ParsingFunction = Retriever.get(parser10);

        pub const body = struct {
            fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
                const analyte: Analyte = try choice9(parser1, parser2, parser3, parser4, parser5, parser6, parser7, parser8, parser9).body(allocator, text);
                if (analyte.answer == Analyte.Answer.ok)
                    return analyte;

                defer analyte.deinit();
                return try parser10_parsingFunction(allocator, text);
            }
        }.anonymous;
    };
}

/// p1 / p2 / p3 / p4 / p5 / p6 / p7 / p8 / p9 / p10 / p11
pub fn choice11(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype, parser8: anytype, parser9: anytype, parser10: anytype, parser11: anytype) type {
    return struct {
        const parser11_parsingFunction: ParsingFunction = Retriever.get(parser11);

        pub const body = struct {
            fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
                const analyte: Analyte = try choice10(parser1, parser2, parser3, parser4, parser5, parser6, parser7, parser8, parser9, parser10).body(allocator, text);
                if (analyte.answer == Analyte.Answer.ok)
                    return analyte;

                defer analyte.deinit();
                return try parser11_parsingFunction(allocator, text);
            }
        }.anonymous;
    };
}
