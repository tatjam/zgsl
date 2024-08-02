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
