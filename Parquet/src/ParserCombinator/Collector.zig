const std = @import("std");
const ArrayList = std.ArrayList;
const heap = std.heap;
const io = std.io;
const Allocator = std.mem.Allocator;

const Base = @import("../Base.zig");
const String = Base.String;
const Analyte = @import("Analyte.zig").Analyte;
const ParsingFunction = @import("Parser.zig").ParsingFunction;
const Retriever = @import("Parser.zig").Retriever;


var accumulated: ArrayList(String) = undefined;

pub fn init(allocator: Allocator) void {
    accumulated = ArrayList(String).init(allocator);
}

pub fn deinit() void {
    for (accumulated.items) |item| {
        item.deinit();
    }

    accumulated.deinit();
}

pub fn strip() void {
    for (accumulated.items, 0..) |item, i| {
        if (item.isEmpty()) {
            _ = accumulated.orderedRemove(i);
        }
    }
}

pub fn get() []String {
    strip();
    return accumulated.items;
}

pub fn dump() anyerror!void {
    for (get()) |s| {
        try io.getStdOut().writer().print("{s}/", .{ s.getPrimitive() });
    }
}

pub fn this(parser: anytype) type {
    return struct {
        pub const body = struct {
            fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
                const analyte: Analyte = try Retriever.get(parser)(allocator, text);
                try accumulated.append(try analyte.consumed.initCopy());
                return analyte;
            }
        }.anonymous;
    };
}

pub fn backtrack(count: usize) type {
    return struct {
        pub const body = struct {
            fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
                for (0..count) |i| {
                    _ = i;
                    _ = accumulated.popOrNull();
                }
                return Analyte.initWithOk(allocator, text);
            }
        }.anonymous;
    };
}

pub fn print(parser: anytype, format: []const u8) type {
    return struct {
        pub const body = struct {
            fn anonymous(allocator: Allocator, text: String) anyerror!Analyte {
                const analyte: Analyte = try Retriever.get(parser)(allocator, text);
                try io.getStdOut().writer().print(format, .{ analyte.consumed.getPrimitive() });
                return analyte;
            }
        }.anonymous;
    };
}
