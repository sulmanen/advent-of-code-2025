//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

const FreshRange = struct {
    start: u128,
    end: u128,
};

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
