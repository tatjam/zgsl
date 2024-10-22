const std = @import("std");
const parser = @import("c_parse.zig");

const ExceptionsPossible = struct {
    failure: bool = false,
    cont: bool = false,
    domain: bool = false,
    range: bool = false,
    invalid_ptr: bool = false,
    invalid_value: bool = false,
    generic_failure: bool = false,
    factor: bool = false,
    sanity: bool = false,
    no_mem: bool = false,
    bad_func: bool = false,
    run_away: bool = false,
    max_iter: bool = false,
    zero_div: bool = false,
    bad_tol: bool = false,
    tol: bool = false,
    underflow: bool = false,
    overflow: bool = false,
    loss: bool = false,
    round: bool = false,
    bad_len: bool = false,
    not_square: bool = false,
    singular: bool = false,
    diverge: bool = false,
    unsup: bool = false,
    unimpl: bool = false,
    cache: bool = false,
    table: bool = false,
    no_prog: bool = false,
    no_prog_j: bool = false,
    tol_f: bool = false,
    tol_x: bool = false,
    tol_g: bool = false,
};

// argument, converted to slice, is checked as
// slice.len == max - min + 1, only in debug builds!
pub const BoundCheckedArg = struct { idx: usize, min: []u8, max: []u8 };

// Autogenerated reasonably, some stuff manually input
pub const FunctionConfig = struct {
    fun: parser.ParsedCFunction,
    // Only if return type is int (of fun) These exceptions then will be
    // handled as Zig errors! Any unhandled exception will return in a
    // (debug) runtime error, to facilitate catching forgotten exceptions
    exceptions: ExceptionsPossible,

    // Indices into the function arguments, that are converted instead to an anonymous return struct
    // (or single return value if only one is present)
    ret_args: ?[]usize,
    // Arguments which are bound checked (turned into a slice and its len checked)
    // (Note that such arguments may not be ret_args! This prevents allocations inside the function)
    bound_checked_args: ?[]BoundCheckedArg,
};

pub fn set_exceptions(fun: *FunctionConfig, val: bool) void {
    const tinfo = comptime @typeInfo(ExceptionsPossible).@"struct";
    inline for (tinfo.fields) |field| {
        @field(fun.exceptions, field.name) = val;
    }
}

pub fn all_set(fun: FunctionConfig) bool {
    const tinfo = comptime @typeInfo(ExceptionsPossible).@"struct";
    inline for (tinfo.fields) |field| {
        if (!@field(fun.exceptions, field.name)) {
            return false;
        }
    }
    return true;
}

