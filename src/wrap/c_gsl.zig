// Include file for all GSL
pub const c_gsl = @cImport({
		@cInclude("gsl/gsl_errno.h");
		@cInclude("gsl/gsl_sf.h");
	}
);