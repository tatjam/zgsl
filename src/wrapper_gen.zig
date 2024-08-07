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
	const preproc = try parser.preprocess(arena, fin_contents);
	const blocks = try parser.block_separate(arena, preproc);

	// The first block is always the license header, and may be ignored
	// Each block afterwards is formed by:
	// -an optional doc string
	// -one or more functions
	// We try to parse each block as those, failure simply leads to the block being ignored

	for(blocks.items[1..]) |block| {
		const funcs = try parser.parse_block(arena, block.items);
		for(funcs) |func| {
			std.log.info("Function:\n Name: {s}\n Ret: {s}\n Doc: {s}", 
				.{func.name, func.rettype, func.doc});
			for(func.arg_names, 0..) |arg, i| {
				std.log.info("Arg {}, type {s}, name {s}\n", .{i, func.arg_types[i], arg});
			}
			for(func.exceptions, 0..) |exc, i| {
				std.log.info("Excpt {}: {s}\n", .{i, exc});
			}
		}
	}
	
	var fout = try std.fs.cwd().createFile(output_fname, .{});
	defer fout.close();
	
	return std.process.cleanExit();
}