pub fn make_default_config(fun: parser.ParsedCFunction) !FunctionConfig {
    var out: FunctionConfig = undefined;
    out.fun = fun;

    set_exceptions(&out, false);
    var has_any = false;
    // try to parse exceptions from doc, if any
    for (fun.exceptions) |excp| {
        if (std.mem.eql(u8, excp, "GSL_EDOM")) {
            out.exceptions.domain = true;
        } else if (std.mem.eql(u8, excp, "GSL_ERANGE")) {
            out.exceptions.range = true;
        } else if (std.mem.eql(u8, excp, "GSL_EFAULT")) {
            out.exceptions.invalid_ptr = true;
        } else if (std.mem.eql(u8, excp, "GSL_EINVAL")) {
            out.exceptions.invalid_value = true;
        } else if (std.mem.eql(u8, excp, "GSL_EFAILED")) {
            out.exceptions.generic_failure = true;
        } else if (std.mem.eql(u8, excp, "GSL_EFACTOR")) {
            out.exceptions.factor = true;
        } else if (std.mem.eql(u8, excp, "GSL_ESANITY")) {
            out.exceptions.sanity = true;
        } else if (std.mem.eql(u8, excp, "GSL_ENOMEM")) {
            out.exceptions.no_mem = true;
        } else if (std.mem.eql(u8, excp, "GSL_EBADFUNC")) {
            out.exceptions.bad_func = true;
        } else if (std.mem.eql(u8, excp, "GSL_ERUNAWAY")) {
            out.exceptions.run_away = true;
        } else if (std.mem.eql(u8, excp, "GSL_EMAXITER")) {
            out.exceptions.max_iter = true;
        } else if (std.mem.eql(u8, excp, "GSL_EZERODIV")) {
            out.exceptions.zero_div = true;
        } else if (std.mem.eql(u8, excp, "GSL_EBADTOL")) {
            out.exceptions.bad_tol = true;
        } else if (std.mem.eql(u8, excp, "GSL_ETOL")) {
            out.exceptions.tol = true;
        } else if (std.mem.eql(u8, excp, "GSL_EUNDRFLW")) {
            out.exceptions.underflow = true;
        } else if (std.mem.eql(u8, excp, "GSL_EOVRFLW")) {
            out.exceptions.overflow = true;
        } else if (std.mem.eql(u8, excp, "GSL_ELOSS")) {
            out.exceptions.loss = true;
        } else if (std.mem.eql(u8, excp, "GSL_EROUND")) {
            out.exceptions.round = true;
        } else if (std.mem.eql(u8, excp, "GSL_EBADLEN")) {
            out.exceptions.bad_len = true;
        } else if (std.mem.eql(u8, excp, "GSL_ENOTSQR")) {
            out.exceptions.not_square = true;
        } else if (std.mem.eql(u8, excp, "GSL_ESING")) {
            out.exceptions.singular = true;
        } else if (std.mem.eql(u8, excp, "GSL_EDIVERGE")) {
            out.exceptions.diverge = true;
        } else if (std.mem.eql(u8, excp, "GSL_EUNSUP")) {
            out.exceptions.unsup = true;
        } else if (std.mem.eql(u8, excp, "GSL_EUNIMPL")) {
            out.exceptions.unimpl = true;
        } else if (std.mem.eql(u8, excp, "GSL_ECACHE")) {
            out.exceptions.cache = true;
        } else if (std.mem.eql(u8, excp, "GSL_ETABLE")) {
            out.exceptions.table = true;
        } else if (std.mem.eql(u8, excp, "GSL_ENOPROG")) {
            out.exceptions.no_prog = true;
        } else if (std.mem.eql(u8, excp, "GSL_ENOPROGJ")) {
            out.exceptions.no_prog_j = true;
        } else if (std.mem.eql(u8, excp, "GSL_ETOLF")) {
            out.exceptions.tol_f = true;
        } else if (std.mem.eql(u8, excp, "GSL_ETOLX")) {
            out.exceptions.tol_x = true;
        } else if (std.mem.eql(u8, excp, "GSL_ETOLG")) {
            out.exceptions.tol_g = true;
        } else if (std.mem.eql(u8, excp, "none")) {
            // No exceptions, just ignore (has_any will be set to true)
        } else {
            std.log.err("Unknown exception string {s}", .{excp});
            unreachable;
        }

        has_any = true;
    }

    // Worst case scenario, assume every one is possible
    if (!has_any) {
        set_exceptions(&out, true);
    }

    out.ret_args = null;
    out.bound_checked_args = null;

    return out;
}

pub fn has_errors(cfg: FunctionConfig) bool {
    return std.mem.eql(u8, cfg.fun.rettype, "int");
}

