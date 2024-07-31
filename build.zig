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

    const symlink_gen_tool = b.addExecutable(.{
        .name = "symlink_gen",
        .root_source_file = b.path("src/symlink_gen.zig"),
        .target = b.host
    });

    const symlink_gen_step = b.addRunArtifact(symlink_gen_tool);
    // Inside this folder, a "gsl/" directory is created that contains symlinks
    // to all other gsl files, as done by default by a Makefile
    symlink_gen_step.addDirectoryArg(upstream.path(""));
    const gsl_files = symlink_gen_step.addOutputDirectoryArg("gsl_holder");
    
    const gsl_lib = b.addStaticLibrary(.{
        .name = "gsl",
        .optimize = optimize,
        .target = target
    });
    gsl_lib.linkLibC();


    // All source files in gls
    gsl_lib.addCSourceFiles(.{
        .root = upstream.path(""),
        .files = &.{
            "blas/blas.c"
        }
    });
    gsl_lib.addIncludePath(upstream.path(""));
    gsl_lib.addIncludePath(config_file.dirname());
    gsl_lib.addIncludePath(gsl_files);

    const lib = b.addStaticLibrary(.{
        .name = "zgsl",
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    lib.linkLibrary(gsl_lib);

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
