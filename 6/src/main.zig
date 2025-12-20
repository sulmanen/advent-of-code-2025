const std = @import("std");
const _6 = @import("_6");

pub fn main() !void {
    const one: u128 = try _6.solveOne("input.txt");
    std.debug.print("First Total: {d}\n", .{one});
}
