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
    return Parser(struct {
        fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            const parsingFunctions: [@typeInfo(@TypeOf(parsers)).Struct.fields.len]ParsingFunction = blk: {
                var fnPtrs: [@typeInfo(@TypeOf(parsers)).Struct.fields.len]ParsingFunction = undefined;
                inline for (parsers, 0..) |parser, i| {
                    fnPtrs[i] = Retriever.get(parser);
                }
                break :blk fnPtrs;
            };

            var analyte: Analyte = try Analyte.initWithOk(allocator, text);

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
    }.anonymous);
}

/// p1 / ... / pn
pub fn choice(parsers: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            const parsingFunctions: [@typeInfo(@TypeOf(parsers)).Struct.fields.len]ParsingFunction = blk: {
                var fnPtrs: [@typeInfo(@TypeOf(parsers)).Struct.fields.len]ParsingFunction = undefined;
                inline for (parsers, 0..) |parser, i| {
                    fnPtrs[i] = Retriever.get(parser);
                }
                break :blk fnPtrs;
            };

            for (parsingFunctions) |parsingFunction| {
                const analyte: Analyte = try parsingFunction(allocator, text);

                if (analyte.answer == Analyte.Answer.ok)
                    return analyte;

                defer analyte.deinit();
            }

            return Analyte.initWithErr(allocator, text);
        }
    }.anonymous);
}

/// p*
pub fn many0(parser: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            var analyte: Analyte = try Retriever.get(parser)(allocator, text);

            if (analyte.answer == Analyte.Answer.err) {
                defer analyte.deinit();
                return Analyte.initWithOk(allocator, text);
            }

            while (true) {
                const analyte2: Analyte = try Retriever.get(parser)(allocator, analyte.subsequent);
                defer analyte2.deinit();

                if (analyte2.answer == Analyte.Answer.err)
                    break;

                const tmp: Analyte = analyte;
                analyte = try analyte.initWithAbsorb(analyte2);
                tmp.deinit();
            }

            return analyte;
        }
    }.anonymous);
}

/// p+
pub fn many1(parser: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            var analyte: Analyte = try Retriever.get(parser)(allocator, text);

            if (analyte.answer == Analyte.Answer.err)
                return analyte;

            while (true) {
                const analyte2: Analyte = try Retriever.get(parser)(allocator, analyte.subsequent);
                defer analyte2.deinit();

                if (analyte2.answer == Analyte.Answer.err)
                    break;

                const tmp: Analyte = analyte;
                analyte = try analyte.initWithAbsorb(analyte2);
                tmp.deinit();
            }

            return analyte;
        }
    }.anonymous);
}

/// p^N
pub fn manyN(parser: anytype, count: usize) type {
    return Parser(struct {
        fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            var analyte: Analyte = try Analyte.initWithOk(allocator, text);

            for (0..count) |i| {
                _ = i;

                const tmp: Analyte = analyte;
                analyte = try Retriever.get(parser)(allocator, analyte.subsequent);
                tmp.deinit();

                if (analyte.answer == Analyte.Answer.err) {
                    analyte.deinit();
                    return try Analyte.initWithErr(allocator, text);
                }
            }

            while (true) {
                const analyte2: Analyte = try Retriever.get(parser)(allocator, analyte.subsequent);
                defer analyte2.deinit();

                if (analyte2.answer == Analyte.Answer.err)
                    break;

                const tmp: Analyte = analyte;
                analyte = try analyte.initWithAbsorb(analyte2);
                tmp.deinit();
            }

            return analyte;
        }
    }.anonymous);
}

/// p?
pub fn optional(parser: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            const analyte: Analyte = try Retriever.get(parser)(allocator, text);

            return if (analyte.answer == Analyte.Answer.ok)
                analyte
            else blk: {
                defer analyte.deinit();
                break :blk try Analyte.initWithOk(allocator, text);
            };
        }
    }.anonymous);
}

/// &p
pub fn predict(parser: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            const analyte: Analyte = try Retriever.get(parser)(allocator, text);
            defer analyte.deinit();

            return if (analyte.answer == Analyte.Answer.ok)
                Analyte.initWithOk(allocator, text)
            else
                Analyte.initWithErr(allocator, text);
        }
    }.anonymous);
}

/// !p
pub fn notPredict(parser: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            const analyte: Analyte = try Retriever.get(parser)(allocator, text);
            defer analyte.deinit();

            return if (analyte.answer == Analyte.Answer.ok)
                Analyte.initWithErr(allocator, text)
            else
                Analyte.initWithOk(allocator, text);
        }
    }.anonymous);
}


/// p1 >> p2
pub fn sequence2(parser1: anytype, parser2: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            const analyte: Analyte = try Retriever.get(parser1)(allocator, text);
            if (analyte.answer == Analyte.Answer.err)
                return analyte;
            defer analyte.deinit();

            const analyte2: Analyte = try Retriever.get(parser2)(allocator, analyte.subsequent);
            defer analyte2.deinit();

            return try analyte.initWithAbsorb(analyte2);
        }
    }.anonymous);
}

