// Complex data types, guaranteed to be packed!
// Similar to GSL implementation, but not directly based on it to be less verbose
// Also usable with FFTs and other parts of GSL which use complex numbers,
// note that in some cases if you use f32, casting to f64 will take place!
// Do note that we use the same operations as GSL for exactly the same results
// in the cf types.
const std = @import("std");
const gsl = @cImport(@cInclude("gsl/gsl_complex.h"));

fn make_cf(fT: type) type {
    return packed struct {
        re: fT,
        im: fT,
        pub fn rect(re: fT, im: fT) @This() {
            return .{ .re = re, .im = im };
        }
        pub fn polar(r: fT, theta: fT) @This() {
            return .{ .re = r * std.math.cos(theta), .im = r * std.math.sin(theta) };
        }
        pub fn arg(self: @This()) fT {
            if (self.re == 0 and self.im == 0) {
                return 0.0;
            }
            return std.math.atan2(self.im, self.re);
        }
        pub fn abs(self: @This()) fT {
            return std.math.hypot(self.re, self.im);
        }
        pub fn abs2(self: @This()) fT {
            return self.re * self.re + self.im * self.im;
        }
        /// Higher accuracy than naive log |z|
        pub fn logabs(self: @This()) fT {
            const reabs = @abs(self.re);
            const imabs = @abs(self.im);
            var max: f64 = undefined;
            var u: f64 = undefined;

            if (reabs >= imabs) {
                max = reabs;
                u = imabs / reabs;
            } else {
                max = imabs;
                u = reabs / imabs;
            }

            return std.math.log(max) + 0.5 * std.math.log1p(u * u);
        }
        /// Does not modify a!
        pub fn add(a: @This(), b: @This()) @This() {
            return .{ .re = a.re + b.re, .im = a.im + b.im };
        }
        /// Does not modify a!
        pub fn add_real(a: @This(), b: fT) @This() {
            return .{ .re = a.re + b, .im = a.im };
        }
        /// Does not modify a!
        pub fn add_imag(a: @This(), b: fT) @This() {
            return .{ .re = a.re, .im = a.im + b };
        }
        /// Does not modify a!
        pub fn sub(a: @This(), b: @This()) @This() {
            return .{ .re = a.re - b.re, .im = a.im - b.im };
        }
        /// Does not modify a!
        pub fn sub_real(a: @This(), b: fT) @This() {
            return .{ .re = a.re - b, .im = a.im };
        }
        /// Does not modify a!
        pub fn sub_imag(a: @This(), b: fT) @This() {
            return .{ .re = a.re, .im = a.im - b };
        }
        /// Does not modify a!
        pub fn mul(a: @This(), b: @This()) @This() {
            return .{ .re = a.re * b.re - a.im * b.im, .im = a.re * b.im + a.im * b.re };
        }
        /// Does not modify a!
        pub fn mul_real(a: @This(), b: fT) @This() {
            return .{ .re = a.re * b, .im = a.im * b };
        }
        /// Does not modify a!
        pub fn mul_imag(a: @This(), b: fT) @This() {
            return .{ .re = -a.im * b, .im = a.re * b };
        }
        /// Does not modify a!
        pub fn div(a: @This(), b: @This()) @This() {
            const s = 1.0 / b.abs();
            const sbr = s * b.re;
            const sbi = s * b.im;
            return .{ .re = (a.re * sbr + a.im * sbi) * s, .im = (a.im * sbr - a.re * sbi) * s };
        }
        /// Does not modify a!
        pub fn div_real(a: @This(), b: fT) @This() {
            return .{ .re = a.re / b, .im = a.im / b };
        }
        /// Does not modify a!
        pub fn div_imag(a: @This(), b: fT) @This() {
            return .{ .re = a.im / b, .im = -a.re / b };
        }
        /// Does not modify a!
        pub fn conjugate(a: @This()) @This() {
            return .{ .re = a.re, .im = -a.im };
        }
        /// Does not modify a!
        pub fn negative(a: @This()) @This() {
            return .{ .re = -a.re, .im = -a.im };
        }
        /// Does not modify a!
        pub fn inverse(a: @This()) @This() {
            const s = 1.0 / a.abs();
            return .{ .re = (a.re * s) * s, .im = -(a.im * s) * s };
        }

        pub fn cast64(a: @This()) cf64 {
            if (fT == f64) {
                return a;
            }
            return cf64.rect(@floatCast(a.re), @floatCast(a.im));
        }

        pub fn cast32(a: @This()) cf32 {
            if (fT == f32) {
                return a;
            }
            return cf32.rect(@floatCast(a.re), @floatCast(a.im));
        }

        /// This is meant to be used to call GSL functions that expect a
        /// gsl_complex (f64) input. It should reduce to a noop on cf64.
        pub fn cast_gsl(a: @This()) gsl.gsl_complex {
            if (fT == f64) {
                return @bitCast(a);
            }
            return cast_gsl(cast64(a));
        }
    };
}

/// 64-bit complex type. Compatible with all of GSL
pub const cf64 = make_cf(f64);
/// 32-bit complex type. Some other parts of GSL will require casting to
/// cf64 before usage.
pub const cf32 = make_cf(f32);
