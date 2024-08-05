# State of the wrapper

I will slowly build the wrapper as I need different functions in my use cases. If you want to contribute
a wrapper, feel free to do so by creating a Pull Request! On the same way, if you want to request a 
wrapper feel free to create an Issue. 

Check below for the list of stuff that has been wrapped!

# Usage

## With Zig

Usage with Zig is as simple as adding a dependency to your `build.zig.zon`:

```Zig

```

and including the dependency as needed in your `build.zig`:


### Using the wrapper

To use the Zig wrapper, you will use the module:

```Zig

```

### Using the "raw" C library

If you don't want to use the wrapper, you have to also include the 
GSL header files, which can be done as follows:

```Zig
```

## With C / other languages

The wrapper cannot be used on C, but the building of the GSL is straightforward (and 
multiplatform). Simply run `zig build` and use the files generated in `zig-out` (static library
and header files) as you typically would.

# Wrapper status

(Unwrapped functions may be used directly from the C library, without the comfort of Zig of course!)

- [ ]	Mathematical functions
- [ ]	Polynomials
- [ ]	Special functions
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