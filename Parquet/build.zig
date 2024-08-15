const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "Parquet",
        .root_source_file = b.path("src/Parquet.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(lib);


    const test_step = b.step("test", "Run unit tests");

    const Test_Base_String = b.addTest(.{
        .root_source_file = b.path("src/Test_Base_String.zig"),
        .target = target,
        .optimize = optimize,
    });
    test_step.dependOn(&b.addRunArtifact(Test_Base_String).step);

    const Test_ParserCombinator_Analyte = b.addTest(.{
        .root_source_file = b.path("src/Test_ParserCombinator_Analyte.zig"),
        .target = target,
        .optimize = optimize,
    });
    test_step.dependOn(&b.addRunArtifact(Test_ParserCombinator_Analyte).step);

    const Test_ParserCombinator_Parser = b.addTest(.{
        .root_source_file = b.path("src/Test_ParserCombinator_Parser.zig"),
        .target = target,
        .optimize = optimize,
    });
    test_step.dependOn(&b.addRunArtifact(Test_ParserCombinator_Parser).step);

    const Test_ParserCombinator_Combinators = b.addTest(.{
        .root_source_file = b.path("src/Test_ParserCombinator_Combinators.zig"),
        .target = target,
        .optimize = optimize,
    });
    test_step.dependOn(&b.addRunArtifact(Test_ParserCombinator_Combinators).step);

    const Test_ParserCombinator_Parsers = b.addTest(.{
        .root_source_file = b.path("src/Test_ParserCombinator_Parsers.zig"),
        .target = target,
        .optimize = optimize,
    });
    test_step.dependOn(&b.addRunArtifact(Test_ParserCombinator_Parsers).step);
}