/// p1 >> p2 >> p3
pub fn sequence3(parser1: anytype, parser2: anytype, parser3: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            const analyte: Analyte = try sequence2(parser1, parser2).body(allocator, text);
            if (analyte.answer == Analyte.Answer.err)
                return analyte;
            defer analyte.deinit();

            const analyte2: Analyte = try Retriever.get(parser3)(allocator, analyte.subsequent);
            defer analyte2.deinit();

            return try analyte.initWithAbsorb(analyte2);
        }
    }.anonymous);
}

/// p1 >> p2 >> p3 >> p4
pub fn sequence4(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            const analyte: Analyte = try sequence3(parser1, parser2, parser3).body(allocator, text);
            if (analyte.answer == Analyte.Answer.err)
                return analyte;
            defer analyte.deinit();

            const analyte2: Analyte = try Retriever.get(parser4)(allocator, analyte.subsequent);
            defer analyte2.deinit();

            return try analyte.initWithAbsorb(analyte2);
        }
    }.anonymous);
}

/// p1 >> p2 >> p3 >> p4 >> p5
pub fn sequence5(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            const analyte: Analyte = try sequence4(parser1, parser2, parser3, parser4).body(allocator, text);
            if (analyte.answer == Analyte.Answer.err)
                return analyte;
            defer analyte.deinit();

            const analyte2: Analyte = try Retriever.get(parser5)(allocator, analyte.subsequent);
            defer analyte2.deinit();

            return try analyte.initWithAbsorb(analyte2);
        }
    }.anonymous);
}

/// p1 >> p2 >> p3 >> p4 >> p5 >> p6
pub fn sequence6(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            const analyte: Analyte = try sequence5(parser1, parser2, parser3, parser4, parser5).body(allocator, text);
            if (analyte.answer == Analyte.Answer.err)
                return analyte;
            defer analyte.deinit();

            const analyte2: Analyte = try Retriever.get(parser6)(allocator, analyte.subsequent);
            defer analyte2.deinit();

            return try analyte.initWithAbsorb(analyte2);
        }
    }.anonymous);
}

/// p1 >> p2 >> p3 >> p4 >> p5 >> p6 >> p7
pub fn sequence7(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            const analyte: Analyte = try sequence6(parser1, parser2, parser3, parser4, parser5, parser6).body(allocator, text);
            if (analyte.answer == Analyte.Answer.err)
                return analyte;
            defer analyte.deinit();

            const analyte2: Analyte = try Retriever.get(parser7)(allocator, analyte.subsequent);
            defer analyte2.deinit();

            return try analyte.initWithAbsorb(analyte2);
        }
    }.anonymous);
}

/// p1 >> p2 >> p3 >> p4 >> p5 >> p6 >> p7 >> p8
pub fn sequence8(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype, parser8: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            const analyte: Analyte = try sequence7(parser1, parser2, parser3, parser4, parser5, parser6, parser7).body(allocator, text);
            if (analyte.answer == Analyte.Answer.err)
                return analyte;
            defer analyte.deinit();

            const analyte2: Analyte = try Retriever.get(parser8)(allocator, analyte.subsequent);
            defer analyte2.deinit();

            return try analyte.initWithAbsorb(analyte2);
        }
    }.anonymous);
}

/// p1 >> p2 >> p3 >> p4 >> p5 >> p6 >> p7 >> p8 >> p9
pub fn sequence9(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype, parser8: anytype, parser9: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            const analyte: Analyte = try sequence8(parser1, parser2, parser3, parser4, parser5, parser6, parser7, parser8).body(allocator, text);
            if (analyte.answer == Analyte.Answer.err)
                return analyte;
            defer analyte.deinit();

            const analyte2: Analyte = try Retriever.get(parser9)(allocator, analyte.subsequent);
            defer analyte2.deinit();

            return try analyte.initWithAbsorb(analyte2);
        }
    }.anonymous);
}

/// p1 >> p2 >> p3 >> p4 >> p5 >> p6 >> p7 >> p8 >> p9 >> p10
pub fn sequence10(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype, parser8: anytype, parser9: anytype, parser10: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            const analyte: Analyte = try sequence9(parser1, parser2, parser3, parser4, parser5, parser6, parser7, parser8, parser9).body(allocator, text);
            if (analyte.answer == Analyte.Answer.err)
                return analyte;
            defer analyte.deinit();

            const analyte2: Analyte = try Retriever.get(parser10)(allocator, analyte.subsequent);
            defer analyte2.deinit();

            return try analyte.initWithAbsorb(analyte2);
        }
    }.anonymous);
}

