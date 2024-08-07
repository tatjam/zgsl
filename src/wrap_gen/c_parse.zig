const std = @import("std");

// We use a simple state machine to parse the GSL headers
// THIS IS NOT A GENERAL PURPOSE C PARSER! It's only valid for the
// very simple subset of C used in GSL headers
// (for example, if any "raw" function pointer is present, this will break!)
// Also, memory is simply leaked, so make sure to free the whole allocator passed

const ParsedCFunction = struct {
	name: [] u8,
	rettype: [] u8,
	arg_names: [] [] u8,
	arg_types: [] [] u8,
	exceptions: [] [] u8,
	doc: [] u8,
};

const StateMachine = enum {
	HEADER,
	DOC,
	RET_TYPE,
	FUNC_NAME,
	ARGS,
	SEEK_NEXT,
	FINISH
};

pub fn advance_until_str(pos: *usize, data: [] const u8, needle: [] const u8) bool {
	var in_track: usize = 0;
	while(pos.* < data.len) {
		if(data[pos.*] == needle[in_track]) {
			in_track += 1;
		}
		
		if(in_track == needle.len) return true;

		pos.* += 1;
	}

	return false;
}

// Assumes cursor is at the start of a C function def, and parses until the definition ends
pub fn advance_c_ret_type(pos: *usize, data: [] const u8) !void {
	// We actually advance until the last " " before "("
	var open_par_pos = pos.*;
	if(!advance_until_str(&open_par_pos, data, "(")) {
		return error.InvalidFunction;
	}

	// Now find the last space before "("
	var last_pos = pos.*;
	var next_pos = pos.*;

	while(next_pos < open_par_pos) {
		last_pos = next_pos;
		
		if(!advance_until_str(&next_pos, data, " ")) {
			return error.InvalidFunction;
		}
	}

	// last_pos now points to the last space before "(", which delimits the type
	pos.* = last_pos;

}

// flavor0 files are our favorite. Every function is documented,
// and includes exceptions that it may throw
pub fn parse_c_flavor0(alloc: std.mem.Allocator, data: []const u8) !std.ArrayList(ParsedCFunction) {
	var st: StateMachine = .HEADER;
	var pos: usize = 0;
	var out = std.ArrayList(ParsedCFunction).init(alloc);
	var cur_symbol: ParsedCFunction = undefined;

	while(st != .FINISH) {
		if(st == .HEADER) {
			std.log.info("ENTER .HEADER", .{});
			// Wait for __BEGIN_DECLS
			if(!advance_until_str(&pos, data, "__BEGIN_DECLS")) {
				return error.InvalidHeader;
			}

			// Move to first function docs
			if(!advance_until_str(&pos, data, "/*")) {
				return error.InvalidHeader;
			}

			st = .DOC;

		} else if(st == .DOC) {
			std.log.info("ENTER .DOC", .{});
			// Save location of start of doc 
			const start_doc = pos;

			// And move to its end
			if(!advance_until_str(&pos, data, "*/")) {
				return error.UnfinishedDoc;
			}

			cur_symbol.doc = try alloc.alloc(u8, pos - start_doc);
			std.mem.copyForwards(u8, cur_symbol.doc, data[start_doc..pos]);
			
			st = .RET_TYPE;
		} else if(st == .RET_TYPE) {
			std.log.info("ENTER .RET_TYPE", .{});
			const start_ret = pos;

			try advance_c_ret_type(&pos, data);

			cur_symbol.rettype = try alloc.alloc(u8, pos - start_ret);
			std.mem.copyForwards(u8, cur_symbol.rettype, data[start_ret..pos]);

			st = .FUNC_NAME;
		} else if(st == .FUNC_NAME) {
			std.log.info("ENTER .FUNC_NAME", .{});
			const start_name = pos;

			if(!advance_until_str(&pos, data, "(")) {
				return error.InvalidFunction;
			}

			cur_symbol.name = try alloc.alloc(u8, pos - start_name);
			std.mem.copyForwards(u8, cur_symbol.name, data[start_name..pos]);

			st = .ARGS;
		} else if(st == .ARGS) {
			std.log.info("ENTER .ARGS", .{});

		} else if(st == .SEEK_NEXT) {
			std.log.info("ENTER .SEEK_NEXT", .{});

			try out.append(cur_symbol);
		}
	}

	return out;
}

// Similar to before, but 
pub fn parse_c_flavor1(alloc: std.mem.Allocator, data: [] const u8) !std.ArrayList(ParsedCFunction) {

}