const std = @import("std");
const _1 = @import("_1");

pub fn main() !void {
    // Prints to stderr, ignoring potential errors.
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
    try _1.readInput("input.txt");
}
