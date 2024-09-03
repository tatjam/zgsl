const cf64 = @import("../wrap/complex.zig").cf64;
const cf32 = @import("../wrap/complex.zig").cf32;
const std = @import("std");

fn is_approx(T: type, a: T, b: T, epsilon: T) bool {
    return @abs(a - b) < epsilon;
}

fn is_approx_cf64(a: cf64, b: cf64, epsilon2: f64) bool {
    return a.sub(b).abs2() < epsilon2;
}

test "complex_elementary_64" {
    const a = cf64.rect(1, 1);
    const b = cf64.rect(2, 2);

    const eps: f64 = 0.0000001;

    const c = a.add(b);
    try std.testing.expect(c.re == 3 and c.im == 3);
    const d = a.sub(b);
    try std.testing.expect(d.re == -1 and d.im == -1);
    const e = a.mul(b);
    try std.testing.expect(e.re == 0 and e.im == 4);
    const f = a.div(b);
    // expectedly from our/GSL's div implementation, this implies slight error
    try std.testing.expect(is_approx(f64, f.re, 0.5, eps) and f.im == 0);
    const g = a.add_real(2.0);
    try std.testing.expect(g.re == 3.0 and g.im == 1.0);
    const h = a.add_imag(2.0);
    try std.testing.expect(h.re == 1.0 and h.im == 3.0);
    const i = a.sub_real(2.0);
    try std.testing.expect(i.re == -1.0 and i.im == 1.0);
    const j = a.sub_imag(2.0);
    try std.testing.expect(j.re == 1.0 and j.im == -1.0);
    const k = a.mul_real(2.0);
    try std.testing.expect(k.re == 2.0 and k.im == 2.0);
    const l = a.mul_imag(2.0);
    try std.testing.expect(l.re == -2.0 and l.im == 2.0);
    const m = a.div_real(2.0);
    try std.testing.expect(m.re == 0.5 and m.im == 0.5);
    const n = a.div_imag(2.0);
    try std.testing.expect(n.re == 0.5 and n.im == -0.5);
    const o = a.conjugate();
    try std.testing.expect(o.re == 1.0 and o.im == -1.0);
    const p = a.negative();
    try std.testing.expect(p.re == -1.0 and p.im == -1.0);
    const q = a.inverse();
    try std.testing.expect(is_approx(f64, q.re, 0.5, eps) and is_approx(f64, q.im, -0.5, eps));
}

test "complex_elementary_32" {
    const a = cf32.rect(1, 1);
    const b = cf32.rect(2, 2);

    const eps: f32 = 0.0000001;

    const c = a.add(b);
    try std.testing.expect(c.re == 3 and c.im == 3);
    const d = a.sub(b);
    try std.testing.expect(d.re == -1 and d.im == -1);
    const e = a.mul(b);
    try std.testing.expect(e.re == 0 and e.im == 4);
    const f = a.div(b);
    // expectedly from our/GSL's div implementation, this implies slight error
    try std.testing.expect(is_approx(f32, f.re, 0.5, eps) and f.im == 0);
    const g = a.add_real(2.0);
    try std.testing.expect(g.re == 3.0 and g.im == 1.0);
    const h = a.add_imag(2.0);
    try std.testing.expect(h.re == 1.0 and h.im == 3.0);
    const i = a.sub_real(2.0);
    try std.testing.expect(i.re == -1.0 and i.im == 1.0);
    const j = a.sub_imag(2.0);
    try std.testing.expect(j.re == 1.0 and j.im == -1.0);
    const k = a.mul_real(2.0);
    try std.testing.expect(k.re == 2.0 and k.im == 2.0);
    const l = a.mul_imag(2.0);
    try std.testing.expect(l.re == -2.0 and l.im == 2.0);
    const m = a.div_real(2.0);
    try std.testing.expect(m.re == 0.5 and m.im == 0.5);
    const n = a.div_imag(2.0);
    try std.testing.expect(n.re == 0.5 and n.im == -0.5);
    const o = a.conjugate();
    try std.testing.expect(o.re == 1.0 and o.im == -1.0);
    const p = a.negative();
    try std.testing.expect(p.re == -1.0 and p.im == -1.0);
    const q = a.inverse();
    try std.testing.expect(is_approx(f32, q.re, 0.5, eps) and is_approx(f32, q.im, -0.5, eps));
}

test "complex_basic_64" {
    const eps: f32 = 0.0000001;

    const a = cf64.polar(1.0, std.math.pi / 2.0);
    try std.testing.expect(is_approx(f64, a.re, 0.0, eps) and a.im == 1.0);
    const b = cf64.polar(2.0, std.math.pi / 4.0);
    try std.testing.expect(is_approx(f64, b.re, b.im, eps));

    try std.testing.expect(is_approx(f64, a.abs(), 1.0, eps));
    try std.testing.expect(is_approx(f64, b.abs(), 2.0, eps));
    try std.testing.expect(is_approx(f64, a.abs2(), 1.0, eps));
    try std.testing.expect(is_approx(f64, b.abs2(), 4.0, eps));
    try std.testing.expect(is_approx(f64, a.logabs(), 0.0, eps));
    try std.testing.expect(is_approx(f64, b.logabs(), 0.69314718055994530942, eps));
    try std.testing.expect(is_approx(f64, a.arg(), std.math.pi / 2.0, eps));
    try std.testing.expect(is_approx(f64, b.arg(), std.math.pi / 4.0, eps));
}

test "cast_32_64" {
    const a = cf64.rect(1, 1);
    const b = a.cast32();
    const c = b.cast64();
    try std.testing.expect(a.re == c.re and a.im == b.im);
}

test "to_from_gsl_64" {
    const a = cf64.rect(1, 1);
    const a_gsl = a.cast_gsl();
    const b = cf64.from_gsl(a_gsl);
    try std.testing.expect(b.re == a.re and b.im == a.im);
}

test "to_from_gsl_32" {
    const a = cf32.rect(1, 1);
    const a_gsl = a.cast_gsl();
    const b = cf32.from_gsl(a_gsl);
    try std.testing.expect(b.re == a.re and b.im == a.im);
}

// TODO: All of these are broken, see Zig issue #21245
test "gsl_funcs" {
    const eps = 0.0000001;
    _ = eps; // autofix

    const a = cf64.rect(1, 1);
    const b = a.sqrt();
    std.debug.print("{} + I*{}\n", .{ b.re, b.im });
    //try std.testing.expect(is_approx_cf64(b, cf64.rect(1.0986841135, 0.4550898606), eps));
}
