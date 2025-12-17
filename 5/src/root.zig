//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

const FreshRange = struct {
    start: u128,
    end: u128,
};
pub fn solveTwo(filename: []const u8) !void {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var file_buffer: [4096]u8 = undefined;
    var reader = file.reader(&file_buffer);

    var freshRanges = try std.ArrayList(FreshRange).initCapacity(std.heap.page_allocator, 100);
    defer freshRanges.deinit(std.heap.page_allocator);

    while (try reader.interface.takeDelimiter('\n')) |line| {
        const right_trimmed = std.mem.trimRight(u8, line, " \t\n\r");
        if (right_trimmed.len == 0) break;

        var freshRangeIterator = std.mem.splitSequence(u8, right_trimmed, "-");
        const min = freshRangeIterator.next().?;
        const max = freshRangeIterator.next().?;
        const freshRange = FreshRange{ .start = try std.fmt.parseInt(u128, min, 10), .end = try std.fmt.parseInt(u128, max, 10) };
        try freshRanges.append(std.heap.page_allocator, freshRange);
    }

    var all_fresh_ids: u128 = 0;
    for (freshRanges.items) |freshRange| {
        std.debug.print("Fresh Range: {}-{}\n", .{ freshRange.start, freshRange.end });
        all_fresh_ids += freshRange.end - freshRange.start + 1;
    }

    std.debug.print("All Fresh Ranges length: {}\n", .{freshRanges.items.len});
    var overlapping_fresh_ids: u128 = 0;
    for (freshRanges.items, 0..) |freshRange, i| {
        for (freshRanges.items, 0..) |otherFreshRange, j| {
            if (i != j) {
                overlapping_fresh_ids += howManyOverlapping(freshRange, otherFreshRange);
            }
        }
    }
    std.debug.print("Overlapping Fresh IDs Total: {}\n", .{overlapping_fresh_ids});
    const unique_fresh_ids = all_fresh_ids - overlapping_fresh_ids / 2;
    std.debug.print("Unique Fresh IDs Total: {}\n", .{unique_fresh_ids});
}

pub fn howManyOverlapping(first: FreshRange, second: FreshRange) u128 {
    if (first.start > second.end or first.end < second.start) {
        return 0;
    }
    if (first.start <= second.start and first.end >= second.end) {
        std.debug.print("Overlapping range: {}-{} and {}-{}\n", .{ first.start, first.end, second.start, second.end });
        return second.end - second.start + 1;
    }
    if (first.start <= second.start and first.end <= second.end) {
        std.debug.print("Overlapping range: {}-{} and {}-{}\n", .{ first.start, first.end, second.start, second.end });
        return first.end - second.start + 1;
    }
    if (first.start >= second.start and first.end >= second.end) {
        std.debug.print("Overlapping range: {}-{} and {}-{}\n", .{ first.start, first.end, second.start, second.end });
        return second.end - first.start + 1;
    }
    if (first.start >= second.start and first.end <= second.end) {
        std.debug.print("Overlapping range: {}-{} and {}-{}\n", .{ first.start, first.end, second.start, second.end });
        return first.end - first.start + 1;
    }
    return 0;
}

pub fn solveOne(filename: []const u8) !void {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var file_buffer: [4096]u8 = undefined;
    var reader = file.reader(&file_buffer);

    var freshRanges = try std.ArrayList(FreshRange).initCapacity(std.heap.page_allocator, 100);
    defer freshRanges.deinit(std.heap.page_allocator);

    var ingredientIds = try std.ArrayList(u128).initCapacity(std.heap.page_allocator, 100);
    defer ingredientIds.deinit(std.heap.page_allocator);

    while (try reader.interface.takeDelimiter('\n')) |line| {
        const right_trimmed = std.mem.trimRight(u8, line, " \t\n\r");
        if (right_trimmed.len == 0) break;

        var freshRangeIterator = std.mem.splitSequence(u8, right_trimmed, "-");
        const min = freshRangeIterator.next().?;
        const max = freshRangeIterator.next().?;
        const freshRange = FreshRange{ .start = try std.fmt.parseInt(u128, min, 10), .end = try std.fmt.parseInt(u128, max, 10) };
        try freshRanges.append(std.heap.page_allocator, freshRange);
    }

    while (try reader.interface.takeDelimiter('\n')) |line| {
        const right_trimmed = std.mem.trimRight(u8, line, " \t\n\r");
        const ingredientId = try std.fmt.parseInt(u128, right_trimmed, 10);
        try ingredientIds.append(std.heap.page_allocator, ingredientId);
    }

    var freshCount: u32 = 0;
    for (ingredientIds.items) |ingredientId| {
        for (freshRanges.items) |freshRange| {
            if (ingredientId >= freshRange.start and ingredientId <= freshRange.end) {
                freshCount += 1;
                std.debug.print("Ingredient ID: {}, Fresh Range: {}-{}\n", .{ ingredientId, freshRange.start, freshRange.end });
                break;
            }
        }
    }
    std.debug.print("Fresh count: {}\n", .{freshCount});
}

