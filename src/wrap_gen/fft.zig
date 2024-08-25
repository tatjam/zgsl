const std = @import("std");
const parser = @import("c_parse.zig");
const zig_gen = @import("zig_gen.zig");

const assert = std.debug.assert;

// We use a "manual" implementation for radix2 functions, which is shared (up to data types)
// used for all kinds of FFT offered by GSL
// It simply takes a slice instead of raw pointers. The stride option is passed directly
pub fn emit_header(fname: []const u8, fout: std.fs.File) !void {
    _ = fout; // autofix
    _ = fname; // autofix
}

fn wrap_radix2(
    alloc: std.mem.Allocator,
    fout: std.fs.File,
    fun: parser.ParsedCFunction,
    half: bool,
    float: bool,
) !void {
    _ = half; // autofix

    // trim everything up to the radix2 (everything else is namespaced!)
    const point = std.mem.indexOf(u8, fun.name, "radix2") orelse unreachable;
    const name = try alloc.alloc(u8, fun.name.len - point);
    std.mem.copyForwards(u8, name, fun.name[point..]);

    try fout.writeAll("pub fn ");
    try fout.writeAll(name);
    try fout.writeAll("(data: ");
    if (float) {
        try fout.writeAll("[]f32, ");
    } else {
        try fout.writeAll("[]f64, ");
    }
    try fout.writeAll("stride: usize) error{Domain, InvalidValue}!void {\n");
    // Function invocation
    try fout.writeAll("const ret = c_gsl.");
    try fout.writeAll(fun.name);
    try fout.writeAll("(@ptrCast(data), stride, data.len);\n");
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
    const is_halfcomplex: bool =
        if (std.mem.indexOf(u8, fun.name, "halfcomplex")) |_| true else false;

    const is_float: bool =
        if (std.mem.indexOf(u8, fun.name, "float")) |_| true else false;

    std.log.info("{s}", .{fun.name});

    if (std.mem.indexOf(u8, fun.name, "radix2")) |_| {
        return wrap_radix2(alloc, fout, fun, is_halfcomplex, is_float);
    }
    // TODO: Other cases
}
