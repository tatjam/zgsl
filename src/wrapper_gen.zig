const std = @import("std");
const parser = @import("wrap_gen/c_parse.zig");
const fatal = @import("utils.zig").fatal;

pub fn main() !void {
	var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
	defer arena_state.deinit();
	const arena = arena_state.allocator();

	const args = try std.process.argsAlloc(arena);
	if(args.len != 3) fatal("specify input file name, and output file name", .{});

	const input_fname = args[1];
	const output_fname = args[2];

	var fin = try std.fs.cwd().openFile(input_fname, .{});
	defer fin.close();

	// We don't memory manage! Just allocate as wished and free at the end
	const fin_contents = try fin.readToEndAlloc(arena, 1000000);
	const parsed = try parser.parse_c(arena, fin_contents);

	_ = parsed;
	
	var fout = try std.fs.cwd().createFile(output_fname, .{});
	defer fout.close();
	
	return std.process.cleanExit();
}