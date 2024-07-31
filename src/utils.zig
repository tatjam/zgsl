const std = @import("std");

pub fn fatal(comptime format: []const u8, args: anytype) noreturn {
	std.debug.print(format, args);
	std.process.exit(1);
}