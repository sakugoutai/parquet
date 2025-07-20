const std = @import("std");
const mem = std.mem;

const ariadne = @import("ariadne");
const Analyte = @import("analyte.zig").Analyte;
const ParsingFunction = @import("parser.zig").ParsingFunction;
const Parser = @import("parser.zig").Parser;
const extractParsingFunction = @import("parser.zig").extractParsingFunction;


/// p1 >> ... >> pn
pub fn sequence(parsers: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            const parsingFunctions: [@typeInfo(@TypeOf(parsers)).@"struct".fields.len]ParsingFunction = blk: {
                var fnPtrs: [@typeInfo(@TypeOf(parsers)).@"struct".fields.len]ParsingFunction = undefined;
                inline for (parsers, 0..) |parser, i| {
                    fnPtrs[i] = extractParsingFunction(parser);
                }
                break :blk fnPtrs;
            };

            var analyte = try Analyte.ok(allocator, text);

            for (parsingFunctions) |parsingFunction| {
                const analyte2 = try parsingFunction(allocator, analyte.subsequent);
                defer analyte2.deinit();

                if (analyte2.answer == Analyte.Answer.err) {
                    defer analyte.deinit();
                    return Analyte.err(allocator, text);
                }

                try analyte.merge(analyte2);
            }

            return analyte;
        }
    }.anonymous);
}

/// p1 / ... / pn
pub fn choice(parsers: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            const parsingFunctions: [@typeInfo(@TypeOf(parsers)).@"struct".fields.len]ParsingFunction = blk: {
                var fnPtrs: [@typeInfo(@TypeOf(parsers)).@"struct".fields.len]ParsingFunction = undefined;
                inline for (parsers, 0..) |parser, i| {
                    fnPtrs[i] = extractParsingFunction(parser);
                }
                break :blk fnPtrs;
            };

            for (parsingFunctions) |parsingFunction| {
                var analyte = try parsingFunction(allocator, text);

                if (analyte.answer == Analyte.Answer.ok)
                    return analyte;

                defer analyte.deinit();
            }

            return Analyte.err(allocator, text);
        }
    }.anonymous);
}

/// p*
pub fn many0(parser: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            var analyte = try extractParsingFunction(parser)(allocator, text);

            if (analyte.answer == Analyte.Answer.err) {
                defer analyte.deinit();
                return Analyte.ok(allocator, text);
            }

            while (true) {
                const analyte2 = try extractParsingFunction(parser)(allocator, analyte.subsequent);
                defer analyte2.deinit();

                if (analyte2.answer == Analyte.Answer.err)
                    break;

                try analyte.merge(analyte2);
            }

            return analyte;
        }
    }.anonymous);
}

/// p+
pub fn many1(parser: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            var analyte = try extractParsingFunction(parser)(allocator, text);

            if (analyte.answer == Analyte.Answer.err)
                return analyte;

            while (true) {
                const analyte2 = try extractParsingFunction(parser)(allocator, analyte.subsequent);
                defer analyte2.deinit();

                if (analyte2.answer == Analyte.Answer.err)
                    break;

                try analyte.merge(analyte2);
            }

            return analyte;
        }
    }.anonymous);
}

/// p^N
pub fn manyN(parser: anytype, count: usize) type {
    return Parser(struct {
        fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            var analyte = try Analyte.ok(allocator, text);

            for (0..count) |_| {
                const analyte2 = try extractParsingFunction(parser)(allocator, analyte.subsequent);
                defer analyte2.deinit();

                if (analyte2.answer == Analyte.Answer.err) {
                    analyte.deinit();
                    return try Analyte.err(allocator, text);
                }

                try analyte.merge(analyte2);
            }

            return analyte;
        }
    }.anonymous);
}

/// p?
pub fn optional(parser: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            var analyte = try extractParsingFunction(parser)(allocator, text);

            return if (analyte.answer == Analyte.Answer.ok)
                analyte
            else blk: {
                analyte.deinit();
                break :blk try Analyte.ok(allocator, text);
            };
        }
    }.anonymous);
}

/// &p
pub fn predict(parser: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            var analyte = try extractParsingFunction(parser)(allocator, text);
            defer analyte.deinit();

            return if (analyte.answer == Analyte.Answer.ok)
                Analyte.ok(allocator, text)
            else
                Analyte.err(allocator, text);
        }
    }.anonymous);
}

/// !p
pub fn notPredict(parser: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            var analyte = try extractParsingFunction(parser)(allocator, text);
            defer analyte.deinit();

            return if (analyte.answer == Analyte.Answer.ok)
                Analyte.err(allocator, text)
            else
                Analyte.ok(allocator, text);
        }
    }.anonymous);
}


/// p1 >> p2
pub fn sequence2(parser1: anytype, parser2: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            var analyte = try extractParsingFunction(parser1)(allocator, text);
            if (analyte.answer == Analyte.Answer.err)
                return analyte;

            const analyte2 = try extractParsingFunction(parser2)(allocator, analyte.subsequent);
            defer analyte2.deinit();

            try analyte.merge(analyte2);
            return analyte;
        }
    }.anonymous);
}

