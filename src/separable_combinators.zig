const std = @import("std");
const mem = std.mem;

const ariadne = @import("ariadne");
const Analyte = @import("analyte.zig").Analyte;
const ParsingFunction = @import("parser.zig").ParsingFunction;
const Parser = @import("parser.zig").Parser;
const extractParsingFunction = @import("parser.zig").extractParsingFunction;
const Combinators = @import("combinators.zig");
const Parsers = @import("parsers.zig");


/// p1 >> ... >> pn
pub fn sequence(parsers: anytype) type {
    if (@typeInfo(@TypeOf(parsers)) != .@"struct")
		@compileError("parsers as .{ Parser(ParsingFunction), ... } must be a struct.");

    return Combinators.sequence(blk: {
            var fnPtrs: [@typeInfo(@TypeOf(parsers)).@"struct".fields.len * 2 + 1]ParsingFunction = undefined;
            fnPtrs[0] = extractParsingFunction(Parsers.seps);
            for (parsers, 0..) |parser, i| {
                fnPtrs[1 + i * 2] = extractParsingFunction(parser);
                fnPtrs[1 + i * 2 + 1] = extractParsingFunction(Parsers.seps);
            }
            break :blk fnPtrs;
    });
}

/// p1 / ... / pn
pub fn choice(parsers: anytype) type {
    if (@typeInfo(@TypeOf(parsers)) != .@"struct")
		@compileError("parsers as .{ Parser(ParsingFunction), ... } must be a struct.");

    return Combinators.choice(blk: {
            var fnPtrs: [@typeInfo(@TypeOf(parsers)).@"struct".fields.len * 2 + 1]ParsingFunction = undefined;
            fnPtrs[0] = extractParsingFunction(Parsers.seps);
            for (parsers, 0..) |parser, i| {
                fnPtrs[1 + i * 2] = extractParsingFunction(parser);
                fnPtrs[1 + i * 2 + 1] = extractParsingFunction(Parsers.seps);
            }
            break :blk fnPtrs;
    });
}

/// p*
pub fn many0(parser: anytype) type {
    return Combinators.many0(
        Combinators.sequence3(
            Parsers.seps0,
            parser,
            Parsers.seps0
        )
    );
}

/// p+
pub fn many1(parser: anytype) type {
    return Combinators.many1(
        Combinators.sequence3(
            Parsers.seps0,
            parser,
            Parsers.seps0
        )
    );
}

/// p^N
pub fn manyN(parser: anytype, count: usize) type {
    return Combinators.manyN(
        Combinators.sequence3(
            Parsers.seps0,
            parser,
            Parsers.seps0
        ),
        count
    );
}

/// p?
pub fn optional(parser: anytype) type {
    return Combinators.optional(
        Combinators.sequence3(
            Parsers.seps0,
            parser,
            Parsers.seps0
        )
    );
}

/// &p
pub fn predict(parser: anytype) type {
    return Combinators.predict(
        Combinators.sequence3(
            Parsers.seps0,
            parser,
            Parsers.seps0
        )
    );
}

/// !p
pub fn notPredict(parser: anytype) type {
    return Combinators.notPredict(
        Combinators.sequence3(
            Parsers.seps0,
            parser,
            Parsers.seps0
        )
    );
}


/// p1 >> p2
pub fn sequence2(parser1: anytype, parser2: anytype) type {
    return Combinators.sequence5(
        Parsers.seps0,
        parser1,
        Parsers.seps0,
        parser2,
        Parsers.seps0
    );
}

/// p1 >> p2 >> p3
pub fn sequence3(parser1: anytype, parser2: anytype, parser3: anytype) type {
    return Combinators.sequence3(
        sequence2(parser1, parser2),
        parser3,
        Parsers.seps0
    );
}

/// p1 >> p2 >> p3 >> p4
pub fn sequence4(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype) type {
    return Combinators.sequence3(
        sequence3(parser1, parser2, parser3),
        parser4,
        Parsers.seps0
    );
}

/// p1 >> p2 >> p3 >> p4 >> p5
pub fn sequence5(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype) type {
    return Combinators.sequence3(
        sequence4(parser1, parser2, parser3, parser4),
        parser5,
        Parsers.seps0
    );
}

/// p1 >> p2 >> p3 >> p4 >> p5 >> p6
pub fn sequence6(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype) type {
    return Combinators.sequence3(
        sequence5(parser1, parser2, parser3, parser4, parser5),
        parser6,
        Parsers.seps0
    );
}

/// p1 >> p2 >> p3 >> p4 >> p5 >> p6 >> p7
pub fn sequence7(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype) type {
    return Combinators.sequence3(
        sequence6(parser1, parser2, parser3, parser4, parser5, parser6),
        parser7,
        Parsers.seps0
    );
}

