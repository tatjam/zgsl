const std = @import("std");
const parser = @import("c_parse.zig");
const zig_gen = @import("zig_gen.zig");

const assert = std.debug.assert;

const FftKind = enum {
    Complex,
    HalfComplex,
    Real,
};

// We use a "manual" implementation for radix2 functions, which is shared (up to data types)
// used for all kinds of FFT offered by GSL
// It simply takes a slice instead of raw pointers. The stride option is passed directly
pub fn emit_header(fname: []const u8, fout: std.fs.File) !void {
    _ = fname; // autofix
    try fout.writeAll("const fft = @import(\"zgsl.zig\").fft;\n");
    try fout.writeAll("const FftDirection = fft.FftDirection;\n");
}

fn wrap_radix2(
    alloc: std.mem.Allocator,
    fout: std.fs.File,
    kind: FftKind,
    fun: parser.ParsedCFunction,
    float: bool,
    sign: bool,
) !void {

    // trim everything up to the radix2 (everything else is namespaced!)
    const point = std.mem.indexOf(u8, fun.name, "radix2") orelse unreachable;
    const name = try alloc.alloc(u8, fun.name.len - point);
    @memcpy(name, fun.name[point..]);

    try fout.writeAll("pub fn ");
    try fout.writeAll(name);
    try fout.writeAll("(data: ");
    if (float) {
        try fout.writeAll("[]f32, ");
    } else {
        try fout.writeAll("[]f64, ");
    }
    if (sign) {
        try fout.writeAll("stride: usize, dir: FftDirection) error{Domain, InvalidValue}!void {\n");
    } else {
        try fout.writeAll("stride: usize) error{Domain, InvalidValue}!void {\n");
    }
    // Function invocation
    try fout.writeAll("const ret = c_gsl.");
    try fout.writeAll(fun.name);
    try fout.writeAll("(@ptrCast(data.ptr), stride");
    if (kind == .Complex) {
        // Divide len of array by two, as the input array contains both reals and
    }
    if (sign) {
        try fout.writeAll("(@ptrCast(data.ptr), stride, data.len, " ++
            "@intFromEnum(dir));\n");
    } else {
        try fout.writeAll("(@ptrCast(data.ptr), stride, data.len);\n");
    }
    // Error translation
    try fout.writeAll("switch(ret) {\n" ++
        "c_gsl.GSL_SUCCESS => return,\n" ++
        "c_gsl.GSL_EDOM => return GslError.Domain,\n" ++
        "c_gsl.GSL_EINVAL => return GslError.InvalidValue,\n" ++
        "else => unreachable\n" ++
        "}\n");
    try fout.writeAll("}\n");
}

pub fn wrap_fft(alloc: std.mem.Allocator, fout: std.fs.File, fun: parser.ParsedCFunction) !void {
    const is_complex: bool =
        if (std.mem.indexOf(u8, fun.name, "complex")) |_| true else false;
    const is_halfcomplex: bool =
        if (std.mem.indexOf(u8, fun.name, "halfcomplex")) |_| true else false;

    var kind: FftKind = .Real;
    if (is_complex) {
        kind = .Complex;
    } else if (is_halfcomplex) {
        kind = .HalfComplex;
    }

    const is_float: bool =
        if (std.mem.indexOf(u8, fun.name, "float")) |_| true else false;

    const is_sign: bool = for (fun.arg_types) |typ| {
        if (std.mem.eql(u8, typ, "const gsl_fft_direction")) break true;
    } else false;

    if (std.mem.indexOf(u8, fun.name, "radix2")) |_| {
        return wrap_radix2(alloc, fout, fun, kind, is_float, is_sign);
    }
    // TODO: Other cases
}
