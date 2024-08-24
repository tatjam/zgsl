// Logic for all special functions, which are more or less common in form
// We simply build a wrapper that converts int return value to errors (with some exceptions)
// and for non-erroring functions simply wrap directly
const std = @import("std");
const parser = @import("c_parse.zig");
const zig_gen = @import("zig_gen.zig");

pub fn emit_header(fname: []const u8, fout: std.fs.File) !void {
    _ = fname; // autofix
    try fout.writeAll("const sf = @import(\"zgsl.zig\").sf;\n");
    try fout.writeAll("const Result = sf.Result;\n");
    try fout.writeAll("const ResultE10 = sf.ResultE10;\n");
    try fout.writeAll("const Precision = sf.Precision;\n");
}

fn emit_function_header(fout: std.fs.File, cfg: zig_gen.FunctionConfig, args: []const u8, err: []const u8, ret: []const u8) !void {
    try fout.writeAll("pub fn ");
    // Function name gets trimmed to remove all redundant namespacing
    var tokens = std.mem.tokenizeAny(u8, cfg.fun.name, "_");

    // Non common namespace: trig, zeta, sincos, erf, dilog, exp
    //  These are simply not trmmed, which results in name duplication but makes sense
    // Full name in namespace: pow_int, synchrotron, elljac, clausen, dawson, coupling, hyperg
    //  These are not trimmed either, as it would be confusing syntax. Instead, they are
    //  directly promoted to the upper namespace in the root file
    //  (Conditional compilation guarantees no wasted resources)
    while (tokens.next()) |tok| {
        if (std.mem.eql(u8, tok, "airy")) continue;
        if (std.mem.eql(u8, tok, "gsl")) continue;
        if (std.mem.eql(u8, tok, "sf")) continue;
        if (std.mem.eql(u8, tok, "bessel")) continue;
        if (std.mem.eql(u8, tok, "coulomb")) continue;
        if (std.mem.eql(u8, tok, "ellint")) continue;
        if (std.mem.eql(u8, tok, "lambert")) continue;
        if (std.mem.eql(u8, tok, "legendre")) continue;
        if (std.mem.eql(u8, tok, "mathieu")) continue;
        if (std.mem.eql(u8, tok, "transport")) {
            // Transport functions are renamed to J[number] (not J_[number]!)
            try fout.writeAll("J");
            continue;
        }
        if (std.mem.eql(u8, tok, "debye")) {
            // Debye functions are renamed to D[number] (not D_[number]!)
            try fout.writeAll("D");
            continue;
        }
        if (std.mem.eql(u8, tok, "laguerre")) {
            // Laguerre functions are renamed to L[number] (not L_[number]!)
            try fout.writeAll("L");
            continue;
        }

        try fout.writeAll(tok);
        if (tokens.peek() != null) {
            try fout.writeAll("_");
        }
    }

    try fout.writeAll("(");
    try fout.writeAll(args);
    try fout.writeAll(") ");

    if (err.len != 0) {
        try fout.writeAll(err);
        try fout.writeAll("!");
    }

    if (ret.len == 0) {
        try fout.writeAll("void");
    } else {
        try fout.writeAll(ret);
    }

    try fout.writeAll(" {\n");
}

fn convert_result_args(alloc: std.mem.Allocator, cfg: *zig_gen.FunctionConfig) !void {
    var arr = std.ArrayList(usize).init(alloc);
    for (cfg.fun.arg_types, cfg.fun.arg_names, 0..) |typ, name, idx| {
        if (std.mem.eql(u8, typ, "gsl_sf_result *")) {
            try arr.append(idx);
        } else if (std.mem.eql(u8, typ, "gsl_sf_result_e10 *")) {
            try arr.append(idx);
        } else if (std.mem.eql(u8, name, "sgn")) {
            try arr.append(idx);
        }
    }

    if (arr.items.len != 0) {
        cfg.ret_args = try arr.toOwnedSlice();
    }
}