/// p1 >> p2 >> p3 >> p4 >> p5 >> p6 >> p7 >> p8
pub fn sequence8(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype, parser8: anytype) type {
    return Combinators.sequence3(
        sequence7(parser1, parser2, parser3, parser4, parser5, parser6, parser7),
        parser8,
        Parsers.seps0
    );
}

/// p1 >> p2 >> p3 >> p4 >> p5 >> p6 >> p7 >> p8 >> p9
pub fn sequence9(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype, parser8: anytype, parser9: anytype) type {
    return Combinators.sequence3(
        sequence8(parser1, parser2, parser3, parser4, parser5, parser6, parser7, parser8),
        parser9,
        Parsers.seps0
    );
}

/// p1 >> p2 >> p3 >> p4 >> p5 >> p6 >> p7 >> p8 >> p9 >> p10
pub fn sequence10(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype, parser8: anytype, parser9: anytype, parser10: anytype) type {
    return Combinators.sequence3(
        sequence9(parser1, parser2, parser3, parser4, parser5, parser6, parser7, parser8, parser9),
        parser10,
        Parsers.seps0
    );
}

/// p1 >> p2 >> p3 >> p4 >> p5 >> p6 >> p7 >> p8 >> p9 >> p10 >> p11
pub fn sequence11(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype, parser8: anytype, parser9: anytype, parser10: anytype, parser11: anytype) type {
    return Combinators.sequence3(
        sequence10(parser1, parser2, parser3, parser4, parser5, parser6, parser7, parser8, parser9, parser10),
        parser11,
        Parsers.seps0
    );
}

/// p1 / p2
pub fn choice2(parser1: anytype, parser2: anytype) type {
    return Combinators.choice2(
        Combinators.sequence3(Parsers.seps0, parser1, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser2, Parsers.seps0)
    );
}

/// p1 / p2 / p3
pub fn choice3(parser1: anytype, parser2: anytype, parser3: anytype) type {
    return Combinators.choice3(
        Combinators.sequence3(Parsers.seps0, parser1, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser2, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser3, Parsers.seps0)
    );
}

/// p1 / p2 / p3 / p4
pub fn choice4(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype) type {
    return Combinators.choice4(
        Combinators.sequence3(Parsers.seps0, parser1, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser2, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser3, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser4, Parsers.seps0)
    );
}

/// p1 / p2 / p3 / p4 / p5
pub fn choice5(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype) type {
    return Combinators.choice5(
        Combinators.sequence3(Parsers.seps0, parser1, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser2, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser3, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser4, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser5, Parsers.seps0)
    );
}

/// p1 / p2 / p3 / p4 / p5 / p6
pub fn choice6(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype) type {
    return Combinators.choice6(
        Combinators.sequence3(Parsers.seps0, parser1, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser2, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser3, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser4, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser5, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser6, Parsers.seps0)
    );
}

/// p1 / p2 / p3 / p4 / p5 / p6 / p7
pub fn choice7(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype) type {
    return Combinators.choice7(
        Combinators.sequence3(Parsers.seps0, parser1, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser2, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser3, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser4, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser5, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser6, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser7, Parsers.seps0)
    );
}

/// p1 / p2 / p3 / p4 / p5 / p6 / p7 / p8
pub fn choice8(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype, parser8: anytype) type {
    return Combinators.choice8(
        Combinators.sequence3(Parsers.seps0, parser1, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser2, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser3, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser4, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser5, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser6, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser7, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser8, Parsers.seps0)
    );
}

/// p1 / p2 / p3 / p4 / p5 / p6 / p7 / p8 / p9
pub fn choice9(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype, parser8: anytype, parser9: anytype) type {
    return Combinators.choice9(
        Combinators.sequence3(Parsers.seps0, parser1, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser2, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser3, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser4, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser5, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser6, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser7, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser8, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser9, Parsers.seps0)
    );
}

/// p1 / p2 / p3 / p4 / p5 / p6 / p7 / p8 / p9 / p10
pub fn choice10(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype, parser8: anytype, parser9: anytype, parser10: anytype) type {
    return Combinators.choice10(
        Combinators.sequence3(Parsers.seps0, parser1, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser2, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser3, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser4, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser5, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser6, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser7, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser8, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser9, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser10, Parsers.seps0)
    );
}

/// p1 / p2 / p3 / p4 / p5 / p6 / p7 / p8 / p9 / p10 / p11
pub fn choice11(parser1: anytype, parser2: anytype, parser3: anytype, parser4: anytype, parser5: anytype, parser6: anytype, parser7: anytype, parser8: anytype, parser9: anytype, parser10: anytype, parser11: anytype) type {
    return Combinators.choice11(
        Combinators.sequence3(Parsers.seps0, parser1, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser2, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser3, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser4, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser5, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser6, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser7, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser8, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser9, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser10, Parsers.seps0),
        Combinators.sequence3(Parsers.seps0, parser11, Parsers.seps0)
    );
}