/// p1 >> p2 >> p3 >> p4 >> p5 >> p6 >> p7 >> p8 >> p9 >> p10 >> p11
pub fn sequence11(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype, parser8: anytype, parser9: anytype, parser10: anytype, parser11: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            const analyte: Analyte = try sequence10(parser1, parser2, parser3, parser4, parser5, parser6, parser7, parser8, parser9, parser10).body(allocator, text);
            if (analyte.answer == Analyte.Answer.err)
                return analyte;
            defer analyte.deinit();

            const analyte2: Analyte = try Retriever.get(parser11)(allocator, analyte.subsequent);
            defer analyte2.deinit();

            return try analyte.initWithAbsorb(analyte2);
        }
    }.anonymous);
}

/// p1 / p2
pub fn choice2(parser1: anytype, parser2: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            const analyte: Analyte = try Retriever.get(parser1)(allocator, text);
            if (analyte.answer == Analyte.Answer.ok)
                return analyte;

            defer analyte.deinit();
            return try Retriever.get(parser2)(allocator, text);
        }
    }.anonymous);
}

/// p1 / p2 / p3
pub fn choice3(parser1: anytype, parser2: anytype, parser3: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            const analyte: Analyte = try choice2(parser1, parser2).body(allocator, text);
            if (analyte.answer == Analyte.Answer.ok)
                return analyte;

            defer analyte.deinit();
            return try Retriever.get(parser3)(allocator, text);
        }
    }.anonymous);
}

/// p1 / p2 / p3 / p4
pub fn choice4(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            const analyte: Analyte = try choice3(parser1, parser2, parser3).body(allocator, text);
            if (analyte.answer == Analyte.Answer.ok)
                return analyte;

            defer analyte.deinit();
            return try Retriever.get(parser4)(allocator, text);
        }
    }.anonymous);
}

/// p1 / p2 / p3 / p4 / p5
pub fn choice5(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            const analyte: Analyte = try choice4(parser1, parser2, parser3, parser4).body(allocator, text);
            if (analyte.answer == Analyte.Answer.ok)
                return analyte;

            defer analyte.deinit();
            return try Retriever.get(parser5)(allocator, text);
        }
    }.anonymous);
}

/// p1 / p2 / p3 / p4 / p5 / p6
pub fn choice6(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            const analyte: Analyte = try choice5(parser1, parser2, parser3, parser4, parser5).body(allocator, text);
            if (analyte.answer == Analyte.Answer.ok)
                return analyte;

            defer analyte.deinit();
            return try Retriever.get(parser6)(allocator, text);
        }
    }.anonymous);
}

/// p1 / p2 / p3 / p4 / p5 / p6 / p7
pub fn choice7(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            const analyte: Analyte = try choice6(parser1, parser2, parser3, parser4, parser5, parser6).body(allocator, text);
            if (analyte.answer == Analyte.Answer.ok)
                return analyte;

            defer analyte.deinit();
            return try Retriever.get(parser7)(allocator, text);
        }
    }.anonymous);
}

/// p1 / p2 / p3 / p4 / p5 / p6 / p7 / p8
pub fn choice8(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype, parser8: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            const analyte: Analyte = try choice7(parser1, parser2, parser3, parser4, parser5, parser6, parser7).body(allocator, text);
            if (analyte.answer == Analyte.Answer.ok)
                return analyte;

            defer analyte.deinit();
            return try Retriever.get(parser8)(allocator, text);
        }
    }.anonymous);
}

/// p1 / p2 / p3 / p4 / p5 / p6 / p7 / p8 / p9
pub fn choice9(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype, parser8: anytype, parser9: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            const analyte: Analyte = try choice8(parser1, parser2, parser3, parser4, parser5, parser6, parser7, parser8).body(allocator, text);
            if (analyte.answer == Analyte.Answer.ok)
                return analyte;

            defer analyte.deinit();
            return try Retriever.get(parser9)(allocator, text);
        }
    }.anonymous);
}

/// p1 / p2 / p3 / p4 / p5 / p6 / p7 / p8 / p9 / p10
pub fn choice10(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype, parser8: anytype, parser9: anytype, parser10: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            const analyte: Analyte = try choice9(parser1, parser2, parser3, parser4, parser5, parser6, parser7, parser8, parser9).body(allocator, text);
            if (analyte.answer == Analyte.Answer.ok)
                return analyte;

            defer analyte.deinit();
            return try Retriever.get(parser10)(allocator, text);
        }
    }.anonymous);
}

/// p1 / p2 / p3 / p4 / p5 / p6 / p7 / p8 / p9 / p10 / p11
pub fn choice11(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype, parser8: anytype, parser9: anytype, parser10: anytype, parser11: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
            const analyte: Analyte = try choice10(parser1, parser2, parser3, parser4, parser5, parser6, parser7, parser8, parser9, parser10).body(allocator, text);
            if (analyte.answer == Analyte.Answer.ok)
                return analyte;

            defer analyte.deinit();
            return try Retriever.get(parser11)(allocator, text);
        }
    }.anonymous);
}
