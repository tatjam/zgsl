pub const sf = @import("sf.zig");
pub const fft = @import("fft.zig");

const gsl = @cImport(@cInclude("gsl/gsl_errno.h"));

// Use if you want to use Zig errors exclusively, instead of
// GSL errors (that will panic by default on any error, thus
// making handling it useless!)
pub fn set_error_handler_off() void {
    _ = gsl.gsl_set_error_handler_off();
}