pub fn build_errors(alloc: std.mem.Allocator, cfg: FunctionConfig) ![]u8 {
    var out = std.ArrayList(u8).init(alloc);
    if (!has_errors(cfg)) {
        return out.toOwnedSlice();
    }

    try out.appendSlice("error{");
    if (cfg.exceptions.failure) {
        try out.appendSlice("Failure,");
    }
    if (cfg.exceptions.cont) {
        try out.appendSlice("Continue,");
    }
    if (cfg.exceptions.domain) {
        try out.appendSlice("Domain,");
    }
    if (cfg.exceptions.range) {
        try out.appendSlice("Range,");
    }
    if (cfg.exceptions.invalid_ptr) {
        try out.appendSlice("InvalidPointer,");
    }
    if (cfg.exceptions.invalid_value) {
        try out.appendSlice("InvalidValue,");
    }
    if (cfg.exceptions.generic_failure) {
        try out.appendSlice("GenericFailure,");
    }
    if (cfg.exceptions.factor) {
        try out.appendSlice("Factorization,");
    }
    if (cfg.exceptions.sanity) {
        try out.appendSlice("SanityCheck,");
    }
    if (cfg.exceptions.no_mem) {
        try out.appendSlice("NoMemory,");
    }
    if (cfg.exceptions.bad_func) {
        try out.appendSlice("BadFunction,");
    }
    if (cfg.exceptions.run_away) {
        try out.appendSlice("RunAway,");
    }
    if (cfg.exceptions.max_iter) {
        try out.appendSlice("MaxIter,");
    }
    if (cfg.exceptions.zero_div) {
        try out.appendSlice("ZeroDiv,");
    }
    if (cfg.exceptions.bad_tol) {
        try out.appendSlice("BadTolerance,");
    }
    if (cfg.exceptions.tol) {
        try out.appendSlice("Tolerance,");
    }
    if (cfg.exceptions.underflow) {
        try out.appendSlice("Underflow,");
    }
    if (cfg.exceptions.overflow) {
        try out.appendSlice("Overflow,");
    }
    if (cfg.exceptions.loss) {
        try out.appendSlice("LossOfAccuracy,");
    }
    if (cfg.exceptions.round) {
        try out.appendSlice("Roundoff,");
    }
    if (cfg.exceptions.bad_len) {
        try out.appendSlice("BadLength,");
    }
    if (cfg.exceptions.not_square) {
        try out.appendSlice("NotSquare,");
    }
    if (cfg.exceptions.singular) {
        try out.appendSlice("Singularity,");
    }
    if (cfg.exceptions.diverge) {
        try out.appendSlice("Divergent,");
    }
    if (cfg.exceptions.unsup) {
        try out.appendSlice("Unsupported,");
    }
    if (cfg.exceptions.unimpl) {
        try out.appendSlice("Unimplemented,");
    }
    if (cfg.exceptions.cache) {
        try out.appendSlice("CacheLimit,");
    }
    if (cfg.exceptions.table) {
        try out.appendSlice("TableLimit,");
    }
    if (cfg.exceptions.no_prog) {
        try out.appendSlice("NoProgress,");
    }
    if (cfg.exceptions.no_prog_j) {
        try out.appendSlice("NoProgressJacobian,");
    }
    if (cfg.exceptions.tol_f) {
        try out.appendSlice("ToleranceF,");
    }
    if (cfg.exceptions.tol_x) {
        try out.appendSlice("ToleranceX,");
    }
    if (cfg.exceptions.tol_g) {
        try out.appendSlice("ToleranceG,");
    }

    try out.appendSlice("}");

    return try out.toOwnedSlice();
}

fn build_ret_single(out: *std.ArrayList(u8), rtype: []u8) !void {
    if (std.mem.eql(u8, rtype, "gsl_sf_result *")) {
        try out.appendSlice("Result");
    } else if (std.mem.eql(u8, rtype, "gsl_sf_result_e10 *")) {
        try out.appendSlice("ResultE10");
    } else {
        try out.appendSlice(convert_type_to_zig(rtype));
    }
}

// There are two possibilities:
// - Bare, single return value
// - Various return values in anonymous struct
pub fn build_ret(alloc: std.mem.Allocator, cfg: FunctionConfig) ![]u8 {
    var out = std.ArrayList(u8).init(alloc);
    if (cfg.ret_args) |ret_args| {
        if (ret_args.len == 1) {
            try build_ret_single(&out, cfg.fun.arg_types[ret_args[0]]);
        } else {
            // Anonymous struct
            try out.appendSlice("struct {");
            for (ret_args) |idx| {
                try out.appendSlice(cfg.fun.arg_names[idx]);
                try out.appendSlice(": ");
                try build_ret_single(&out, cfg.fun.arg_types[idx]);
                try out.appendSlice(", ");
            }
            try out.appendSlice("}");
        }
    } else if (cfg.bound_checked_args) |_| {
        try out.appendSlice("void");
    } else {
        // Must be a single return value
        try build_ret_single(&out, cfg.fun.rettype);
    }
    return out.toOwnedSlice();
}