/// p1 >> p2 >> p3
pub fn sequence3(parser1: anytype, parser2: anytype, parser3: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            var analyte = try extractParsingFunction(sequence2(parser1, parser2))(allocator, text);
            if (analyte.answer == Analyte.Answer.err)
                return analyte;

            const analyte2 = try extractParsingFunction(parser3)(allocator, analyte.subsequent);
            defer analyte2.deinit();

            try analyte.merge(analyte2);
            return analyte;
        }
    }.anonymous);
}

/// p1 >> p2 >> p3 >> p4
pub fn sequence4(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            var analyte = try extractParsingFunction(sequence3(parser1, parser2, parser3))(allocator, text);
            if (analyte.answer == Analyte.Answer.err)
                return analyte;

            const analyte2 = try extractParsingFunction(parser4)(allocator, analyte.subsequent);
            defer analyte2.deinit();

            try analyte.merge(analyte2);
            return analyte;
        }
    }.anonymous);
}

/// p1 >> p2 >> p3 >> p4 >> p5
pub fn sequence5(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            var analyte = try extractParsingFunction(sequence4(parser1, parser2, parser3, parser4))(allocator, text);
            if (analyte.answer == Analyte.Answer.err)
                return analyte;

            const analyte2 = try extractParsingFunction(parser5)(allocator, analyte.subsequent);
            defer analyte2.deinit();

            try analyte.merge(analyte2);
            return analyte;
        }
    }.anonymous);
}

/// p1 >> p2 >> p3 >> p4 >> p5 >> p6
pub fn sequence6(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            var analyte = try extractParsingFunction(sequence5(parser1, parser2, parser3, parser4, parser5))(allocator, text);
            if (analyte.answer == Analyte.Answer.err)
                return analyte;

            const analyte2 = try extractParsingFunction(parser6)(allocator, analyte.subsequent);
            defer analyte2.deinit();

            try analyte.merge(analyte2);
            return analyte;
        }
    }.anonymous);
}

/// p1 >> p2 >> p3 >> p4 >> p5 >> p6 >> p7
pub fn sequence7(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            var analyte = try extractParsingFunction(sequence6(parser1, parser2, parser3, parser4, parser5, parser6))(allocator, text);
            if (analyte.answer == Analyte.Answer.err)
                return analyte;

            const analyte2 = try extractParsingFunction(parser7)(allocator, analyte.subsequent);
            defer analyte2.deinit();

            try analyte.merge(analyte2);
            return analyte;
        }
    }.anonymous);
}

/// p1 >> p2 >> p3 >> p4 >> p5 >> p6 >> p7 >> p8
pub fn sequence8(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype, parser8: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            var analyte = try extractParsingFunction(sequence7(parser1, parser2, parser3, parser4, parser5, parser6, parser7))(allocator, text);
            if (analyte.answer == Analyte.Answer.err)
                return analyte;

            const analyte2 = try extractParsingFunction(parser8)(allocator, analyte.subsequent);
            defer analyte2.deinit();

            try analyte.merge(analyte2);
            return analyte;
        }
    }.anonymous);
}

/// p1 >> p2 >> p3 >> p4 >> p5 >> p6 >> p7 >> p8 >> p9
pub fn sequence9(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype, parser8: anytype, parser9: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            var analyte = try extractParsingFunction(sequence8(parser1, parser2, parser3, parser4, parser5, parser6, parser7, parser8))(allocator, text);
            if (analyte.answer == Analyte.Answer.err)
                return analyte;

            const analyte2 = try extractParsingFunction(parser9)(allocator, analyte.subsequent);
            defer analyte2.deinit();

            try analyte.merge(analyte2);
            return analyte;
        }
    }.anonymous);
}

/// p1 >> p2 >> p3 >> p4 >> p5 >> p6 >> p7 >> p8 >> p9 >> p10
pub fn sequence10(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype, parser8: anytype, parser9: anytype, parser10: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            var analyte = try extractParsingFunction(sequence9(parser1, parser2, parser3, parser4, parser5, parser6, parser7, parser8, parser9))(allocator, text);
            if (analyte.answer == Analyte.Answer.err)
                return analyte;

            const analyte2 = try extractParsingFunction(parser10)(allocator, analyte.subsequent);
            defer analyte2.deinit();

            try analyte.merge(analyte2);
            return analyte;
        }
    }.anonymous);
}

