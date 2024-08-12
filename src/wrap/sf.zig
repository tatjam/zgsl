const gsl = @cImport(@cInclude("gsl/gsl_sf.h"));
const err = @import("errors.zig");

// Value and error estimate for special function invocation
pub const Result = gsl.gsl_sf_result;
// Same as Result, but with scaling applied to prevent overflowing
// Real result is thus val * 10^(e10). Uses smash function to obtain this
// value.
pub const ResultE10 = gsl.gsl_sf_result_e10;

// Converts a scaled result to a normal result. Note that overflow or underflow
// are not considered errors here, but they will end up in a inf / -inf result
pub fn smash(r: ResultE10) err.OverflowOrUnderflowError!Result {
    var out: Result = undefined;
    const retval = gsl.gsl_sf_result_smash_e(&r, &out);
    switch (retval) {
        gsl.GSL_SUCCESS => return out,
        gsl.GSL_EOVRFLW => return error.Overflow,
        gsl.GSL_EUNDRFLW => return error.Undeflow,
        else => unreachable,
    }
    return out;
}

// Autogenerated headers for all subfunction types
pub const bessel = @import("wrapped_sf_bessel.zig");
