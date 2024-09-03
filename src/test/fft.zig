const gsl = @import("../wrap/zgsl.zig");
const std = @import("std");
const nearly_equal = @import("nearly_equal.zig").nearly_equal;

fn fft_data(T: type, alloc: std.mem.Allocator, n: usize) ![]T {
    const base_data = try alloc.alloc(T, n);
    for (base_data, 0..) |*dat, i| {
        const as_f: T = @floatFromInt(i);
        dat.* = std.math.sin(as_f * 0.02) + std.math.sin(as_f * 0.05);
    }

    return base_data;
}

fn fft_data_complex(T: type, alloc: std.mem.Allocator, n: usize) ![]gsl.complex.make_cf(T) {
    const base_data = try alloc.alloc(gsl.complex.make_cf(T), n);
    for (base_data, 0..) |*dat, i| {
        const as_f: T = @floatFromInt(i);
        dat.*.re = std.math.sin(as_f * 0.02) + std.math.sin(as_f * 0.05);
        dat.*.im = std.math.sin(as_f * 0.05) + std.math.sin(as_f * 0.07);
    }

    return base_data;
}

test "fft_dir_f32" {
    gsl.set_error_handler_off();
    const alloc = std.testing.allocator;

    var data_copies = [_][]gsl.complex.cf32{ undefined, undefined, undefined, undefined };
    data_copies[0] = try fft_data_complex(f32, alloc, 1024);
    for (data_copies[1..]) |*data_copy| {
        data_copy.* = try alloc.alloc(gsl.complex.cf32, data_copies[0].len);
        @memcpy(data_copy.*, data_copies[0]);
    }

    try gsl.fft.complex_f32.radix2_transform(data_copies[0], 1, .Forward);
    try gsl.fft.complex_f32.radix2_transform(data_copies[1], 1, .Backward);
    try gsl.fft.complex_f32.radix2_forward(data_copies[2], 1);
    try gsl.fft.complex_f32.radix2_backward(data_copies[3], 1);

    try std.testing.expect(std.mem.eql(gsl.complex.cf32, data_copies[0], data_copies[2]));
    try std.testing.expect(std.mem.eql(gsl.complex.cf32, data_copies[1], data_copies[3]));

    for (data_copies) |data_copy| {
        alloc.free(data_copy);
    }
}

test "fft_dir_f64" {
    gsl.set_error_handler_off();
    const alloc = std.testing.allocator;

    var data_copies = [_][]gsl.complex.cf64{ undefined, undefined, undefined, undefined };
    data_copies[0] = try fft_data_complex(f64, alloc, 1024);
    for (data_copies[1..]) |*data_copy| {
        data_copy.* = try alloc.alloc(gsl.complex.cf64, data_copies[0].len);
        @memcpy(data_copy.*, data_copies[0]);
    }

    //try gsl.fft.complex_f64.radix2_transform(data_copies[0], 1, .Forward);
    //try gsl.fft.complex_f64.radix2_transform(data_copies[1], 1, .Backward);
    //try gsl.fft.complex_f64.radix2_forward(data_copies[2], 1);
    //try gsl.fft.complex_f64.radix2_backward(data_copies[3], 1);

    try std.testing.expect(std.mem.eql(gsl.complex.cf64, data_copies[0], data_copies[2]));
    try std.testing.expect(std.mem.eql(gsl.complex.cf64, data_copies[1], data_copies[3]));

    for (data_copies) |data_copy| {
        alloc.free(data_copy);
    }
}

test "real_fft_and_back_f64" {
    gsl.set_error_handler_off();
    const alloc = std.testing.allocator;

    var data_copies = [_][]f64{ undefined, undefined };
    data_copies[0] = try fft_data(f64, alloc, 512);
    data_copies[1] = try alloc.alloc(f64, 512);
    @memcpy(data_copies[1], data_copies[0]);
    defer alloc.free(data_copies[0]);
    defer alloc.free(data_copies[1]);

    try gsl.fft.real_f64.radix2_transform(data_copies[0], 1);
    // data_copies[0] now contains half complex data
    try gsl.fft.halfcomplex_f64.radix2_inverse(data_copies[0], 1);

    std.debug.assert(nearly_equal(f64, data_copies[0], data_copies[1], 0.00001));
}