// Zig parameters are always const, so we don't care about the C specifier
pub fn sanify_typ(typ: []const u8) []const u8 {
    if (std.mem.startsWith(u8, typ, "const ")) {
        return sanify_typ(typ[6..]);
    }

    return std.mem.trim(u8, typ, " ");
}

pub fn convert_type_to_zig(typ: []const u8) []const u8 {
    const sane_typ = sanify_typ(typ);

    if (std.mem.eql(u8, sane_typ, "double")) {
        return "f64";
    } else if (std.mem.eql(u8, sane_typ, "int")) {
        return "i32";
    } else if (std.mem.eql(u8, sane_typ, "unsigned int")) {
        return "u32";
    } else if (std.mem.eql(u8, sane_typ, "gsl_mode_t")) {
        return "Precision";
    } else if (std.mem.eql(u8, sane_typ, "double *")) {
        // Cast to non pointer, this is a return type!
        return "f64";
    }

    unreachable;
}

pub fn convert_sliced_type_to_zig(typ: []const u8) []const u8 {
    if (std.mem.eql(u8, typ, "double *")) {
        return "f64";
    }

    unreachable;
}

fn check_is_ret_arg(idx: usize, cfg: FunctionConfig) bool {
    if (cfg.ret_args) |ret_args| {
        for (ret_args) |ridx| {
            if (idx == ridx) return true;
        }
    }
    return false;
}

fn get_as_bound_checked(idx: usize, cfg: FunctionConfig) ?BoundCheckedArg {
    if (cfg.bound_checked_args) |bcheck_args| {
        for (bcheck_args) |bcheck| {
            if (bcheck.idx == idx) return bcheck;
        }
    }
    return null;
}

// Removes return arguments
// Converts bound checked args to slices
// Keeps argument ordering!
pub fn build_args(alloc: std.mem.Allocator, cfg: FunctionConfig) ![]u8 {
    var out = std.ArrayList(u8).init(alloc);

    for (cfg.fun.arg_names, cfg.fun.arg_types, 0..) |name, typ, idx| {
        if (check_is_ret_arg(idx, cfg)) continue;
        const as_bound_checked = get_as_bound_checked(idx, cfg);
        if (as_bound_checked) |bchecked| {
            _ = bchecked;
            try out.appendSlice(name);
            try out.appendSlice(": ");
            try out.appendSlice("[]");
            try out.appendSlice(convert_sliced_type_to_zig(typ));
            try out.appendSlice(", ");
        } else {
            // We do no conversion to the arg, simply use Zig syntax
            try out.appendSlice(name);
            try out.appendSlice(": ");
            try out.appendSlice(convert_type_to_zig(typ));
            try out.appendSlice(", ");
        }
    }

    return out.toOwnedSlice();
}

pub fn build_invoke(alloc: std.mem.Allocator, cfg: FunctionConfig) ![]u8 {
    var out = std.ArrayList(u8).init(alloc);

    // Relatively simple, we just declare the return arguments...
    if (cfg.ret_args) |ret_args| {
        for (ret_args) |idx| {
            try out.appendSlice("var ");
            try out.appendSlice(cfg.fun.arg_names[idx]);
            try out.appendSlice(": ");
            try build_ret_single(&out, cfg.fun.arg_types[idx]);
            try out.appendSlice(" = undefined;\n");
        }
    }

    // Inserts bound checking for slices, to prevent out of bound access
    // which is totally ignored by GSL (of course, unless it segfaults!)
    for (cfg.fun.arg_names, 0..) |name, idx| {
        const as_bcheck = get_as_bound_checked(idx, cfg);
        if (as_bcheck) |bcheck| {
            try out.appendSlice("std.debug.assert(");
            try out.appendSlice(name);
            // We are fairly strict with the equality, the user can always pass sub-slices
            try out.appendSlice(".len == ");
            try out.appendSlice(bcheck.max);
            try out.appendSlice(" - ");
            try out.appendSlice(bcheck.min);
            try out.appendSlice(" + 1);\n");
        }
    }

    // Invoke the function, and store its return value
    try out.appendSlice("const ret = ");
    try out.appendSlice("c_gsl.");
    try out.appendSlice(cfg.fun.name);
    try out.appendSlice("(");
    for (cfg.fun.arg_names, 0..) |name, idx| {
        const is_ret_arg = check_is_ret_arg(idx, cfg);
        const as_bcheck = get_as_bound_checked(idx, cfg);
        if (is_ret_arg) {
            try out.appendSlice("@ptrCast(&");
            try out.appendSlice(name);
            try out.appendSlice(")");
        } else if (as_bcheck) |bcheck| {
            try out.appendSlice("@ptrCast(");
            try out.appendSlice(name);
            try out.appendSlice(".ptr)");
            _ = bcheck;
        } else {
            try out.appendSlice(name);
        }
        try out.appendSlice(", ");
    }

    try out.appendSlice(");\n");

    return out.toOwnedSlice();
}

