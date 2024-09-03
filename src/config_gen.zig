const std = @import("std");
const fatal = @import("utils.zig").fatal;

pub fn main() !void {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const args = try std.process.argsAlloc(arena);
    if (args.len != 3) fatal("specify output file name, and output folder name", .{});

    const output_file_path = args[1];
    const output_dir_path = args[2];

    var fout = try std.fs.cwd().createFile(output_file_path, .{});
    defer fout.close();

    // Some platform specifics

    // config.h as generated by configure for clang (used by zig)
    // except for some math operators which must not be defined (use math.h)
    // and some options which are multiplatform:
    // dlfcn
    // extended precision registers
    // fpu_x86_sse
    // ieee comparisons, denormals
    // inttypes
    // libm
    // strings (with the s!)
    // sys_stat, sys_types, unistd
    // ieee arithmetic interface
    // TODO: Make GSL_COMPLEX_LEGACY and HAVE_INLINE optional!
    try fout.writeAll(
        \\  #define HAVE_C99_INLINE 1
        \\  #define HAVE_INLINE 1
        \\  #define GSL_COMPLEX_LEGACY 1
        \\  #define HAVE_COMPLEX_H 0
        \\  #define HAVE_DECL_ACOSH 1
        \\  #define HAVE_DECL_ASINH 1
        \\  #define HAVE_DECL_ATANH 1
        \\  #define HAVE_DECL_EXPM 1
        \\  #define HAVE_DECL_FEENABLEEXCEPT 1
        \\  #define HAVE_DECL_FESETTRAPENABLE 0  
        \\  #define HAVE_DECL_FINITE 1
        \\  #define HAVE_DECL_FPRND_T 0
        \\  #define HAVE_DECL_FREXP 1
        \\  #define HAVE_DECL_HYPOT 1
        \\  #define HAVE_DECL_ISFINITE 1
        \\  #define HAVE_DECL_ISINF 1
        \\  #define HAVE_DECL_ISNAN 1
        \\  #define HAVE_DECL_LDEXP 1
        \\  #define HAVE_DECL_LOG1P 1
        \\  #define HAVE_EXIT_SUCCESS_AND_FAILURE 1
        \\  #define HAVE_MEMCPY 1
        \\  #define HAVE_MEMMOVE 1
        \\  #define HAVE_PRINTF_LONGDOUBLE 1
        \\  #define HAVE_STDINT_H 1
        \\  #define HAVE_STDIO_H 1
        \\  #define HAVE_STDLIB_H 1
        \\  #define HAVE_STRDUP 1
        \\  #define HAVE_STRING_H 1
        \\  #define HAVE_STRTOL 1
        \\  #define HAVE_STRTOUL 1
        \\  #define HAVE_VPRINTF 1
        \\  #define LT_OBJDIR ".libs/"
        \\  #define PACKAGE "gsl"
        \\  #define PACKAGE_BUGREPORT ""
        \\  #define PACKAGE_NAME "gsl"
        \\  #define PACKAGE_STRING "gsl 2.8"
        \\  #define PACKAGE_TARNAME "gsl"
        \\  #define PACKAGE_URL ""
        \\  #define PACKAGE_VERSION "2.8"
        \\  #define RELEASED
        \\  #define STDC_HEADERS 1
        \\  #define VERSION "2.8"
        \\  #if HAVE_EXTENDED_PRECISION_REGISTERS
        \\      #define GSL_COERCE_DBL(x) (gsl_coerce_double(x))
        \\  #else
        \\      #define GSL_COERCE_DBL(x) (x)
        \\  #endif
        \\  #ifdef __GNUC__
        \\      #define DISCARD_POINTER(p) do { ; } while(p ? 0 : 0);
        \\  #else
        \\      #define DISCARD_POINTER(p)
        \\  #endif
        \\  #if defined(GSL_RANGE_CHECK_OFF) || !defined(GSL_RANGE_CHECK)
        \\      #define GSL_RANGE_CHECK 0  /* turn off range checking by default internally */
        \\  #endif
        \\  #define RETURN_IF_NULL(x) if (!x) { return ; }
    );

    const works = try checkCCompiles("int main(void) {}", output_dir_path, arena);
    _ = works;

    return std.process.cleanExit();
}

fn checkCCompiles(code: []const u8, path: [:0]u8, alloc: std.mem.Allocator) !bool {
    const hash = std.hash.Crc32.hash(code);
    const file_path = try std.fmt.allocPrint(alloc, "{s}/{}.c", .{ path, hash });
    const ofile_path = try std.fmt.allocPrint(alloc, "{s}/{}.o", .{ path, hash });

    // Note that this file is already running in a "tmp" location, so we
    // can simply do this, we use the hash of the code string as filename
    {
        var fout = try std.fs.cwd().createFile(file_path, .{});
        defer fout.close();
        _ = try fout.write(code);
    }

    // Now we invoke zig to compile the C source
    const argv = [_][]const u8{ "zig", "cc", file_path, "-o", ofile_path };
    var child = std.process.Child.init(&argv, alloc);
    child.cwd = path;
    const res = try child.spawnAndWait();
    const ret = switch (res) {
        .Exited => |v| v == 0,
        // TODO: This could be made more robust by emitting an error message
        else => false,
    };

    return ret;
}
