const cf64 = @import("../wrap/complex.zig").cf64;
const cf32 = @import("../wrap/complex.zig").cf32;
const std = @import("std");

fn is_approx(T: type, a: T, b: T, epsilon: T) bool {
    return @abs(a - b) < epsilon;
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
}
