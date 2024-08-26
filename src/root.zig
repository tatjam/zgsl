const std = @import("std");
const testing = std.testing;
const sf = @import("wrap/sf.zig");

// All tests go here
comptime {
    _ = @import("test/sf.zig");
    _ = @import("test/fft.zig");
}
