///Regular cylindrical Bessel function J_nu(x)
///evaluated at a series of x values. The array
///contains the x values. They are assumed to be
///strictly ordered and positive. The array is
///over-written with the values of J_nu(x_i).
pub fn sequence_Jnu_e(nu: f64, mode: Precision, seq_x: []f64) error{Domain, InvalidValue}!void {
	// Note ordering is already checked by GSL
	const ret = c_gsl.gsl_sf_bessel_sequence_Jnu_e(nu, @intFromEnum(mode), seq_x.len, @ptrCast(seq_x.ptr));
    switch (ret) {
        c_gsl.GSL_SUCCESS => {},
        c_gsl.GSL_EDOM => return GslError.Domain,
        c_gsl.GSL_EINVAL => return GslError.InvalidValue,
        else => unreachable,
    }
	return;
}

