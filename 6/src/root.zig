//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

pub fn solveOne(input: []const u8) !u128 {
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
    return total;
}

pub fn addCephalopod(numbers: *[][]const u8) !u128 {
    var cephalopod_numbers: std.ArrayList(u32) = try std.ArrayList(u32).initCapacity(std.heap.page_allocator, 50);
    defer cephalopod_numbers.deinit(std.heap.page_allocator);

    var padded_numbers: std.ArrayList([]const u8) = try std.ArrayList([]const u8).initCapacity(std.heap.page_allocator, 50);
    defer padded_numbers.deinit(std.heap.page_allocator);

    var max_length: usize = 0;
    var j: usize = 0;
    while (j < numbers.len) : (j += 1) {
        max_length = @max(max_length, numbers.*[j].len);
    }
    for (0..numbers.len) |i| {
        const number = numbers.*[i];
        const padded_num = try std.fmt.allocPrint(std.heap.page_allocator, "{s:0>[1]}", .{ number, max_length });
        std.debug.print("Padded number: {s}\n", .{padded_num});
        defer std.heap.page_allocator.free(padded_num);
        try padded_numbers.append(std.heap.page_allocator, padded_num);
    }

    var max_length_index = max_length - 1;
    while (max_length_index >= 0) : (max_length_index -= 1) {
        var number_characters: std.ArrayList(u8) = try std.ArrayList(u8).initCapacity(std.heap.page_allocator, 50);
        defer number_characters.deinit(std.heap.page_allocator);

        var i: usize = 0;
        while (i < padded_numbers.items.len) : (i += 1) {
            const padded_number = padded_numbers.items[i];
            const character = padded_number[max_length_index];
            try number_characters.append(std.heap.page_allocator, character);
        }
        std.debug.print("{s}\n", .{number_characters.items});
    }
    return 0;
}

pub fn multiplyCephalopod(numbers: *[][]const u8) !u128 {
    var cephalopod_numbers: std.ArrayList(u32) = try std.ArrayList(u32).initCapacity(std.heap.page_allocator, 50);
    defer cephalopod_numbers.deinit(std.heap.page_allocator);

    var max_length: usize = 0;
    for (numbers.*) |number| {
        max_length = @max(max_length, number.len);
    }
    for (0..numbers.len) |i| {
        const number = numbers.*[i];
        const padded_num = try std.fmt.allocPrint(std.heap.page_allocator, "{s:0>[1]}", .{ number, max_length });
        defer std.heap.page_allocator.free(padded_num);
    }
    return 0;
}

pub fn solveTwo(input: []const u8) !u128 {
    const file = try std.fs.cwd().openFile(input, .{});
    defer file.close();
    var file_buffer: [4096]u8 = undefined;
    var reader = file.reader(&file_buffer);

    var operators: std.ArrayList([]const u8) = try std.ArrayList([]const u8).initCapacity(std.heap.page_allocator, 50);
    defer operators.deinit(std.heap.page_allocator);

    var operands = try std.ArrayList([]const u8).initCapacity(std.heap.page_allocator, 50);
    defer operands.deinit(std.heap.page_allocator);
    var width: usize = 0;
    while (try reader.interface.takeDelimiter('\n')) |line| {
        if (std.mem.startsWith(u8, line, "*") or std.mem.startsWith(u8, line, "+")) {
            var iter = std.mem.tokenizeAny(u8, line, " \t\n\r");
            while (iter.next()) |operator| : (width += 1) {
                try operators.append(std.heap.page_allocator, operator);
            }
        } else {
            var iter = std.mem.splitScalar(u8, line, ' ');
            while (iter.next()) |operand| {
                std.debug.print(".{s}.\n", .{operand});
                try operands.append(std.heap.page_allocator, operand);
            }
        }
    }
    var total: u128 = 0;
    const row_count: usize = operands.items.len / width;
    for (operators.items, 0..) |operator, i| {
        if (std.mem.eql(u8, operator, "+")) {
            var numbers = try std.heap.page_allocator.alloc([]const u8, row_count);
            defer std.heap.page_allocator.free(numbers);
            for (0..row_count) |j| {
                numbers[j] = operands.items[j * width + i];
            }
            total += try addCephalopod(&numbers);
        }
        if (std.mem.eql(u8, operator, "*")) {
            var numbers = try std.heap.page_allocator.alloc([]const u8, row_count);
            defer std.heap.page_allocator.free(numbers);
            for (0..row_count) |j| {
                numbers[j] = operands.items[j * width + i];
            }
            total += try multiplyCephalopod(&numbers);
        }
    }
    return total;
}
