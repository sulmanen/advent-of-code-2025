//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

pub fn solveOne(input: []const u8) !void {
    const file = try std.fs.cwd().openFile(input, .{});
    defer file.close();

    var file_buffer: [4096]u8 = undefined;
    var reader = file.reader(&file_buffer);
    while (try reader.interface.takeDelimiter('\n')) |line| {
        const right_trimmed = std.mem.trimRight(u8, line, " \t\n\r");

        if (std.mem.startsWith(u8, right_trimmed, "*") or std.mem.startsWith(u8, right_trimmed, "+")) {
            std.debug.print("Operator line: '{s}'\n", .{right_trimmed});
        }

        var iter = std.mem.tokenizeAny(u8, right_trimmed, " \t\n\r");
        while (iter.next()) |token| {
            std.debug.print("Token: '{s}'\n", .{token});
        }
        std.debug.print("End of line\n", .{});
    }
}
