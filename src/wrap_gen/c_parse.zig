const std = @import("std");

pub const ParsedCFunction = struct {
    name: []u8,
    rettype: []u8,
    arg_names: [][]u8,
    arg_types: [][]u8,
    exceptions: [][]u8,
    doc: []u8,
};

// Trims and removes macros
pub fn preprocess(alloc: std.mem.Allocator, data: []const u8) ![]const u8 {
    // At most, out is as big as the input file
    var out: []u8 = try alloc.alloc(u8, data.len);
    var opos: usize = 0;
    var inifdef: i32 = 0;

    // Iterate over data line by line
    var it = std.mem.splitAny(u8, data, "\n");
    while (it.next()) |x| {
        if(inifdef == 0) {
            if(std.mem.startsWith(u8, x, "#endif")) {
                inifdef -= 1;
            }
        } else {
            if (std.mem.startsWith(u8, x, "#")) {
                if(std.mem.startsWith(u8, x, "#ifdef")) {
                    inifdef += 1;
                }
                continue;
            }
            const xt = std.mem.trim(u8, x, " \t");
            std.mem.copyForwards(u8, out[opos..(opos + xt.len)], xt);
            opos += xt.len;
            out[opos] = '\n';
            opos += 1;
        }
    }

    return out[0..opos];
}

// Separates the source in blocks, ie, sections separated by more than one
// line break (ie, atleast one empty line)
pub fn block_separate(alloc: std.mem.Allocator, data: []const u8) !std.ArrayList(std.ArrayList(u8)) {
    var out = std.ArrayList(std.ArrayList(u8)).init(alloc);
    var acc = std.ArrayList(u8).init(alloc);

    var last_empty: usize = 0;

    var it = std.mem.splitAny(u8, data, "\n");
    while (it.next()) |x| {
        if (x.len == 0) {
            // Empty line
            last_empty += 1;
            continue;
        }

        if (last_empty >= 2) {
            // Save previous buffer
            try out.append(try acc.clone());
            try acc.resize(0);
            last_empty = 0;
        }

        // Append to the accumulator
        try acc.appendSlice(x);
        try acc.append('\n');
    }

    // Save acc if it's not empty
    if (acc.items.len != 0) {
        try out.append(acc);
    }

    return out;
}

// Returns the number of characters parsed as doc string
pub fn parse_doc(alloc: std.mem.Allocator, block: []const u8, to: *ParsedCFunction) !usize {
    var parsed: usize = 0;
    if (std.mem.startsWith(u8, block, "/*")) {
        // Extract doc string and exceptions
        const excpt_loc = std.mem.indexOf(u8, block, "exceptions: ");
        // Doc up to */ is how much we parse (+3 = */\n)
        parsed = std.mem.indexOf(u8, block, "*/") orelse return error.BadDoc;
        parsed += 3;

        // Make sure next line is not another doc, otherwise skip to it
        if(block[parsed] == '/') {
            return try parse_doc(alloc, block[parsed..], to) + parsed;
        }

        const eloc = if (excpt_loc) |excpt| excpt else parsed;

        // Doc up to exceptions is docstring
        var lines_it = std.mem.splitAny(u8, block[0..eloc], "\n");
        // Upper bound
        to.doc = try alloc.alloc(u8, eloc);
        var actually_written: usize = 0;

        while (lines_it.next()) |line| {
            const trim = std.mem.trimLeft(u8, line, "/ *");
            std.mem.copyForwards(u8, to.doc[actually_written..(actually_written + trim.len)], trim);
            actually_written += trim.len;
            if (trim.len != 0) {
                to.doc[actually_written] = '\n';
                actually_written += 1;
            }
        }

        to.doc = try alloc.realloc(to.doc, actually_written);

        // Exceptions, always a single line
        if (excpt_loc) |excpt| {
            to.exceptions = try alloc.alloc([]u8, 1);

            const excpt_line_end =
                excpt + (std.mem.indexOf(u8, block[excpt..], "\n") orelse return error.BadDoc);
            var spaces_it =
                std.mem.splitAny(u8, block[(excpt + 12)..excpt_line_end], " ,;");

            var first = true;
            while (spaces_it.next()) |token| {
                if (token.len == 0) continue;

                if (!first) {
                    to.exceptions = try alloc.realloc(to.exceptions, to.exceptions.len + 1);
                }
                to.exceptions[to.exceptions.len - 1] = try alloc.alloc(u8, token.len);
                std.mem.copyForwards(u8, to.exceptions[to.exceptions.len - 1], token);
                first = false;
            }
        } else {
            to.exceptions.len = 0;
        }
    }
    else {
        to.doc.len = 0;
        to.exceptions.len = 0;
    }

    return parsed;
}

