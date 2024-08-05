const gsl = @cImport(@cInclude("gsl/gsl_sf.h"));

// Value and error estimate for special function invocation
const Result = gsl.gsl_sf_result;
const ResultE10 = gsl.gsl_sf_result_e10;

// Converts a 
pub fn smash(r: ResultE10) Result {

}