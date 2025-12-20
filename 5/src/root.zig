//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

const FreshRange = struct {
    start: u128,
    end: u128,
};
fn hasOverlapping(ranges: *std.ArrayList(FreshRange)) bool {
    for (ranges.items) |first| {
        for (ranges.items) |second| {
            if (howManyOverlapping(first, second) != 0 and first.start != second.start and first.end != second.end) {
                return true;
            }
        }
    }
    return false;
}

fn exists(ranges: *std.ArrayList(FreshRange), range: FreshRange) bool {
    for (ranges.items) |existingRange| {
        if (range.start == existingRange.start and range.end == existingRange.end) {
            return true;
        }
    }
    return false;
}

fn addIfNotExists(ranges: *std.ArrayList(FreshRange), range: FreshRange) !void {
    if (!exists(ranges, range)) {
        try ranges.append(std.heap.page_allocator, range);
    }
}

fn compareByFreshRange(context: void, a: FreshRange, b: FreshRange) bool {
    _ = context;
    return a.start < b.start;
}

fn rangesAreEqual(a: FreshRange, b: FreshRange) bool {
    return a.start == b.start and a.end == b.end;
}

fn findAndRemove(ranges: *std.ArrayList(FreshRange), range_to_remove: FreshRange) !void {
    for (ranges.items, 0..) |range, i| {
        if (rangesAreEqual(range, range_to_remove)) {
            _ = ranges.swapRemove(i);
            return;
        }
    }
}

pub fn flattenRanges(range_to_check: FreshRange, ranges: *std.ArrayList(FreshRange)) !u128 {
    var overlappingRanges = try std.ArrayList(FreshRange).initCapacity(std.heap.page_allocator, 100);
    defer overlappingRanges.deinit(std.heap.page_allocator);

    var overlapping: u128 = 0;
    for (ranges.items) |range| {
        overlapping = howManyOverlapping(range_to_check, range);
        if (overlapping != 0) {
            try overlappingRanges.append(std.heap.page_allocator, range);
        }
    }

    for (overlappingRanges.items) |range| {
        try findAndRemove(ranges, range);
    }

    if (overlappingRanges.items.len == 0 and !hasOverlapping(ranges)) {
        var unique_ids: u128 = 0;
        try ranges.append(std.heap.page_allocator, range_to_check);
        std.mem.sort(FreshRange, ranges.items, {}, compareByFreshRange);

        var finalRanges = try std.ArrayList(FreshRange).initCapacity(std.heap.page_allocator, 100);
        defer finalRanges.deinit(std.heap.page_allocator);

        for (ranges.items) |range| {
            try addIfNotExists(&finalRanges, range);
        }

        for (finalRanges.items) |range| {
            std.debug.print("{d}-{d}\n", .{ range.start, range.end });
            unique_ids += range.end - range.start + 1;
        }
        return unique_ids;
    } else {
        var newRange: FreshRange = range_to_check;
        for (overlappingRanges.items) |overlapping_range| {
            std.debug.print("overlap:{d}-{d}\n", .{ overlapping_range.start, overlapping_range.end });
            newRange.start = @min(newRange.start, overlapping_range.start);
            newRange.end = @max(newRange.end, overlapping_range.end);
        }
        try ranges.append(std.heap.page_allocator, newRange);
        return try flattenRanges(ranges.orderedRemove(0), ranges);
    }
    try ranges.append(std.heap.page_allocator, range_to_check);
    return try flattenRanges(ranges.orderedRemove(0), ranges);
}

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
    std.mem.sort(FreshRange, freshRanges.items, {}, compareByFreshRange);
    const unique_fresh_ids: u128 = try flattenRanges(freshRanges.pop().?, &freshRanges);

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
test "real case" {
    const range: FreshRange = .{ .start = 2020409498512, .end = 2020409498512 };
    const result = howManyOverlapping(range, .{ .start = 2020409498513, .end = 6492182236039 });
    try std.testing.expect(result == 4471772737528);
}
