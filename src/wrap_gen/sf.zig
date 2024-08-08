// Logic for all special functions, which are more or less common in form
// We simply build a wrapper that converts int return value to errors (with some exceptions)
// and for non-erroring functions simply wrap directly
const std = @import("std");
const parser = @import("c_parse.zig");

pub fn emit_function_header(fout: std.fs.File, fun: parser.ParsedCFunction) !void {
    try fout.writeAll("pub fn ");
    // Function name gets trimmed to remove all redundant namespacing
    var tokens = std.mem.tokenizeAny(u8, fun.name, "_");

    // Non common namespace: trig, zeta, sincos, erf, dilog, exp
    //  These are simply not trmmed, which results in name duplication but makes sense
    // Full name in namespace: pow_int, synchrotron, elljac, clausen, dawson
    //  These are not trimmed either, as it would be confusing syntax. Instead, they are
    //  directly promoted to the upper namespace in the root file
    //  (Conditional compilation guarantees no wasted resources)
    while (tokens.next()) |tok| {
        if (std.mem.eql(u8, tok, "gsl")) continue;
        if (std.mem.eql(u8, tok, "sf")) continue;
        if (std.mem.eql(u8, tok, "bessel")) continue;
        if (std.mem.eql(u8, tok, "coulomb")) continue;
        if (std.mem.eql(u8, tok, "coupling")) continue;
        if (std.mem.eql(u8, tok, "ellint")) continue;
        if (std.mem.eql(u8, tok, "hyperg")) continue;
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
}

pub fn wrap_sf(alloc: std.mem.Allocator, fout: std.fs.File, fun: parser.ParsedCFunction) !void {
    _ = alloc;
    try emit_function_header(fout, fun);
    if (std.mem.eql(u8, fun.rettype, "int")) {
        // Has error handling

    } else {
        // Doesn't have error handling, "raw" wrapper
    }
}