test "real_fft_and_back_f32" {
    gsl.set_error_handler_off();
    const alloc = std.testing.allocator;

    var data_copies = [_][]f32{ undefined, undefined };
    data_copies[0] = try fft_data(f32, alloc, 512);
    data_copies[1] = try alloc.alloc(f32, 512);
    @memcpy(data_copies[1], data_copies[0]);
    defer alloc.free(data_copies[0]);
    defer alloc.free(data_copies[1]);

    try gsl.fft.real_f32.radix2_transform(data_copies[0], 1);
    // data_copies[0] now contains half complex data
    try gsl.fft.halfcomplex_f32.radix2_inverse(data_copies[0], 1);

    std.debug.assert(nearly_equal(f32, data_copies[0], data_copies[1], 0.00001));
}

test "fft_error_radix2" {
    gsl.set_error_handler_off();
    const alloc = std.testing.allocator;

    const non_pow2_data_f32 = try fft_data(f32, alloc, 543);
    const non_pow2_data_f64 = try fft_data(f64, alloc, 543);
    const non_pow2_data_cf32 = try fft_data_complex(f32, alloc, 543);
    const non_pow2_data_cf64 = try fft_data_complex(f64, alloc, 543);

    defer alloc.free(non_pow2_data_f32);
    defer alloc.free(non_pow2_data_f64);
    defer alloc.free(non_pow2_data_cf32);
    defer alloc.free(non_pow2_data_cf64);

    // InvalidValue is returned for non power of 2 n
    const fft_cf32 = gsl.fft.complex_f32.radix2_forward(non_pow2_data_cf32, 1);
    std.debug.assert(fft_cf32 == error.InvalidValue);
    const fft_cf64 = gsl.fft.complex_f64.radix2_forward(non_pow2_data_cf64, 1);
    std.debug.assert(fft_cf64 == error.InvalidValue);
    const fft_hc_f32 = gsl.fft.halfcomplex_f32.radix2_transform(non_pow2_data_f32, 1);
    std.debug.assert(fft_hc_f32 == error.InvalidValue);
    const fft_hc_f64 = gsl.fft.halfcomplex_f64.radix2_transform(non_pow2_data_f64, 1);
    std.debug.assert(fft_hc_f64 == error.InvalidValue);
    const fft_f32 = gsl.fft.real_f32.radix2_transform(non_pow2_data_f32, 1);
    std.debug.assert(fft_f32 == error.InvalidValue);
    const fft_f64 = gsl.fft.real_f64.radix2_transform(non_pow2_data_f64, 1);
    std.debug.assert(fft_f64 == error.InvalidValue);

    // Edge case for n = 0 (Zig doesn't allow negative slice sizes ;))
    const dummy_f32: [0]f32 = undefined;
    const dummy_f64: [0]f64 = undefined;
    const dummy_cf32: [0]gsl.complex.cf32 = undefined;
    const dummy_cf64: [0]gsl.complex.cf64 = undefined;

    const fft_0_cf32 = gsl.fft.complex_f32.radix2_forward(&dummy_cf32, 1);
    std.debug.assert(fft_0_cf32 == error.InvalidValue);
    const fft_0_cf64 = gsl.fft.complex_f64.radix2_forward(&dummy_cf64, 1);
    std.debug.assert(fft_0_cf64 == error.InvalidValue);
    const fft_0_hc_f32 = gsl.fft.halfcomplex_f32.radix2_transform(&dummy_f32, 1);
    std.debug.assert(fft_0_hc_f32 == error.InvalidValue);
    const fft_0_hc_f64 = gsl.fft.halfcomplex_f64.radix2_transform(&dummy_f64, 1);
    std.debug.assert(fft_0_hc_f64 == error.InvalidValue);
    const fft_0_f32 = gsl.fft.real_f32.radix2_transform(&dummy_f32, 1);
    std.debug.assert(fft_0_f32 == error.InvalidValue);
    const fft_0_f64 = gsl.fft.real_f64.radix2_transform(&dummy_f64, 1);
    std.debug.assert(fft_0_f64 == error.InvalidValue);
}