pub fn build_err_convert(alloc: std.mem.Allocator, cfg: FunctionConfig) ![]u8 {
    var out = std.ArrayList(u8).init(alloc);

    // We just handle the exceptions indicated in cfg, but leave an "unreachable" block
    // to catch forgotten ones
    try out.appendSlice("switch(ret) {\n");
    try out.appendSlice("c_gsl.GSL_SUCCESS => {},");
    if (cfg.exceptions.failure) {
        try out.appendSlice("c_gsl.GSL_FAILURE => return GslError.Failure,");
    }
    if (cfg.exceptions.cont) {
        try out.appendSlice("c_gsl.GSL_CONTINUE => return GslError.Continue,");
    }
    if (cfg.exceptions.domain) {
        try out.appendSlice("c_gsl.GSL_EDOM => return GslError.Domain,");
    }
    if (cfg.exceptions.range) {
        try out.appendSlice("c_gsl.GSL_ERANGE => return GslError.Range,");
    }
    if (cfg.exceptions.invalid_ptr) {
        try out.appendSlice("c_gsl.GSL_EFAULT => return GslError.InvalidPointer,");
    }
    if (cfg.exceptions.invalid_value) {
        try out.appendSlice("c_gsl.GSL_EINVAL => return GslError.InvalidValue,");
    }
    if (cfg.exceptions.generic_failure) {
        try out.appendSlice("c_gsl.GSL_EFAILED => return GslError.GenericFailure,");
    }
    if (cfg.exceptions.factor) {
        try out.appendSlice("c_gsl.GSL_EFACTOR => return GslError.Factorization,");
    }
    if (cfg.exceptions.sanity) {
        try out.appendSlice("c_gsl.GSL_ESANITY => return GslError.SanityCheck,");
    }
    if (cfg.exceptions.no_mem) {
        try out.appendSlice("c_gsl.GSL_ENOMEM => return GslError.NoMemory,");
    }
    if (cfg.exceptions.bad_func) {
        try out.appendSlice("c_gsl.GSL_EBADFUNC => return GslError.BadFunction,");
    }
    if (cfg.exceptions.run_away) {
        try out.appendSlice("c_gsl.GSL_ERUNAWAY => return GslError.RunAway,");
    }
    if (cfg.exceptions.max_iter) {
        try out.appendSlice("c_gsl.GSL_EMAXITER => return GslError.MaxIter,");
    }
    if (cfg.exceptions.zero_div) {
        try out.appendSlice("c_gsl.GSL_EZERODIV => return GslError.ZeroDiv,");
    }
    if (cfg.exceptions.bad_tol) {
        try out.appendSlice("c_gsl.GSL_EBADTOL => return GslError.BadTolerance,");
    }
    if (cfg.exceptions.tol) {
        try out.appendSlice("c_gsl.GSL_ETOL => return GslError.Tolerance,");
    }
    if (cfg.exceptions.underflow) {
        try out.appendSlice("c_gsl.GSL_EUNDRFLW => return GslError.Underflow,");
    }
    if (cfg.exceptions.overflow) {
        try out.appendSlice("c_gsl.GSL_EOVRFLW => return GslError.Overflow,");
    }
    if (cfg.exceptions.loss) {
        try out.appendSlice("c_gsl.GSL_ELOSS => return GslError.LossOfAccuracy,");
    }
    if (cfg.exceptions.round) {
        try out.appendSlice("c_gsl.GSL_EROUND => return GslError.Roundoff,");
    }
    if (cfg.exceptions.bad_len) {
        try out.appendSlice("c_gsl.GSL_EBADLEN => return GslError.BadLength,");
    }
    if (cfg.exceptions.not_square) {
        try out.appendSlice("c_gsl.GSL_ENOTSQR => return GslError.NotSquare,");
    }
    if (cfg.exceptions.singular) {
        try out.appendSlice("c_gsl.GSL_ESING => return GslError.Singularity,");
    }
    if (cfg.exceptions.diverge) {
        try out.appendSlice("c_gsl.GSL_EDIVERGE => return GslError.Divergent,");
    }
    if (cfg.exceptions.unsup) {
        try out.appendSlice("c_gsl.GSL_EUNSUP => return GslError.Unsupported,");
    }
    if (cfg.exceptions.unimpl) {
        try out.appendSlice("c_gsl.GSL_EUNIMPL => return GslError.Unimplemented,");
    }
    if (cfg.exceptions.cache) {
        try out.appendSlice("c_gsl.GSL_ECACHE => return GslError.CacheLimit,");
    }
    if (cfg.exceptions.table) {
        try out.appendSlice("c_gsl.GSL_ETABLE => return GslError.TableLimit,");
    }
    if (cfg.exceptions.no_prog) {
        try out.appendSlice("c_gsl.GSL_ENOPROG => return GslError.NoProgress,");
    }
    if (cfg.exceptions.no_prog_j) {
        try out.appendSlice("c_gsl.GSL_ENOPROGJ => return GslError.NoProgressJacobian,");
    }
    if (cfg.exceptions.tol_f) {
        try out.appendSlice("c_gsl.GSL_ETOLF => return GslError.ToleranceF,");
    }
    if (cfg.exceptions.tol_x) {
        try out.appendSlice("c_gsl.GSL_ETOLX => return GslError.ToleranceX,");
    }
    if (cfg.exceptions.tol_g) {
        try out.appendSlice("c_gsl.GSL_ETOLG => return GslError.ToleranceG,");
    }
    try out.appendSlice("else => unreachable,\n");
    try out.appendSlice("}\n");

    return out.toOwnedSlice();
}

