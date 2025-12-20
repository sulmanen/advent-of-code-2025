//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

pub fn solveOne(input: []const u8) !void {
    const file = try std.fs.cwd().openFile(input, .{});
    defer file.close();
    var file_buffer: [4096]u8 = undefined;
    var reader = file.reader(&file_buffer);

    var operators: std.ArrayList([]const u8) = try std.ArrayList([]const u8).initCapacity(std.heap.page_allocator, 50);
    defer operators.deinit(std.heap.page_allocator);

    var operands = try std.ArrayList(u128).initCapacity(std.heap.page_allocator, 50);
    defer operands.deinit(std.heap.page_allocator);
    var width: usize = 0;
    while (try reader.interface.takeDelimiter('\n')) |line| {
        const right_trimmed = std.mem.trimRight(u8, line, " \t\n\r");

        if (std.mem.startsWith(u8, right_trimmed, "*") or std.mem.startsWith(u8, right_trimmed, "+")) {
            var iter = std.mem.tokenizeAny(u8, right_trimmed, " \t\n\r");
            while (iter.next()) |operator| : (width += 1) {
                try operators.append(std.heap.page_allocator, operator);
            }
            std.debug.print("Operator line: '{s}'\n", .{right_trimmed});
        } else {
            var iter = std.mem.tokenizeAny(u8, right_trimmed, " \t\n\r");
            while (iter.next()) |operand| {
                try operands.append(std.heap.page_allocator, try std.fmt.parseInt(u128, operand, 10));
            }
        }
    }
    var total: u128 = 0;
    const row_count = operands.items.len / width;
    for (operators.items, 0..) |operator, i| {
        if (std.mem.eql(u8, operator, "+")) {
            var line_total: u128 = 0;
            for (0..row_count) |j| {
                std.debug.print("Operand: {d}\n", .{operands.items[j * width + i]});
                line_total += operands.items[j * width + i];
            }
            total += line_total;
        }
        if (std.mem.eql(u8, operator, "*")) {
            var line_total: u128 = 1;
            for (0..row_count) |j| {
                line_total *= operands.items[j * width + i];
            }
            total += line_total;
        }
    }
    std.debug.print("Total: {d}\n", .{total});
}
