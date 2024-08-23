# State of the wrapper

I will slowly build the wrapper as I need different functions in my use cases. If you want to contribute
a wrapper, feel free to do so by creating a Pull Request! On the same way, if you want to request a 
wrapper feel free to create an Issue. 

Check below for the list of stuff that has been wrapped!

# Usage

## With Zig

Usage with Zig is as simple as adding a dependency to your `build.zig.zon`:

```Zig
.dependencies = .{
	.zgsl = .{
		.url = "TO BE SPECIFIED",
		.hash = "TO BE SPECIFIED",
	}
},
```

and including the dependency as needed in your `build.zig`:

```Zig 
const zgsl = b.dependency("zgsl", .{
	.target = target,
	.optimize = optimize
});

// ... for example, if you generate an executable ... 

const gsl_lib = zgsl.artifact("gsl");
exe.linkLibrary(gsl_lib);
exe.linkLibC();
exe.step.dependOn(&zgsl.namedWriteFiles("gsl_include").step);
```


Afterwards, depending on whether you want to use the wrapper or the raw functions (or both):

### Using the wrapper

To use the Zig wrapper, you will use the module:

```Zig    
exe.root_module.addImport("zgsl", zgsl.module("wrapper"));
exe.step.dependOn(&zgsl.builder.top_level_steps.get("wrap").?.step);
```

The second line guarantees wrappers are generated, as otherwise you would have to manually run 
`zig build wrap` on the downloaded dependency.

Now you have access to the wrapper under the name `zgsl`. For example, to compute a Bessel function:

```Zig     
const sf = @import("zgsl").sf;

...

const result = try sf.bessel.J0_e(5.0);
std.debug.print("Bessel J0(5.0) = {}, error = {}\n", .{result.val, result.err});
```

To learn more about the wrapper, check the tests contained in `src/test`, usage should be intuitive
coming from using the GSL library in C or other languages.

**It's heavily recommended** that you disable the default GSL error handler, as otherwise Zig errors 
will almost never be useful (GSL will panic before you can handle the errors). To do so use the 
function:

```Zig
const gsl = @import("zgsl")
//...
gsl.set_error_handler_off();
```

### Using the "raw" C library

In this case you also have to include the GSL header files and link with the 
library, which can be done as follows:

```Zig    
exe.addIncludePath(zgsl.namedWriteFiles("gsl_include").getDirectory().path(b, "include"));
```

Now you can directly call the GSL. The same example as before would be implemented as follows:

```Zig 
const gsl = @cImport({
    @cInclude("gsl/gsl_sf_bessel.h");
    @cInclude("gsl/gsl_errno.h");
});

...

var result_raw: gsl.gsl_sf_result = undefined;
const err = gsl.gsl_sf_bessel_J0_e(5.0, @ptrCast(&result_raw));
if(err != gsl.GSL_SUCCESS) {
	return error.GSL;
}
std.debug.print("Raw Bessel J0(5.0) = {}, error bound = {}\n", .{result_raw.val, result_raw.err});
```

The convenience of the wrapper, which exploits Zig's errors, should have become evident.

## With C / other languages

The wrapper cannot be used on C, but the building of the GSL is straightforward (and 
multiplatform). Simply run `zig build` and use the files generated in `zig-out` (static library
and header files) as you typically would.

# Wrapper status

(Unwrapped functions may be used directly from the C library, without the comfort of Zig of course!)

- [ ]	Mathematical functions
- [ ]	Polynomials
- [x]	Special functions
- [ ]	Vectors and Matrices
- [ ]	Permutations
- [ ]	Combinations
- [ ]	Multisets
- [ ]	Sorting
- [ ]	BLAS Support
- [ ]	Linear Algebra
- [ ]	Eigensystems
- [ ]	FFTs
- [ ]	Numerical Integration
- [ ]	RNG
- [ ]	Statistics
- [ ]	Running Statistics
- [ ]	Moving Window Statistics
- [ ]	Digital Filtering
- [ ]	Histograms
- [ ]	N-tuples
- [ ]	Monte Carlo Integration
- [ ]	Simulated Annealing
- [ ]	ODEs
- [ ]	Interpolation
- [ ]	Numerical differentiation
- [ ]	Chebyshev approximations
- [ ]	Series acceleration
- [ ]	Wavelet transforms
- [ ]	Discrete hankel transforms
- [ ]	1D root finding
- [ ]	1D minimization
- [ ]	nD root finding
- [ ]	nD minimization
- [ ]	Linear least squares
- [ ]	Nonlinear least squares
- [ ]	Basis splines
- [ ]	Sparse matrices
- [ ]	Sparse BLAS
- [ ]	Sparse Linear Algebra
- [ ]	Physical constants
- [ ]	IEEE floating point arithmetic