test "Find overlap where second range is within the first" {
    const range: FreshRange = .{ .start = 5, .end = 12 };
    const result = howManyOverlapping(range, .{ .start = 6, .end = 11 });
    try std.testing.expect(result == 6);
}

test "Find overlap where second range is within the first but flipped" {
    const range: FreshRange = .{ .start = 6, .end = 11 };
    const result = howManyOverlapping(range, .{ .start = 5, .end = 12 });
    try std.testing.expect(result == 6);
}

test "Find overlap where second range overlaps from start" {
    const range: FreshRange = .{ .start = 5, .end = 12 };
    const result = howManyOverlapping(range, .{ .start = 7, .end = 13 });
    try std.testing.expect(result == 6);
}

test "Find overlap where second range overlaps from start flipped" {
    const range: FreshRange = .{ .start = 7, .end = 13 };
    const result = howManyOverlapping(range, .{ .start = 5, .end = 12 });
    try std.testing.expect(result == 6);
}

test "Find overlap where second range overlaps from end" {
    const range: FreshRange = .{ .start = 5, .end = 12 };
    const result = howManyOverlapping(range, .{ .start = 1, .end = 6 });
    try std.testing.expect(result == 2);
}
test "Find overlap where second range overlaps from end flipped" {
    const range: FreshRange = .{ .start = 1, .end = 6 };
    const result = howManyOverlapping(range, .{ .start = 5, .end = 12 });
    try std.testing.expect(result == 2);
}

test "Find overlap where second range overlaps from both ends" {
    const range: FreshRange = .{ .start = 5, .end = 12 };
    const result = howManyOverlapping(range, .{ .start = 3, .end = 15 });
    try std.testing.expect(result == 8);
}

test "Find overlap where second range overlaps from both ends flipped" {
    const range: FreshRange = .{ .start = 3, .end = 15 };
    const result = howManyOverlapping(range, .{ .start = 5, .end = 12 });
    try std.testing.expect(result == 8);
}

test "Find one number overlapping" {
    const range: FreshRange = .{ .start = 5, .end = 12 };
    const result = howManyOverlapping(range, .{ .start = 12, .end = 13 });
    try std.testing.expect(result == 1);
}
test "Find one number overlapping flipped" {
    const range: FreshRange = .{ .start = 12, .end = 13 };
    const result = howManyOverlapping(range, .{ .start = 5, .end = 12 });
    try std.testing.expect(result == 1);
}

test "Find one number overlapping at start" {
    const range: FreshRange = .{ .start = 5, .end = 12 };
    const result = howManyOverlapping(range, .{ .start = 4, .end = 5 });
    try std.testing.expect(result == 1);
}

test "Find exact overlap" {
    const range: FreshRange = .{ .start = 5, .end = 12 };
    const result = howManyOverlapping(range, .{ .start = 5, .end = 12 });
    try std.testing.expect(result == 8);
}

test "No overlap" {
    const range: FreshRange = .{ .start = 3, .end = 5 };
    const result = howManyOverlapping(range, .{ .start = 10, .end = 14 });
    try std.testing.expect(result == 0);
}
test "No overlap other end" {
    const range: FreshRange = .{ .start = 3, .end = 5 };
    const result = howManyOverlapping(range, .{ .start = 1, .end = 2 });
    try std.testing.expect(result == 0);
}
test "No overlap flipped" {
    const range: FreshRange = .{ .start = 10, .end = 14 };
    const result = howManyOverlapping(range, .{ .start = 3, .end = 5 });
    try std.testing.expect(result == 0);
}

test "Overlap" {
    const range: FreshRange = .{ .start = 72610827321812, .end = 74139327712477 };
    const result = howManyOverlapping(range, .{ .start = 73828954111068, .end = 75232756067163 });
    try std.testing.expect(result == 310373601410);
}