// This is some "ad-hoc" logic, could technically be extracted from doc but too hard!
fn find_bounds(alloc: std.mem.Allocator, cfg: *zig_gen.FunctionConfig) !struct { min: []u8, max: []u8 } {
    var min: ?[]u8 = null;
    var max: ?[]u8 = null;
    for (cfg.fun.arg_names) |name| {
        if (std.mem.endsWith(u8, name, "min")) {
            min = name;
        } else if (std.mem.endsWith(u8, name, "max")) {
            max = name;
        }
    }

    if (min == null) {
        min = try alloc.alloc(u8, 1);
        min.?[0] = '0';
    }
    if (max == null) {
        return error.InvalidBound;
    }
    return .{ .min = min.?, .max = max.? };
}

fn convert_bound_args(alloc: std.mem.Allocator, cfg: *zig_gen.FunctionConfig) !void {
    var arr = std.ArrayList(zig_gen.BoundCheckedArg).init(alloc);

    outer: for (cfg.fun.arg_types, 0..) |typ, idx| {
        if (cfg.ret_args) |ret_args| {
            for (ret_args) |ret_idx| {
                if (ret_idx == idx) {
                    continue :outer;
                }
            }
        }
        if (std.mem.eql(u8, zig_gen.sanify_typ(typ), "double *")) {
            // Find what kind of bounds we have...
            var nbound: zig_gen.BoundCheckedArg = undefined;
            nbound.idx = idx;
            const bounds = try find_bounds(alloc, cfg);
            nbound.min = bounds.min;
            nbound.max = bounds.max;
            try arr.append(nbound);
        }
    }

    if (arr.items.len != 0) {
        cfg.bound_checked_args = try arr.toOwnedSlice();
    }
}

fn skip_fn(fun: parser.ParsedCFunction, fout: std.fs.File) !bool {
    if (std.mem.eql(u8, fun.name, "gsl_sf_bessel_sequence_Jnu_e")) {
        try fout.writeAll(@embedFile("../wrap/manual/sf/sequence_Jnu_e.zig"));
        return true;
    } else if (std.mem.eql(u8, fun.name, "gsl_sf_coulomb_wave_FG_e")) {
        try fout.writeAll(@embedFile("../wrap/manual/sf/coulomb_wave_FG.zig"));
        return true;
    } else if (std.mem.eql(u8, fun.name, "gsl_sf_angle_restrict_symm_e")) {
        try fout.writeAll(@embedFile("../wrap/manual/sf/angle_restrict_symm_e.zig"));
        return true;
    } else if (std.mem.eql(u8, fun.name, "gsl_sf_angle_restrict_pos_e")) {
        try fout.writeAll(@embedFile("../wrap/manual/sf/angle_restrict_pos_e.zig"));
        return true;
    }

    return false;
}

pub fn wrap_sf(alloc: std.mem.Allocator, fout: std.fs.File, fun: parser.ParsedCFunction) !void {
    if (try skip_fn(fun, fout)) return;
    var cfg = try zig_gen.make_default_config(fun);
    if (zig_gen.all_set(cfg)) {
        // Sane defaults
        zig_gen.set_exceptions(&cfg, false);
        cfg.exceptions.domain = true;
        cfg.exceptions.invalid_value = true;
        cfg.exceptions.overflow = true;
        cfg.exceptions.underflow = true;
        cfg.exceptions.loss = true;
    }
    // Loss of accuracy can happen almost everywhere, but is not clearly indicated
    cfg.exceptions.loss = true;

    try convert_result_args(alloc, &cfg);
    try convert_bound_args(alloc, &cfg);

    const args = try zig_gen.build_args(alloc, cfg);
    const ret = try zig_gen.build_ret(alloc, cfg);
    const err = try zig_gen.build_errors(alloc, cfg);

    const doc = try zig_gen.build_doc(alloc, cfg);
    try fout.writeAll(doc);

    try emit_function_header(fout, cfg, args, err, ret);

    const invoke = try zig_gen.build_invoke(alloc, cfg);
    try fout.writeAll(invoke);
    if (zig_gen.has_errors(cfg)) {
        const err_conv = try zig_gen.build_err_convert(alloc, cfg);
        try fout.writeAll(err_conv);
    }
    const ret_state = try zig_gen.build_ret_state(alloc, cfg);
    try fout.writeAll(ret_state);
    try fout.writeAll("}\n\n");
}
