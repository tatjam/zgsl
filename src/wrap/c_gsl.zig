// Include file for all GSL
pub const c_gsl = @cImport({
    @cInclude("gsl/gsl_errno.h");
    @cInclude("gsl/gsl_sf.h");
    @cInclude("gsl/gsl_fft_complex_float.h");
    @cInclude("gsl/gsl_fft_complex.h");
    @cInclude("gsl/gsl_fft_halfcomplex_float.h");
    @cInclude("gsl/gsl_fft_halfcomplex.h");
    @cInclude("gsl/gsl_fft_real_float.h");
    @cInclude("gsl/gsl_fft_real.h");
});
