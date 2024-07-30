const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const upstream = b.dependency("gsl", .{});

    const config_gen_tool = b.addExecutable(.{
        .name = "config_gen",
        .root_source_file = b.path("src/config_gen.zig"),
        .target = b.host
    });

    const config_gen_step = b.addRunArtifact(config_gen_tool);
    const config_file = config_gen_step.addOutputFileArg("config.h");
    _ = config_gen_step.addOutputDirectoryArg("cfiles");

    const gls_lib = b.addStaticLibrary(.{
        .name = "gsl",
        .optimize = optimize,
        .target = target
    });
    gls_lib.linkLibC();


    // All source files in gls
    gls_lib.addCSourceFiles(.{
        .root = upstream.path(""),
        .files = &.{
            "blas/blas.c"
        }
    });
    gls_lib.addIncludePath(upstream.path(""));
    gls_lib.addIncludePath(config_file.dirname());

    const lib = b.addStaticLibrary(.{
        .name = "zgsl",
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    lib.linkLibrary(gls_lib);

    b.installArtifact(lib);

    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);

    // For ZLS quick error reporting
    const lib_check = b.addTest(.{
        .name = "check",
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const check = b.step("check", "ZLS compile check (no binary emit)");
    check.dependOn(&lib_check.step);
}
