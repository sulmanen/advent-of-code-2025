const std = @import("std");
const _6 = @import("_6");

pub fn main() !void {
    //const one: u128 = try _6.solveOne("input.txt");
    //std.debug.print("First Total: {d}\n", .{one});

    const two: u128 = try _6.solveTwo("test-input.txt");
    std.debug.print("Second Total: {d}\n", .{two});
}
