const std = @import("std");
const parseInt = std.fmt.parseInt;
const safe = @import("safe");

test "rotate" {
    const expected = 99;
    const value = 50;
    const by = -51;

    const actual = safe.rotate(value, by);
    try std.testing.expectEqual(expected, actual);
}