pub fn sanitize_type(alloc: std.mem.Allocator, typ: []const u8) ![]u8 {
    // Upper bound size
    var out = try alloc.alloc(u8, typ.len);
    var p: usize = 0;

    var tokens = std.mem.splitAny(u8, typ, " ");
    while (tokens.next()) |tok| {
        if (tok.len == 0) {
            continue;
        } else if (std.mem.eql(u8, tok, "INLINE_FUN")) {
            continue;
        }

        const trim_tok = std.mem.trim(u8, tok, " \t,");

        std.mem.copyForwards(u8, out[p..], trim_tok);
        p += trim_tok.len;
        if (tokens.peek() != null) {
            out[p] = ' ';
            p += 1;
        }
    }

    out = try alloc.realloc(out, p);
    return out;
}

pub fn parse_fnc_ret_and_name(alloc: std.mem.Allocator, block: []const u8, to: *ParsedCFunction) !usize {
    const open_par = std.mem.indexOf(u8, block, "(") orelse return 0;
    const last_space = std.mem.lastIndexOf(u8, block[0..open_par], " ") orelse return 0;

    to.rettype = try sanitize_type(alloc, block[0..last_space]);
    to.name = try alloc.alloc(u8, open_par - last_space - 1);

    std.mem.copyForwards(u8, to.name, block[(last_space + 1)..open_par]);

    // +1 because the args start without the parenthesis
    return open_par + 1;
}

pub fn parse_fnc_argument(alloc: std.mem.Allocator, block: []const u8, to: *ParsedCFunction, first: bool) !usize {
    // Very similar strategy to before, but using comma
    // Note that no raw function pointers are used in GSL (they are namespaced)
    // and thus we can simply use commas. Otherwise, we would need to count parentheses
    if (block.len == 0) return 0;
    if (block[0] == ';') return 0;

    const comma = std.mem.indexOf(u8, block, ",");
    const close_par = std.mem.indexOf(u8, block, ")");
    const end =
        if ((comma orelse block.len) > (close_par orelse block.len))
        (close_par orelse return 0)
    else
        (comma orelse return 0);

    const last_space = std.mem.lastIndexOf(u8, block[0..end], " ") orelse return 0;

    if (!first) {
        to.arg_types = try alloc.realloc(to.arg_types, to.arg_types.len + 1);
        to.arg_names = try alloc.realloc(to.arg_names, to.arg_names.len + 1);
    }

    to.arg_types[to.arg_types.len - 1] = try sanitize_type(alloc, block[0..last_space]);
    to.arg_names[to.arg_names.len - 1] = try alloc.alloc(u8, end - last_space - 1);

    std.mem.copyForwards(u8, to.arg_names[to.arg_names.len - 1], block[(last_space + 1)..end]);

    // +1 because the args start without the comma
    return end + 1;
}

// Returns the number of characters parsed as the function
pub fn parse_fnc(alloc: std.mem.Allocator, block: []const u8, to: *ParsedCFunction) !usize {
    if(std.mem.startsWith(u8, block, "typedef")) {
        return 0;
    }
    // First parse the return type and function name
    var p = try parse_fnc_ret_and_name(alloc, block, to);
    // After return type and function name come the arguments, which are done
    // iteratively
    var done = false;
    var first = true;

    // Allocate one arg for now
    to.arg_names = try alloc.alloc([]u8, 1);
    to.arg_types = try alloc.alloc([]u8, 1);

    while (!done) {
        const pnum = try parse_fnc_argument(alloc, block[p..], to, first);
        if (pnum == 0) {
            done = true;
        }
        p += pnum;
        first = false;
    }

    // ;\n
    return if (p != 0) p + 2 else 0;
}

pub fn parse_block(alloc: std.mem.Allocator, block: []const u8) ![]ParsedCFunction {
    var out = try alloc.alloc(ParsedCFunction, 1);

    var p = try parse_doc(alloc, block, &out[0]);
    // Now, parse functions until exhaustion
    // They all inherit the doc string from the first one
    var done = false;
    var first = true;

    while (!done) {
        if (!first) {
            out = try alloc.realloc(out, out.len + 1);
        }
        const pd = try parse_doc(alloc, block[p..], &out[out.len - 1]);
        p += pd;
        if(pd == 0) {
            out[out.len - 1].doc = out[0].doc;
            out[out.len - 1].exceptions = out[0].exceptions;
        }
        const np = try parse_fnc(alloc, block[p..], &out[out.len - 1]);
        if (np == 0 or p == block.len) {
            done = true;
            out = try alloc.realloc(out, out.len - 1);
        }

        p += np;
        first = false;
    }

    return out;
}