/// p1 >> p2 >> p3 >> p4 >> p5 >> p6 >> p7 >> p8 >> p9 >> p10 >> p11
pub fn sequence11(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype, parser8: anytype, parser9: anytype, parser10: anytype, parser11: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            var analyte = try extractParsingFunction(sequence10(parser1, parser2, parser3, parser4, parser5, parser6, parser7, parser8, parser9, parser10))(allocator, text);
            if (analyte.answer == Analyte.Answer.err)
                return analyte;

            const analyte2 = try extractParsingFunction(parser11)(allocator, analyte.subsequent);
            defer analyte2.deinit();

            try analyte.merge(analyte2);
            return analyte;
        }
    }.anonymous);
}

/// p1 / p2
pub fn choice2(parser1: anytype, parser2: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            var analyte = try extractParsingFunction(parser1)(allocator, text);
            if (analyte.answer == Analyte.Answer.ok)
                return analyte;

            analyte.deinit();
            return try extractParsingFunction(parser2)(allocator, text);
        }
    }.anonymous);
}

/// p1 / p2 / p3
pub fn choice3(parser1: anytype, parser2: anytype, parser3: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            var analyte = try extractParsingFunction(choice2(parser1, parser2))(allocator, text);
            if (analyte.answer == Analyte.Answer.ok)
                return analyte;

            analyte.deinit();
            return try extractParsingFunction(parser3)(allocator, text);
        }
    }.anonymous);
}

/// p1 / p2 / p3 / p4
pub fn choice4(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            var analyte = try extractParsingFunction(choice3(parser1, parser2, parser3))(allocator, text);
            if (analyte.answer == Analyte.Answer.ok)
                return analyte;

            analyte.deinit();
            return try extractParsingFunction(parser4)(allocator, text);
        }
    }.anonymous);
}

/// p1 / p2 / p3 / p4 / p5
pub fn choice5(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            var analyte = try extractParsingFunction(choice4(parser1, parser2, parser3, parser4))(allocator, text);
            if (analyte.answer == Analyte.Answer.ok)
                return analyte;

            analyte.deinit();
            return try extractParsingFunction(parser5)(allocator, text);
        }
    }.anonymous);
}

/// p1 / p2 / p3 / p4 / p5 / p6
pub fn choice6(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            var analyte = try extractParsingFunction(choice5(parser1, parser2, parser3, parser4, parser5))(allocator, text);
            if (analyte.answer == Analyte.Answer.ok)
                return analyte;

            analyte.deinit();
            return try extractParsingFunction(parser6)(allocator, text);
        }
    }.anonymous);
}

/// p1 / p2 / p3 / p4 / p5 / p6 / p7
pub fn choice7(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            var analyte = try extractParsingFunction(choice6(parser1, parser2, parser3, parser4, parser5, parser6))(allocator, text);
            if (analyte.answer == Analyte.Answer.ok)
                return analyte;

            analyte.deinit();
            return try extractParsingFunction(parser7)(allocator, text);
        }
    }.anonymous);
}

/// p1 / p2 / p3 / p4 / p5 / p6 / p7 / p8
pub fn choice8(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype, parser8: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            var analyte = try extractParsingFunction(choice7(parser1, parser2, parser3, parser4, parser5, parser6, parser7))(allocator, text);
            if (analyte.answer == Analyte.Answer.ok)
                return analyte;

            analyte.deinit();
            return try extractParsingFunction(parser8)(allocator, text);
        }
    }.anonymous);
}

/// p1 / p2 / p3 / p4 / p5 / p6 / p7 / p8 / p9
pub fn choice9(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype, parser8: anytype, parser9: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            var analyte = try extractParsingFunction(choice8(parser1, parser2, parser3, parser4, parser5, parser6, parser7, parser8))(allocator, text);
            if (analyte.answer == Analyte.Answer.ok)
                return analyte;

            analyte.deinit();
            return try extractParsingFunction(parser9)(allocator, text);
        }
    }.anonymous);
}

/// p1 / p2 / p3 / p4 / p5 / p6 / p7 / p8 / p9 / p10
pub fn choice10(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype, parser8: anytype, parser9: anytype, parser10: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            var analyte = try extractParsingFunction(choice9(parser1, parser2, parser3, parser4, parser5, parser6, parser7, parser8, parser9))(allocator, text);
            if (analyte.answer == Analyte.Answer.ok)
                return analyte;

            analyte.deinit();
            return try extractParsingFunction(parser10)(allocator, text);
        }
    }.anonymous);
}

/// p1 / p2 / p3 / p4 / p5 / p6 / p7 / p8 / p9 / p10 / p11
pub fn choice11(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype, parser8: anytype, parser9: anytype, parser10: anytype, parser11: anytype) type {
    return Parser(struct {
        fn anonymous(allocator: mem.Allocator, text: ariadne.String) anyerror!Analyte {
            var analyte = try extractParsingFunction(choice10(parser1, parser2, parser3, parser4, parser5, parser6, parser7, parser8, parser9, parser10))(allocator, text);
            if (analyte.answer == Analyte.Answer.ok)
                return analyte;

            analyte.deinit();
            return try extractParsingFunction(parser11)(allocator, text);
        }
    }.anonymous);
}
