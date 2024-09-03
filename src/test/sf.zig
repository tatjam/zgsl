const std = @import("std");
const gsl = @import("../wrap/zgsl.zig");

fn over_all_functions_filtered(
    str: type,
    filter: anytype,
    action: anytype,
    userdata: anytype,
) void {
    const sft = @typeInfo(str).@"struct";

    inline for (sft.decls) |decl| {
        const field = @TypeOf(@field(str, decl.name));
        switch (@typeInfo(field)) {
            .@"struct" => over_all_functions_filtered(
                field,
                filter,
                action,
                userdata,
            ),
            .@"fn" => |info| if (filter(info)) {
                action(@field(str, decl.name), userdata);
            },
            else => continue, // Ignore all non functions
        }
    }
}

inline fn is_single_arg_f64_e(f: std.builtin.Type.Fn) bool {
    return has_error_return(f) and f.params.len == 1 and f.params[0].type == f64;
}

inline fn has_error_return(f: std.builtin.Type.Fn) bool {
    if (f.return_type) |ret| {
        const ret_info = @typeInfo(ret);
        switch (ret_info) {
            .error_union => return true,
            else => return false,
        }
    }
    return false;
}

inline fn test_single_args_exceptions(f: anytype, v: f64) void {
    _ = f(v) catch {};
}

// This test calls all sf functions of a single argument
// (that generate errors) with fuzzed inputs, catching and
// ignoring all errors, but making sure no unknown ones are generated
test "fuzz_sf_single_args_exceptions" {
    // TODO: Once better fuzzing support is in zig, we won't need this hackish "manual fuzzing"
    const rnd = std.crypto.random;
    gsl.set_error_handler_off();

    for (0..1000000) |_| {
        // This generates plenty of invalid / weird float values!
        const v: f64 = @bitCast(rnd.int(i64));

        over_all_functions_filtered(
            gsl.sf,
            is_single_arg_f64_e,
            test_single_args_exceptions,
            v,
        );
    }
}
