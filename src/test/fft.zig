const gsl = @import("../wrap/zgsl.zig");
const std = @import("std");

fn fft_data(T: type, alloc: std.mem.Allocator, n: usize) ![]T {
    const base_data = try alloc.alloc(T, n);
    for (base_data, 0..) |*dat, i| {
        const as_f: T = @floatFromInt(i);
        dat.* = std.math.sin(as_f * 0.02) + std.math.sin(as_f * 0.05);
    }

    return base_data;
}

test "fft_dir_f32" {
    gsl.set_error_handler_off();
    const alloc = std.testing.allocator;

    var data_copies = [_][]f32{ undefined, undefined, undefined, undefined };
    data_copies[0] = try fft_data(f32, alloc, 1024);
    for (data_copies[1..]) |*data_copy| {
        data_copy.* = try alloc.alloc(f32, data_copies[0].len);
        @memcpy(data_copy.*, data_copies[0]);
    }

    try gsl.fft.complex_f32.radix2_transform(data_copies[0], 1, .Forward);
    try gsl.fft.complex_f32.radix2_transform(data_copies[1], 1, .Backward);
    try gsl.fft.complex_f32.radix2_forward(data_copies[2], 1);
    try gsl.fft.complex_f32.radix2_backward(data_copies[3], 1);

    try std.testing.expect(std.mem.eql(f32, data_copies[0], data_copies[2]));
    try std.testing.expect(std.mem.eql(f32, data_copies[1], data_copies[3]));

    for (data_copies) |data_copy| {
        alloc.free(data_copy);
    }
}

test "fft_dir_f64" {
    gsl.set_error_handler_off();
    const alloc = std.testing.allocator;

    var data_copies = [_][]f64{ undefined, undefined, undefined, undefined };
    data_copies[0] = try fft_data(f64, alloc, 1024);
    for (data_copies[1..]) |*data_copy| {
        data_copy.* = try alloc.alloc(f64, data_copies[0].len);
        @memcpy(data_copy.*, data_copies[0]);
    }

    //try gsl.fft.complex_f64.radix2_transform(data_copies[0], 1, .Forward);
    //try gsl.fft.complex_f64.radix2_transform(data_copies[1], 1, .Backward);
    //try gsl.fft.complex_f64.radix2_forward(data_copies[2], 1);
    //try gsl.fft.complex_f64.radix2_backward(data_copies[3], 1);

    try std.testing.expect(std.mem.eql(f64, data_copies[0], data_copies[2]));
    try std.testing.expect(std.mem.eql(f64, data_copies[1], data_copies[3]));

    for (data_copies) |data_copy| {
        alloc.free(data_copy);
    }
}
