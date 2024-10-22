const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const upstream = b.dependency("gsl", .{});

    // Config generation

    const config_gen_tool = b.addExecutable(.{
        .name = "config_gen",
        .root_source_file = b.path("src/config_gen.zig"),
        .target = b.host,
    });

    const config_gen_step = b.addRunArtifact(config_gen_tool);
    const config_file = config_gen_step.addOutputFileArg("config.h");
    _ = config_gen_step.addOutputDirectoryArg("cfiles");

    // Header generation

    const header_gen_tool = b.addExecutable(.{
        .name = "header_gen",
        .root_source_file = b.path("src/header_gen.zig"),
        .target = b.host,
    });

    const header_gen_step = b.addRunArtifact(header_gen_tool);
    // Inside this folder, a "gsl/" directory is created that contains copies
    // of all other gsl files, as done by default by a Makefile
    // (Note that GSL actually makes symlinks)
    header_gen_step.addDirectoryArg(upstream.path(""));
    const gsl_files = header_gen_step.addOutputDirectoryArg("gsl_holder");

    // Static GSL library

    const gsl_lib = b.addStaticLibrary(.{
        .name = "gsl",
        .optimize = optimize,
        .target = target,
    });
    gsl_lib.linkLibC();

    // All source files in gls
    gsl_lib.addCSourceFiles(.{
        .root = upstream.path(""),
        .files = &gsl_sources,
    });
    gsl_lib.addIncludePath(upstream.path(""));
    gsl_lib.addIncludePath(config_file.dirname());
    gsl_lib.addIncludePath(gsl_files);

    // GSL header files

    // Copy gsl headers, if the user wants to use those directly
    const wf = b.addNamedWriteFiles("gsl_include");
    wf.step.dependOn(&header_gen_step.step);
    _ = wf.addCopyDirectory(gsl_files, "include", .{ .include_extensions = &[_][]const u8{".h"} });

    const headers_dir = b.addInstallDirectory(.{
        .source_dir = wf.getDirectory(),
        .install_dir = .prefix,
        .install_subdir = "",
    });
    headers_dir.step.dependOn(&wf.step);
    headers_dir.step.dependOn(&header_gen_step.step);

    // zgsl static library

    const lib = b.addStaticLibrary(.{
        .name = "zgsl",
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    lib.step.dependOn(&config_gen_step.step);
    lib.step.dependOn(&headers_dir.step);
    lib.linkLibrary(gsl_lib);

    b.installArtifact(gsl_lib);
    b.installArtifact(lib);

    // Wrapper generation tooling
    const wrapper_gen_tool = b.addExecutable(.{
        .name = "wrapper_gen",
        .root_source_file = b.path("src/wrapper_gen.zig"),
        .target = b.host,
    });

    const wrap_module = b.addModule("wrapper", .{
        .root_source_file = b.path("src/wrap/zgsl.zig"),
        .target = target,
        .optimize = optimize,
    });

    wrap_module.addIncludePath(wf.getDirectory().path(b, "include"));

    b.installArtifact(wrapper_gen_tool);

    // Unit testing and ZLS check

    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    lib_unit_tests.addIncludePath(wf.getDirectory().path(b, "include"));
    lib_unit_tests.linkLibC();
    lib_unit_tests.linkLibrary(gsl_lib);
    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    const test_bin = b.addInstallBinFile(lib_unit_tests.getEmittedBin(), "test");

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);

    const test_emit_step = b.step("test-emit", "Emit test-run binary");
    test_emit_step.dependOn(&test_bin.step);

    // For ZLS quick error reporting
    const lib_check = b.addTest(.{
        .name = "check",
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const check = b.step("check", "ZLS compile check (no binary emit)");
    check.dependOn(&lib_check.step);

    // Wrapper updating

    const source_files = b.addUpdateSourceFiles();

    const wrapper_gen_step = b.step("wrap", "Generate / update wrappers");
    for (&wrapper_pairs) |*pair| {
        const wrap_gen_step = b.addRunArtifact(wrapper_gen_tool);
        wrap_gen_step.addFileArg(wf.getDirectory().path(b, pair.in));
        pair.fout = wrap_gen_step.addOutputFileArg(pair.out);
        wrap_gen_step.addArg(pair.logic);

        // We must update the source files themselves
        const spath = b.allocator.alloc(u8, pair.out.len + 9) catch unreachable;
        @memcpy(spath[0..9], "src/wrap/");
        @memcpy(spath[9..], pair.out);
        source_files.addCopyFileToSource(pair.fout.?, spath);

        source_files.step.dependOn(&wrap_gen_step.step);
        wrapper_gen_step.dependOn(&source_files.step);
    }
}

const WrapperPair = struct {
    in: []const u8,
    out: []const u8,
    logic: []const u8,
    fout: ?std.Build.LazyPath,
};

var wrapper_pairs = [_]WrapperPair{
    .{
        .in = "include/gsl/gsl_sf_airy.h",
        .out = "wrapped_sf_airy.zig",
        .logic = "sf",
        .fout = null,
    },
    .{
        .in = "include/gsl/gsl_sf_bessel.h",
        .out = "wrapped_sf_bessel.zig",
        .logic = "sf",
        .fout = null,
    },
    .{
        .in = "include/gsl/gsl_sf_clausen.h",
        .out = "wrapped_sf_clausen.zig",
        .logic = "sf",
        .fout = null,
    },
    .{
        .in = "include/gsl/gsl_sf_coulomb.h",
        .out = "wrapped_sf_coulomb.zig",
        .logic = "sf",
        .fout = null,
    },
    .{
        .in = "include/gsl/gsl_sf_coupling.h",
        .out = "wrapped_sf_coupling.zig",
        .logic = "sf",
        .fout = null,
    },
    .{
        .in = "include/gsl/gsl_sf_dawson.h",
        .out = "wrapped_sf_dawson.zig",
        .logic = "sf",
        .fout = null,
    },
    .{
        .in = "include/gsl/gsl_sf_debye.h",
        .out = "wrapped_sf_debye.zig",
        .logic = "sf",
        .fout = null,
    },
    .{
        .in = "include/gsl/gsl_sf_dilog.h",
        .out = "wrapped_sf_dilog.zig",
        .logic = "sf",
        .fout = null,
    },
    .{
        .in = "include/gsl/gsl_sf_elementary.h",
        .out = "wrapped_sf_elementary.zig",
        .logic = "sf",
        .fout = null,
    },
    .{
        .in = "include/gsl/gsl_sf_ellint.h",
        .out = "wrapped_sf_ellint.zig",
        .logic = "sf",
        .fout = null,
    },
    .{
        .in = "include/gsl/gsl_sf_erf.h",
        .out = "wrapped_sf_erf.zig",
        .logic = "sf",
        .fout = null,
    },
    .{
        .in = "include/gsl/gsl_sf_exp.h",
        .out = "wrapped_sf_exp.zig",
        .logic = "sf",
        .fout = null,
    },
    .{
        .in = "include/gsl/gsl_sf_expint.h",
        .out = "wrapped_sf_expint.zig",
        .logic = "sf",
        .fout = null,
    },
    .{
        .in = "include/gsl/gsl_sf_fermi_dirac.h",
        .out = "wrapped_sf_fermi_dirac.zig",
        .logic = "sf",
        .fout = null,
    },
    .{
        .in = "include/gsl/gsl_sf_gamma.h",
        .out = "wrapped_sf_gamma.zig",
        .logic = "sf",
        .fout = null,
    },
    .{
        .in = "include/gsl/gsl_sf_gegenbauer.h",
        .out = "wrapped_sf_gegenbauer.zig",
        .logic = "sf",
        .fout = null,
    },
    .{
        .in = "include/gsl/gsl_sf_hermite.h",
        .out = "wrapped_sf_hermite.zig",
        .logic = "sf",
        .fout = null,
    },
    .{
        .in = "include/gsl/gsl_sf_hyperg.h",
        .out = "wrapped_sf_hyperg.zig",
        .logic = "sf",
        .fout = null,
    },
    .{
        .in = "include/gsl/gsl_sf_laguerre.h",
        .out = "wrapped_sf_laguerre.zig",
        .logic = "sf",
        .fout = null,
    },
    .{
        .in = "include/gsl/gsl_sf_lambert.h",
        .out = "wrapped_sf_lambert.zig",
        .logic = "sf",
        .fout = null,
    },
    //.{
    //    .in = "include/gsl/gsl_sf_legendre.h",
    //    .out = "wrapped_sf_legendre.zig",
    //    .logic = "sf",
    //    .fout = null,
    //},
    .{
        .in = "include/gsl/gsl_sf_log.h",
        .out = "wrapped_sf_log.zig",
        .logic = "sf",
        .fout = null,
    },
    //.{
    //    .in = "include/gsl/gsl_sf_mathieu.h",
    //    .out = "wrapped_sf_mathieu.zig",
    //    .logic = "sf",
    //   .fout = null,
    //},
    .{
        .in = "include/gsl/gsl_sf_pow_int.h",
        .out = "wrapped_sf_pow_int.zig",
        .logic = "sf",
        .fout = null,
    },
    .{
        .in = "include/gsl/gsl_sf_psi.h",
        .out = "wrapped_sf_psi.zig",
        .logic = "sf",
        .fout = null,
    },
    .{
        .in = "include/gsl/gsl_sf_sincos_pi.h",
        .out = "wrapped_sf_sincos_pi.zig",
        .logic = "sf",
        .fout = null,
    },
    .{
        .in = "include/gsl/gsl_sf_synchrotron.h",
        .out = "wrapped_sf_synchrotron.zig",
        .logic = "sf",
        .fout = null,
    },
    .{
        .in = "include/gsl/gsl_sf_transport.h",
        .out = "wrapped_sf_transport.zig",
        .logic = "sf",
        .fout = null,
    },
    .{
        .in = "include/gsl/gsl_sf_trig.h",
        .out = "wrapped_sf_trig.zig",
        .logic = "sf",
        .fout = null,
    },
    .{
        .in = "include/gsl/gsl_sf_zeta.h",
        .out = "wrapped_sf_zeta.zig",
        .logic = "sf",
        .fout = null,
    },
    .{
        .in = "include/gsl/gsl_fft_complex_float.h",
        .out = "wrapped_fft_complex_float.zig",
        .logic = "fft",
        .fout = null,
    },
    .{
        .in = "include/gsl/gsl_fft_complex.h",
        .out = "wrapped_fft_complex.zig",
        .logic = "fft",
        .fout = null,
    },
    .{
        .in = "include/gsl/gsl_fft_halfcomplex_float.h",
        .out = "wrapped_fft_halfcomplex_float.zig",
        .logic = "fft",
        .fout = null,
    },
    .{
        .in = "include/gsl/gsl_fft_halfcomplex.h",
        .out = "wrapped_fft_halfcomplex.zig",
        .logic = "fft",
        .fout = null,
    },
    .{
        .in = "include/gsl/gsl_fft_real_float.h",
        .out = "wrapped_fft_real_float.zig",
        .logic = "fft",
        .fout = null,
    },
    .{
        .in = "include/gsl/gsl_fft_real.h",
        .out = "wrapped_fft_real.zig",
        .logic = "fft",
        .fout = null,
    },
};

// NOTE TO USERS: If at any point you find a linker error, it's very likely
// it's simply a forgotten entry in the huge list below.

// TODO: This list is manually maintained!
// As of now, done by:
// ls | grep "\.c"
// manually copying and using a vim macro to insert proper folder structure
// removing all sources which are noinst (tests, _source, some others...)
//  (usually those give compile errors and thus are easy to identify)
const gsl_sources = [_][]const u8{
    "blas/blas.c",

    "block/block.c",
    "block/file.c",
    "block/init.c",

    "bspline/bspline.c",
    "bspline/eval.c",
    "bspline/gram.c",
    "bspline/greville.c",
    "bspline/inline.c",
    "bspline/integ.c",
    "bspline/interp.c",
    "bspline/ls.c",
    "bspline/old.c",

    "bst/avl.c",
    "bst/bst.c",
    "bst/rb.c",
    "bst/trav.c",

    "cblas/caxpy.c",
    "cblas/ccopy.c",
    "cblas/cdotc_sub.c",
    "cblas/cdotu_sub.c",
    "cblas/cgbmv.c",
    "cblas/cgemm.c",
    "cblas/cgemv.c",
    "cblas/cgerc.c",
    "cblas/cgeru.c",
    "cblas/chbmv.c",
    "cblas/chemm.c",
    "cblas/chemv.c",
    "cblas/cher2.c",
    "cblas/cher2k.c",
    "cblas/cher.c",
    "cblas/cherk.c",
    "cblas/chpmv.c",
    "cblas/chpr2.c",
    "cblas/chpr.c",
    "cblas/cscal.c",
    "cblas/csscal.c",
    "cblas/cswap.c",
    "cblas/csymm.c",
    "cblas/csyr2k.c",
    "cblas/csyrk.c",
    "cblas/ctbmv.c",
    "cblas/ctbsv.c",
    "cblas/ctpmv.c",
    "cblas/ctpsv.c",
    "cblas/ctrmm.c",
    "cblas/ctrmv.c",
    "cblas/ctrsm.c",
    "cblas/ctrsv.c",
    "cblas/dasum.c",
    "cblas/daxpy.c",
    "cblas/dcopy.c",
    "cblas/ddot.c",
    "cblas/dgbmv.c",
    "cblas/dgemm.c",
    "cblas/dgemv.c",
    "cblas/dger.c",
    "cblas/dnrm2.c",
    "cblas/drot.c",
    "cblas/drotg.c",
    "cblas/drotm.c",
    "cblas/drotmg.c",
    "cblas/dsbmv.c",
    "cblas/dscal.c",
    "cblas/dsdot.c",
    "cblas/dspmv.c",
    "cblas/dspr2.c",
    "cblas/dspr.c",
    "cblas/dswap.c",
    "cblas/dsymm.c",
    "cblas/dsymv.c",
    "cblas/dsyr2.c",
    "cblas/dsyr2k.c",
    "cblas/dsyr.c",
    "cblas/dsyrk.c",
    "cblas/dtbmv.c",
    "cblas/dtbsv.c",
    "cblas/dtpmv.c",
    "cblas/dtpsv.c",
    "cblas/dtrmm.c",
    "cblas/dtrmv.c",
    "cblas/dtrsm.c",
    "cblas/dtrsv.c",
    "cblas/dzasum.c",
    "cblas/dznrm2.c",
    "cblas/hypot.c",
    "cblas/icamax.c",
    "cblas/idamax.c",
    "cblas/isamax.c",
    "cblas/izamax.c",
    "cblas/sasum.c",
    "cblas/saxpy.c",
    "cblas/scasum.c",
    "cblas/scnrm2.c",
    "cblas/scopy.c",
    "cblas/sdot.c",
    "cblas/sdsdot.c",
    "cblas/sgbmv.c",
    "cblas/sgemm.c",
    "cblas/sgemv.c",
    "cblas/sger.c",
    "cblas/snrm2.c",
    "cblas/srot.c",
    "cblas/srotg.c",
    "cblas/srotm.c",
    "cblas/srotmg.c",
    "cblas/ssbmv.c",
    "cblas/sscal.c",
    "cblas/sspmv.c",
    "cblas/sspr2.c",
    "cblas/sspr.c",
    "cblas/sswap.c",
    "cblas/ssymm.c",
    "cblas/ssymv.c",
    "cblas/ssyr2.c",
    "cblas/ssyr2k.c",
    "cblas/ssyr.c",
    "cblas/ssyrk.c",
    "cblas/stbmv.c",
    "cblas/stbsv.c",
    "cblas/stpmv.c",
    "cblas/stpsv.c",
    "cblas/strmm.c",
    "cblas/strmv.c",
    "cblas/strsm.c",
    "cblas/strsv.c",
    "cblas/xerbla.c",
    "cblas/zaxpy.c",
    "cblas/zcopy.c",
    "cblas/zdotc_sub.c",
    "cblas/zdotu_sub.c",
    "cblas/zdscal.c",
    "cblas/zgbmv.c",
    "cblas/zgemm.c",
    "cblas/zgemv.c",
    "cblas/zgerc.c",
    "cblas/zgeru.c",
    "cblas/zhbmv.c",
    "cblas/zhemm.c",
    "cblas/zhemv.c",
    "cblas/zher2.c",
    "cblas/zher2k.c",
    "cblas/zher.c",
    "cblas/zherk.c",
    "cblas/zhpmv.c",
    "cblas/zhpr2.c",
    "cblas/zhpr.c",
    "cblas/zscal.c",
    "cblas/zswap.c",
    "cblas/zsymm.c",
    "cblas/zsyr2k.c",
    "cblas/zsyrk.c",
    "cblas/ztbmv.c",
    "cblas/ztbsv.c",
    "cblas/ztpmv.c",
    "cblas/ztpsv.c",
    "cblas/ztrmm.c",
    "cblas/ztrmv.c",
    "cblas/ztrsm.c",
    "cblas/ztrsv.c",

    "cdf/beta.c",
    "cdf/betainv.c",
    "cdf/binomial.c",
    "cdf/cauchy.c",
    "cdf/cauchyinv.c",
    "cdf/chisq.c",
    "cdf/chisqinv.c",
    "cdf/exponential.c",
    "cdf/exponentialinv.c",
    "cdf/exppow.c",
    "cdf/fdist.c",
    "cdf/fdistinv.c",
    "cdf/flat.c",
    "cdf/flatinv.c",
    "cdf/gamma.c",
    "cdf/gammainv.c",
    "cdf/gauss.c",
    "cdf/gaussinv.c",
    "cdf/geometric.c",
    "cdf/gumbel1.c",
    "cdf/gumbel1inv.c",
    "cdf/gumbel2.c",
    "cdf/gumbel2inv.c",
    "cdf/hypergeometric.c",
    "cdf/laplace.c",
    "cdf/laplaceinv.c",
    "cdf/logistic.c",
    "cdf/logisticinv.c",
    "cdf/lognormal.c",
    "cdf/lognormalinv.c",
    "cdf/nbinomial.c",
    "cdf/pareto.c",
    "cdf/paretoinv.c",
    "cdf/pascal.c",
    "cdf/poisson.c",
    "cdf/rayleigh.c",
    "cdf/rayleighinv.c",
    "cdf/tdist.c",
    "cdf/tdistinv.c",
    "cdf/weibull.c",
    "cdf/weibullinv.c",

    "cheb/deriv.c",
    "cheb/eval.c",
    "cheb/init.c",
    "cheb/integ.c",

    "combination/combination.c",
    "combination/file.c",
    "combination/init.c",
    "combination/inline.c",

    "complex/inline.c",
    "complex/math.c",

    "deriv/deriv.c",

    "dht/dht.c",

    "diff/diff.c",

    "eigen/francis.c",
    "eigen/gen.c",
    "eigen/genherm.c",
    "eigen/genhermv.c",
    "eigen/gensymm.c",
    "eigen/gensymmv.c",
    "eigen/genv.c",
    "eigen/herm.c",
    "eigen/hermv.c",
    "eigen/jacobi.c",
    "eigen/nonsymm.c",
    "eigen/nonsymmv.c",
    "eigen/schur.c",
    "eigen/sort.c",
    "eigen/symm.c",
    "eigen/symmv.c",

    "err/message.c",
    "err/strerror.c",
    "err/error.c",
    "err/stream.c",

    "fft/dft.c",
    "fft/fft.c",
    "fft/signals.c",

    "filter/gaussian.c",
    "filter/impulse.c",
    "filter/median.c",
    "filter/rmedian.c",

    "fit/linear.c",

    "histogram/add2d.c",
    "histogram/add.c",
    "histogram/calloc_range2d.c",
    "histogram/calloc_range.c",
    "histogram/copy2d.c",
    "histogram/copy.c",
    "histogram/file2d.c",
    "histogram/file.c",
    "histogram/get2d.c",
    "histogram/get.c",
    "histogram/init2d.c",
    "histogram/init.c",
    "histogram/maxval2d.c",
    "histogram/maxval.c",
    "histogram/oper2d.c",
    "histogram/oper.c",
    "histogram/params2d.c",
    "histogram/params.c",
    "histogram/pdf2d.c",
    "histogram/pdf.c",
    "histogram/reset2d.c",
    "histogram/reset.c",
    "histogram/stat2d.c",
    "histogram/stat.c",

    // TODO: ieee-utils

    "integration/chebyshev2.c",
    "integration/chebyshev.c",
    "integration/cquad.c",
    "integration/exponential.c",
    "integration/fixed.c",
    "integration/gegenbauer.c",
    "integration/glfixed.c",
    "integration/hermite.c",
    "integration/jacobi.c",
    "integration/laguerre.c",
    "integration/lebedev.c",
    "integration/legendre.c",
    "integration/qag.c",
    "integration/qagp.c",
    "integration/qags.c",
    "integration/qawc.c",
    "integration/qawf.c",
    "integration/qawo.c",
    "integration/qaws.c",
    "integration/qcheb.c",
    "integration/qk15.c",
    "integration/qk21.c",
    "integration/qk31.c",
    "integration/qk41.c",
    "integration/qk51.c",
    "integration/qk61.c",
    "integration/qk.c",
    "integration/qmomo.c",
    "integration/qmomof.c",
    "integration/qng.c",
    "integration/rational.c",
    "integration/romberg.c",
    "integration/workspace.c",

    "interpolation/accel.c",
    "interpolation/akima.c",
    "interpolation/bicubic.c",
    "interpolation/bilinear.c",
    "interpolation/cspline.c",
    "interpolation/inline.c",
    "interpolation/interp2d.c",
    "interpolation/interp.c",
    "interpolation/linear.c",
    "interpolation/poly.c",
    "interpolation/spline2d.c",
    "interpolation/spline.c",
    "interpolation/steffen.c",

    "linalg/balance.c",
    "linalg/balancemat.c",
    "linalg/bidiag.c",
    "linalg/cholesky_band.c",
    "linalg/cholesky.c",
    "linalg/choleskyc.c",
    "linalg/cod.c",
    "linalg/condest.c",
    "linalg/exponential.c",
    "linalg/hermtd.c",
    "linalg/hessenberg.c",
    "linalg/hesstri.c",
    "linalg/hh.c",
    "linalg/householder.c",
    "linalg/householdercomplex.c",
    "linalg/inline.c",
    "linalg/invtri.c",
    "linalg/invtri_complex.c",
    "linalg/ldlt_band.c",
    "linalg/ldlt.c",
    "linalg/lq.c",
    "linalg/lu_band.c",
    "linalg/lu.c",
    "linalg/luc.c",
    "linalg/mcholesky.c",
    "linalg/multiply.c",
    "linalg/pcholesky.c",
    "linalg/ptlq.c",
    "linalg/ql.c",
    "linalg/qr_band.c",
    "linalg/qr.c",
    "linalg/qrc.c",
    "linalg/qrpt.c",
    "linalg/qr_ud.c",
    "linalg/qr_ur.c",
    "linalg/qr_uu.c",
    "linalg/qr_uz.c",
    "linalg/rqr.c",
    "linalg/rqrc.c",
    "linalg/svd.c",
    "linalg/symmtd.c",
    "linalg/tridiag.c",
    "linalg/trimult.c",
    "linalg/trimult_complex.c",

    "matrix/copy.c",
    "matrix/file.c",
    "matrix/getset.c",
    "matrix/init.c",
    "matrix/matrix.c",
    "matrix/minmax.c",
    "matrix/oper.c",
    "matrix/prop.c",
    "matrix/rowcol.c",
    "matrix/submatrix.c",
    "matrix/swap.c",
    "matrix/view.c",

    "min/bracketing.c",
    "min/brent.c",
    "min/convergence.c",
    "min/fsolver.c",
    "min/golden.c",
    "min/quad_golden.c",

    "monte/miser.c",
    "monte/plain.c",
    "monte/vegas.c",

    "movstat/alloc.c",
    "movstat/apply.c",
    "movstat/fill.c",
    "movstat/funcacc.c",
    "movstat/madacc.c",
    "movstat/medacc.c",
    "movstat/mmacc.c",
    "movstat/movmad.c",
    "movstat/movmean.c",
    "movstat/movmedian.c",
    "movstat/movminmax.c",
    "movstat/movQn.c",
    "movstat/movqqr.c",
    "movstat/movSn.c",
    "movstat/movsum.c",
    "movstat/movvariance.c",
    "movstat/mvacc.c",
    "movstat/qnacc.c",
    "movstat/qqracc.c",
    "movstat/snacc.c",
    "movstat/sumacc.c",

    "multifit/convergence.c",
    "multifit/covar.c",
    "multifit/fdfridge.c",
    "multifit/fdfsolver.c",
    "multifit/fdjac.c",
    "multifit/fsolver.c",
    "multifit/gcv.c",
    "multifit/gradient.c",
    "multifit/lmder.c",
    "multifit/lmniel.c",
    "multifit/multilinear.c",
    "multifit/multireg.c",
    "multifit/multirobust.c",
    "multifit/multiwlinear.c",
    "multifit/robust_wfun.c",
    "multifit/work.c",

    "multifit_nlinear/cholesky.c",
    "multifit_nlinear/convergence.c",
    "multifit_nlinear/covar.c",
    "multifit_nlinear/dogleg.c",
    "multifit_nlinear/fdf.c",
    "multifit_nlinear/fdfvv.c",
    "multifit_nlinear/fdjac.c",
    "multifit_nlinear/lm.c",
    "multifit_nlinear/mcholesky.c",
    "multifit_nlinear/qr.c",
    "multifit_nlinear/scaling.c",
    "multifit_nlinear/subspace2D.c",
    "multifit_nlinear/svd.c",
    "multifit_nlinear/trust.c",

    "multilarge/multilarge.c",
    "multilarge/normal.c",
    "multilarge/tsqr.c",

    "multilarge_nlinear/cgst.c",
    "multilarge_nlinear/cholesky.c",
    "multilarge_nlinear/convergence.c",
    "multilarge_nlinear/dogleg.c",
    "multilarge_nlinear/dummy.c",
    "multilarge_nlinear/fdf.c",
    "multilarge_nlinear/lm.c",
    "multilarge_nlinear/mcholesky.c",
    "multilarge_nlinear/scaling.c",
    "multilarge_nlinear/subspace2D.c",
    "multilarge_nlinear/trust.c",

    "multimin/conjugate_fr.c",
    "multimin/conjugate_pr.c",
    "multimin/convergence.c",
    "multimin/diff.c",
    "multimin/fdfminimizer.c",
    "multimin/fminimizer.c",
    "multimin/simplex2.c",
    "multimin/simplex.c",
    "multimin/steepest_descent.c",
    "multimin/vector_bfgs2.c",
    "multimin/vector_bfgs.c",

    "multiroots/broyden.c",
    "multiroots/convergence.c",
    "multiroots/dnewton.c",
    "multiroots/fdfsolver.c",
    "multiroots/fdjac.c",
    "multiroots/fsolver.c",
    "multiroots/gnewton.c",
    "multiroots/hybrid.c",
    "multiroots/hybridj.c",
    "multiroots/newton.c",

    "multiset/file.c",
    "multiset/init.c",
    "multiset/inline.c",
    "multiset/multiset.c",

    "ntuple/ntuple.c",

    "ode-initval/bsimp.c",
    "ode-initval/control.c",
    "ode-initval/cscal.c",
    "ode-initval/cstd.c",
    "ode-initval/evolve.c",
    "ode-initval/gear1.c",
    "ode-initval/gear2.c",
    "ode-initval/rk2.c",
    "ode-initval/rk2imp.c",
    "ode-initval/rk2simp.c",
    "ode-initval/rk4.c",
    "ode-initval/rk4imp.c",
    "ode-initval/rk8pd.c",
    "ode-initval/rkck.c",
    "ode-initval/rkf45.c",
    "ode-initval/step.c",

    "ode-initval2/bsimp.c",
    "ode-initval2/control.c",
    "ode-initval2/cscal.c",
    "ode-initval2/cstd.c",
    "ode-initval2/driver.c",
    "ode-initval2/evolve.c",
    "ode-initval2/msadams.c",
    "ode-initval2/msbdf.c",
    "ode-initval2/rk1imp.c",
    "ode-initval2/rk2.c",
    "ode-initval2/rk2imp.c",
    "ode-initval2/rk4.c",
    "ode-initval2/rk4imp.c",
    "ode-initval2/rk8pd.c",
    "ode-initval2/rkck.c",
    "ode-initval2/rkf45.c",
    "ode-initval2/step.c",

    "permutation/canonical.c",
    "permutation/file.c",
    "permutation/init.c",
    "permutation/inline.c",
    "permutation/permutation.c",
    "permutation/permute.c",

    "poly/dd.c",
    "poly/deriv.c",
    "poly/eval.c",
    "poly/solve_cubic.c",
    "poly/solve_quadratic.c",
    "poly/zsolve.c",
    "poly/zsolve_cubic.c",
    "poly/zsolve_init.c",
    "poly/zsolve_quadratic.c",

    "qrng/halton.c",
    "qrng/inline.c",
    "qrng/niederreiter-2.c",
    "qrng/qrng.c",
    "qrng/reversehalton.c",
    "qrng/sobol.c",

    "randist/bernoulli.c",
    "randist/beta.c",
    "randist/bigauss.c",
    "randist/binomial.c",
    "randist/binomial_tpe.c",
    "randist/cauchy.c",
    "randist/chisq.c",
    "randist/dirichlet.c",
    "randist/discrete.c",
    "randist/erlang.c",
    "randist/exponential.c",
    "randist/exppow.c",
    "randist/fdist.c",
    "randist/flat.c",
    "randist/gamma.c",
    "randist/gauss.c",
    "randist/gausstail.c",
    "randist/gausszig.c",
    "randist/geometric.c",
    "randist/gumbel.c",
    "randist/hyperg.c",
    "randist/landau.c",
    "randist/laplace.c",
    "randist/levy.c",
    "randist/logarithmic.c",
    "randist/logistic.c",
    "randist/lognormal.c",
    "randist/multinomial.c",
    "randist/mvgauss.c",
    "randist/nbinomial.c",
    "randist/pareto.c",
    "randist/pascal.c",
    "randist/poisson.c",
    "randist/rayleigh.c",
    "randist/shuffle.c",
    "randist/sphere.c",
    "randist/tdist.c",
    "randist/weibull.c",
    "randist/wishart.c",

    "rng/borosh13.c",
    "rng/cmrg.c",
    "rng/coveyou.c",
    "rng/default.c",
    "rng/file.c",
    "rng/fishman18.c",
    "rng/fishman20.c",
    "rng/fishman2x.c",
    "rng/gfsr4.c",
    "rng/inline.c",
    "rng/knuthran2002.c",
    "rng/knuthran2.c",
    "rng/knuthran.c",
    "rng/lecuyer21.c",
    "rng/minstd.c",
    "rng/mrg.c",
    "rng/mt.c",
    "rng/r250.c",
    "rng/ran0.c",
    "rng/ran1.c",
    "rng/ran2.c",
    "rng/ran3.c",
    "rng/rand48.c",
    "rng/rand.c",
    "rng/random.c",
    "rng/randu.c",
    "rng/ranf.c",
    "rng/ranlux.c",
    "rng/ranlxd.c",
    "rng/ranlxs.c",
    "rng/ranmar.c",
    "rng/rng.c",
    "rng/schrage.c",
    "rng/slatec.c",
    "rng/taus113.c",
    "rng/taus.c",
    "rng/transputer.c",
    "rng/tt.c",
    "rng/types.c",
    "rng/uni32.c",
    "rng/uni.c",
    "rng/vax.c",
    "rng/waterman14.c",
    "rng/zuf.c",

    "roots/bisection.c",
    "roots/brent.c",
    "roots/convergence.c",
    "roots/falsepos.c",
    "roots/fdfsolver.c",
    "roots/fsolver.c",
    "roots/newton.c",
    "roots/secant.c",
    "roots/steffenson.c",

    "rstat/rquantile.c",
    "rstat/rstat.c",

    "siman/siman.c",

    "sort/sort.c",
    "sort/sortind.c",
    "sort/sortvec.c",
    "sort/sortvecind.c",
    "sort/subset.c",
    "sort/subsetind.c",

    "spblas/spdgemm.c",
    "spblas/spdgemv.c",

    "specfunc/airy.c",
    "specfunc/airy_der.c",
    "specfunc/airy_zero.c",
    "specfunc/alf_P.c",
    "specfunc/atanint.c",
    "specfunc/bessel_amp_phase.c",
    "specfunc/bessel.c",
    "specfunc/bessel_I0.c",
    "specfunc/bessel_I1.c",
    "specfunc/bessel_i.c",
    "specfunc/bessel_In.c",
    "specfunc/bessel_Inu.c",
    "specfunc/bessel_J0.c",
    "specfunc/bessel_J1.c",
    "specfunc/bessel_j.c",
    "specfunc/bessel_Jn.c",
    "specfunc/bessel_Jnu.c",
    "specfunc/bessel_K0.c",
    "specfunc/bessel_K1.c",
    "specfunc/bessel_k.c",
    "specfunc/bessel_Kn.c",
    "specfunc/bessel_Knu.c",
    "specfunc/bessel_olver.c",
    "specfunc/bessel_sequence.c",
    "specfunc/bessel_temme.c",
    "specfunc/bessel_Y0.c",
    "specfunc/bessel_Y1.c",
    "specfunc/bessel_y.c",
    "specfunc/bessel_Yn.c",
    "specfunc/bessel_Ynu.c",
    "specfunc/bessel_zero.c",
    "specfunc/beta.c",
    "specfunc/beta_inc.c",
    "specfunc/clausen.c",
    "specfunc/coulomb_bound.c",
    "specfunc/coulomb.c",
    "specfunc/coupling.c",
    "specfunc/dawson.c",
    "specfunc/debye.c",
    "specfunc/dilog.c",
    "specfunc/elementary.c",
    "specfunc/ellint.c",
    "specfunc/elljac.c",
    "specfunc/erfc.c",
    "specfunc/exp.c",
    "specfunc/expint3.c",
    "specfunc/expint.c",
    "specfunc/fermi_dirac.c",
    "specfunc/gamma.c",
    "specfunc/gamma_inc.c",
    "specfunc/gegenbauer.c",
    "specfunc/hermite.c",
    "specfunc/hyperg_0F1.c",
    "specfunc/hyperg_1F1.c",
    "specfunc/hyperg_2F0.c",
    "specfunc/hyperg_2F1.c",
    "specfunc/hyperg.c",
    "specfunc/hyperg_U.c",
    "specfunc/inline.c",
    "specfunc/laguerre.c",
    "specfunc/lambert.c",
    "specfunc/legendre_con.c",
    "specfunc/legendre_H3d.c",
    "specfunc/legendre_P.c",
    "specfunc/legendre_poly.c",
    "specfunc/legendre_Qn.c",
    "specfunc/log.c",
    "specfunc/mathieu_angfunc.c",
    "specfunc/mathieu_charv.c",
    "specfunc/mathieu_coeff.c",
    "specfunc/mathieu_radfunc.c",
    "specfunc/mathieu_workspace.c",
    "specfunc/poch.c",
    "specfunc/pow_int.c",
    "specfunc/psi.c",
    "specfunc/result.c",
    "specfunc/shint.c",
    "specfunc/sincos_pi.c",
    "specfunc/sinint.c",
    "specfunc/synchrotron.c",
    "specfunc/transport.c",
    "specfunc/trig.c",
    "specfunc/zeta.c",

    "splinalg/gmres.c",
    "splinalg/itersolve.c",

    "spmatrix/compress.c",
    "spmatrix/copy.c",
    "spmatrix/file.c",
    "spmatrix/getset.c",
    "spmatrix/init.c",
    "spmatrix/minmax.c",
    "spmatrix/oper.c",
    "spmatrix/prop.c",
    "spmatrix/swap.c",
    "spmatrix/util.c",

    "statistics/absdev.c",
    "statistics/covariance.c",
    "statistics/gastwirth.c",
    "statistics/kurtosis.c",
    "statistics/lag1.c",
    "statistics/mad.c",
    "statistics/mean.c",
    "statistics/median.c",
    "statistics/minmax.c",
    "statistics/p_variance.c",
    "statistics/Qn.c",
    "statistics/quantiles.c",
    "statistics/select.c",
    "statistics/skew.c",
    "statistics/Sn.c",
    "statistics/test_nist.c",
    "statistics/test_robust.c",
    "statistics/trmean.c",
    "statistics/ttest.c",
    "statistics/variance.c",
    "statistics/wabsdev.c",
    "statistics/wkurtosis.c",
    "statistics/wmean.c",
    "statistics/wskew.c",
    "statistics/wvariance.c",

    "sum/levin_u.c",
    "sum/levin_utrunc.c",
    "sum/work_u.c",
    "sum/work_utrunc.c",

    "sys/coerce.c",
    "sys/expm1.c",
    "sys/fcmp.c",
    "sys/fdiv.c",
    "sys/hypot.c",
    "sys/infnan.c",
    "sys/invhyp.c",
    "sys/ldfrexp.c",
    "sys/log1p.c",
    "sys/minmax.c",
    "sys/pow_int.c",
    "sys/prec.c",

    "utils/placeholder.c",

    "vector/copy.c",
    "vector/file.c",
    "vector/init.c",
    "vector/minmax.c",
    "vector/oper.c",
    "vector/prop.c",
    "vector/reim.c",
    "vector/subvector.c",
    "vector/swap.c",
    "vector/vector.c",
    "vector/view.c",

    "wavelet/bspline.c",
    "wavelet/daubechies.c",
    "wavelet/dwt.c",
    "wavelet/haar.c",
    "wavelet/wavelet.c",

    "version.c",
};
