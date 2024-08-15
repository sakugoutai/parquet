const std = @import("std");
const fs = std.fs;
const File = fs.File;
const mem = std.mem;
const Allocator = mem.Allocator;


pub const String = struct {

    allocator: Allocator,
    text: []u8,

    pub const Error = error{
        OutOfIndex,
        IncorrectIndex,
        NonexistentCharacter,
    };

    pub fn init(allocator: Allocator, str: []const u8) Allocator.Error!String {
        const s: String = String {
            .allocator = allocator,
            .text = try allocator.alloc(u8, str.len),
        };
        mem.copyForwards(u8, s.text, str);

        return s;
    }

    pub fn initWithConcat(allocator: Allocator, str1: []const u8, str2: []const u8) Allocator.Error!String {
        const s: String = String {
            .allocator = allocator,
            .text = try allocator.alloc(u8, str1.len + str2.len),
        };
        mem.copyForwards(u8, s.text[0..str1.len], str1);
        mem.copyForwards(u8, s.text[str1.len..], str2);

        return s;
    }

    pub fn initWithNonConst(allocator: Allocator, str: []u8) Allocator.Error!String {
        const s: String = String {
            .allocator = allocator,
            .text = try allocator.alloc(u8, str.len),
        };
        mem.copyForwards(u8, s.text, str);

        return s;
    }

    pub fn initWithConcatNonConst(allocator: Allocator, str1: []u8, str2: []u8) Allocator.Error!String {
        const s: String = String {
            .allocator = allocator,
            .text = try allocator.alloc(u8, str1.len + str2.len),
        };
        mem.copyForwards(u8, s.text[0..str1.len], str1);
        mem.copyForwards(u8, s.text[str1.len..], str2);

        return s;
    }

    pub fn initFromString(allocator: Allocator, str: String) Allocator.Error!String {
        return try initWithNonConst(allocator, str.getPrimitive());
    }

    pub fn initWithSuffixString(self: String, str: String) Allocator.Error!String {
        return try String.initWithConcatNonConst(self.allocator, self.getPrimitive(), str.getPrimitive());
    }

    pub fn initCopy(self: String) Allocator.Error!String {
        return try String.init(self.allocator, self.getPrimitive());
    }

    pub fn initFromChar(allocator: Allocator, c: u8) Allocator.Error!String {
        return try String.init(allocator, &[_]u8{c});
    }

    pub fn initFromFile(allocator: Allocator, path: []const u8) (File.OpenError || File.GetSeekPosError || Allocator.Error || File.ReadError)!String {
        const file = try fs.cwd().openFile(path, .{ .mode = .read_only });
        defer file.close();

        const file_size: usize = try file.getEndPos();
        const text: []u8 = try allocator.alloc(u8, file_size);
        const read_size: usize = try file.readAll(text);

        return String {
            .allocator = allocator,
            .text = text[0..read_size],
        };
    }

    pub fn deinit(self: String) void {
        self.allocator.free(self.text);
    }

    pub fn getPrimitive(self: String) []u8 {
        return self.text;
    }

    pub fn getLength(self: String) usize {
        return self.text.len;
    }

    pub fn getCharAt(self: String, index: usize) Error!u8 {
        if (self.getLength() <= index)
            return Error.OutOfIndex;

        return self.getPrimitive()[index];
    }

    pub fn getHeadChar(self: String) Error!u8 {
        if (self.isEmpty())
            return Error.OutOfIndex;

        return self.getPrimitive()[0];
    }

    pub fn substring(self: String, beginIndex: usize, lastIndex: usize) (Error || Allocator.Error)!String {
        if (!(beginIndex <= lastIndex))
            return Error.IncorrectIndex;

        if (!(beginIndex <= self.getLength() and lastIndex <= self.getLength()))
            return Error.OutOfIndex;

        return try String.init(self.allocator, self.getPrimitive()[beginIndex..lastIndex]);
    }

    pub fn isEmpty(self: String) bool {
        return self.getLength() == 0;
    }

    pub fn equals(self: String, str: String) bool {
        return mem.eql(u8, self.getPrimitive(), str.getPrimitive());
    }

    pub fn startsWith(self: String, str: String) bool {
        return std.mem.startsWith(u8, self.getPrimitive(), str.getPrimitive());
    }

    pub fn startsWithChar(self: String, c: u8) bool {
        if (self.isEmpty()) return false;

        return self.getPrimitive()[0] == c;
    }

    pub fn firstIndexOf(self: String, c: u8) Error!usize {
        for (0..(self.getLength() - 1)) |i| {
            if (try self.getCharAt(i) == c)
                return i;
        }
        return Error.NonexistentCharacter;
    }

    pub fn lastIndexOf(self: String, c: u8) Error!usize {
        for (0..(self.getLength() - 1)) |i| {
            const j = (self.getLength() - 1) - i;

            if (try self.getCharAt(j) == c)
                return j;
        }
        return Error.NonexistentCharacter;
    }
};