pub fn build_ret_state(alloc: std.mem.Allocator, cfg: FunctionConfig) ![]u8 {
    var out = std.ArrayList(u8).init(alloc);

    try out.appendSlice("return ");

    if (!has_errors(cfg)) {
        // Pretty simple
        try out.appendSlice("ret;\n");
    } else {
        if (cfg.ret_args) |ret_args| {
            if (ret_args.len == 1) {
                try out.appendSlice(cfg.fun.arg_names[cfg.ret_args.?[0]]);
                try out.appendSlice(";\n");
            } else {
                // Build the return struct
                try out.appendSlice(".{");
                for (cfg.ret_args.?) |idx| {
                    try out.appendSlice(".");
                    try out.appendSlice(cfg.fun.arg_names[idx]);
                    try out.appendSlice(" = ");
                    try out.appendSlice(cfg.fun.arg_names[idx]);
                    try out.appendSlice(", ");
                }
                try out.appendSlice("};\n");
            }
        } else {
            try out.appendSlice(";\n");
        }
    }

    return out.toOwnedSlice();
}

pub fn build_doc(alloc: std.mem.Allocator, cfg: FunctionConfig) ![]u8 {
    var out = std.ArrayList(u8).init(alloc);

    var toks = std.mem.splitAny(u8, cfg.fun.doc, "\n");
    while (toks.next()) |line| {
        if (line.len == 0) continue;
        try out.appendSlice("///");
        try out.appendSlice(line);
        try out.appendSlice("\n");
    }

    return out.toOwnedSlice();
}
