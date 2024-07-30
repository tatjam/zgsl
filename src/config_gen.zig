const std = @import("std");

pub fn main() !void {
	var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
	defer arena_state.deinit();
	const arena = arena_state.allocator();

	const args = try std.process.argsAlloc(arena);
	if(args.len != 3) fatal("specify output file name, and output folder name", .{});

	const output_file_path = args[1];
	const output_dir_path = args[2];

	var fout = try std.fs.cwd().createFile(output_file_path, .{});
	defer fout.close();

	// This is mostly taken from the CMake version found at 
	// https://github.com/ampl/gsl/blob/master/CMakeLists.txt
	const works = try checkCCompiles("int main(void) {}", output_dir_path, arena);
	_ = works;


	return std.process.cleanExit();
}

fn fatal(comptime format: []const u8, args: anytype) noreturn {
	std.debug.print(format, args);
	std.process.exit(1);
}

fn checkCCompiles(code: [] const u8, path: [:0] u8, alloc: std.mem.Allocator) !bool {
	const hash = std.hash.Crc32.hash(code);
	const file_path = try std.fmt.allocPrint(alloc, "{s}/{}.c", 
	.{path, hash});
	const ofile_path = try std.fmt.allocPrint(alloc, "{s}/{}.o", 
	.{path, hash});

	// Note that this file is already running in a "tmp" location, so we 
	// can simply do this, we use the hash of the code string as filename
	{
		var fout = try std.fs.cwd().createFile(file_path, .{});
		defer fout.close();
		_ = try fout.write(code);
	}

	// Now we invoke zig to compile the C source
	const argv = [_][] const u8 {"zig", "cc", file_path, "-o", ofile_path};
	var child = std.process.Child.init(&argv, alloc);
	child.cwd = path;
	const res = try child.spawnAndWait();
	const ret = switch(res) {
		.Exited => |v| v == 0,
		// TODO: This could be made more robust by emitting an error message
		else => false,
	};

	return ret;

}