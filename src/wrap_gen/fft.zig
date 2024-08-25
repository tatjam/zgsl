const std = @import("std");
const parser = @import("c_parse.zig");
const zig_gen = @import("zig_gen.zig");
// We use a manual implementation for radix2 functions, which is shared (up to data types)
// used for all kinds of FFT offered by GSL

fn wrap_radix2(alloc: std.mem.Allocator, fout: std.fs.File, fun: parser.ParsedCFunction, half: bool) !void {
    _ = half; // autofix
    _ = alloc; // autofix
    _ = fout; // autofix
    _ = fun; // autofix

}

pub fn wrap_fft(alloc: std.mem.Allocator, fout: std.fs.File, fun: parser.ParsedCFunction) !void {
    const is_halfcomplex: bool =
        if (std.mem.indexOf(u8, fun, "halfcomplex")) true else false;

    if (std.mem.indexOf(u8, fun, "radix2")) {
        return wrap_radix2(alloc, fout, fun, is_halfcomplex);
    }
    // TODO: Other cases
}
