const std = @import("std");
const fatal = @import("utils.zig").fatal;

pub fn isGsl(haystack: []const u8) bool {
    return std.mem.startsWith(u8, haystack, "gsl") and
        std.mem.endsWith(u8, haystack, ".h");
}

// Recursively (TODO: Danger!) links all gsl files to the gsl directory
// TODO: We actually copy the files, this is because otherwise we can't later
// on use zig's features to include those as a build artefact!
// (This results in slight waste of hard drive space)
pub fn linkAllGslFiles(alloc: std.mem.Allocator, b: std.fs.Dir, target: std.fs.Dir) !void {
    var iter = b.iterate();
    while (try iter.next()) |entry| {
        if (entry.kind == .file and isGsl(entry.name)) {
            //const tgt = try b.realpathAlloc(alloc, entry.name);
            //defer alloc.free(tgt);
            //try target.symLink(tgt, entry.name,
            //    .{ .is_directory = false });
            try b.copyFile(
                entry.name,
                target,
                entry.name,
                .{},
            );
        } else if (entry.kind == .directory) {
            // Recurse
            const ndir = try b.openDir(entry.name, .{
                .iterate = true,
                .no_follow = true,
            });
            try linkAllGslFiles(alloc, ndir, target);
        }
    }
}

pub fn main() !void {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const args = try std.process.argsAlloc(arena);
    if (args.len != 3) fatal("specify gsl dir, and output gsl folder holder name", .{});

    const gsl_path = args[1];
    const output_dir_path = args[2];

    // Create gsl directory within output dir
    var holder_dir = try std.fs.openDirAbsolute(output_dir_path, .{});
    defer holder_dir.close();
    var tgt_dir = try holder_dir.makeOpenPath("gsl", .{
        .iterate = false,
        .no_follow = true,
    });
    defer tgt_dir.close();

    // Now, we must symlink all /gsl*.h and /*/gsl*.h files into gsl/ directory,
    // which is done by default by an autoconfig makefile, we do so recursively
    var gsl_iter = try std.fs.openDirAbsolute(gsl_path, .{
        .iterate = true,
        .no_follow = true,
    });
    defer gsl_iter.close();

    try linkAllGslFiles(arena, gsl_iter, tgt_dir);

    return std.process.cleanExit();
}
