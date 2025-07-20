const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const ariadne_pkg = b.dependency("ariadne", .{
        .target   = target,
        .optimize = optimize,
    });

    const parquet_mod = b.addModule("parquet", .{
        .root_source_file = b.path("src/parquet.zig"),
        .target           = target,
        .optimize         = optimize,
        .imports = &.{
            .{ .name = "ariadne", .module = ariadne_pkg.module("ariadne") },
        },
    });

    const analyte_test = b.addTest(.{
        .root_source_file = b.path("test/test_analyte.zig"),
        .target           = target,
        .optimize         = optimize,
    });
    analyte_test.root_module.addImport("ariadne", ariadne_pkg.module("ariadne"));
    analyte_test.root_module.addImport("parquet", parquet_mod);

    const parser_test = b.addTest(.{
        .root_source_file = b.path("test/test_parser.zig"),
        .target           = target,
        .optimize         = optimize,
    });
    parser_test.root_module.addImport("ariadne", ariadne_pkg.module("ariadne"));
    parser_test.root_module.addImport("parquet", parquet_mod);

    const combinators_test = b.addTest(.{
        .root_source_file = b.path("test/test_combinators.zig"),
        .target           = target,
        .optimize         = optimize,
    });
    combinators_test.root_module.addImport("ariadne", ariadne_pkg.module("ariadne"));
    combinators_test.root_module.addImport("parquet", parquet_mod);

    const run_analyte_test = b.addRunArtifact(analyte_test);
    const run_parser_test = b.addRunArtifact(parser_test);
    const run_combinators_test = b.addRunArtifact(combinators_test);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_analyte_test.step);
    test_step.dependOn(&run_parser_test.step);
    test_step.dependOn(&run_combinators_test.step);

    const css_rgb_mod = b.createModule(.{
        .root_source_file = b.path("examples/css_rgb.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "ariadne", .module = ariadne_pkg.module("ariadne") },
            .{ .name = "parquet", .module = parquet_mod },
        },
    });

    const css_rgb_build_mod = b.createModule(.{
        .root_source_file = b.path("examples/css_rgb_build.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "ariadne", .module = ariadne_pkg.module("ariadne") },
            .{ .name = "parquet", .module = parquet_mod },
        },
    });

    const exe_css_rgb = b.addExecutable(.{
        .name = "css_rgb",
        .root_module = css_rgb_mod,
    });
    b.installArtifact(exe_css_rgb);

    const exe_css_rgb_build = b.addExecutable(.{
        .name = "css_rgb_build",
        .root_module = css_rgb_build_mod,
    });
    b.installArtifact(exe_css_rgb_build);

    const run_cmd_css_rgb = b.addRunArtifact(exe_css_rgb);
    const run_cmd_css_rgb_build = b.addRunArtifact(exe_css_rgb_build);

    run_cmd_css_rgb.step.dependOn(b.getInstallStep());
    run_cmd_css_rgb_build.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd_css_rgb.addArgs(args);
    }

    if (b.args) |args| {
        run_cmd_css_rgb_build.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd_css_rgb.step);
    run_step.dependOn(&run_cmd_css_rgb_build.step);
}
