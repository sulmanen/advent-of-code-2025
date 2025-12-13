//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
const JOLTAGE_DIGITS = 12;

pub fn bufferedPrint() !void {
    // Stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try stdout.flush(); // Don't forget to flush!
}

pub fn readInput(filename: []const u8) !void {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var file_buffer: [4096]u8 = undefined;
    var reader = file.reader(&file_buffer);
    var line_no: usize = 0;
    var total_output_joltage: i64 = 0;

    while (try reader.interface.takeDelimiter('\n')) |line| {
        line_no += 1;

        const right_trimmed = std.mem.trimRight(u8, line, " \t\n\r");
        var biggest: i64 = 0;
        var biggest_index: usize = 0;
        var first_i: usize = 0;

        while (first_i < right_trimmed.len - 1) : (first_i += 1) {
            const num: i64 = right_trimmed[first_i] - '0';
            if (num > biggest) {
                biggest = num;
                biggest_index = first_i;
            }
        }

        std.debug.print("Biggest: {d}\n", .{biggest});
        var next_biggest: i64 = 0;
        var next_biggest_index: usize = 0;
        for (right_trimmed[biggest_index + 1 ..], 0..) |number, i| {
            const num: i64 = number - '0';
            if (num > next_biggest) {
                next_biggest = num;
                next_biggest_index = i;
            }
        }

        std.debug.print("Biggest: {d}\n", .{biggest});
        std.debug.print("Next Biggest: {d} at {d}\n", .{ next_biggest, next_biggest_index });

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        const allocator = gpa.allocator();

        const joltage_str = try std.fmt.allocPrint(allocator, "{d}{d}", .{ biggest, next_biggest });
        std.debug.print("Joltage: {s}\n", .{joltage_str});
        defer allocator.free(joltage_str);
        const joltage = try std.fmt.parseInt(i64, joltage_str, 10);
        total_output_joltage += joltage;
    }

    std.debug.print("Total output joltage: {d}\n", .{total_output_joltage});
}

pub fn readInputTwo(filename: []const u8) !void {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var file_buffer: [4096]u8 = undefined;
    var reader = file.reader(&file_buffer);
    var line_no: usize = 0;
    var total_output_joltage: u512 = 0;

    while (try reader.interface.takeDelimiter('\n')) |line| {
        line_no += 1;

        const right_trimmed = std.mem.trimRight(u8, line, " \t\n\r");

        const joltage = try findJoltage(right_trimmed);
        total_output_joltage += joltage;
    }

    std.debug.print("Total output joltage: {d}\n", .{total_output_joltage});
}
const NumberAndIndex = struct {
    number: i64,
    index: usize,
};

fn byNumber(context: void, a: NumberAndIndex, b: NumberAndIndex) bool {
    _ = context;
    if (a.number == b.number) {
        return a.index > b.index;
    }

    return a.number > b.number;
}

fn byIndex(context: void, a: NumberAndIndex, b: NumberAndIndex) bool {
    _ = context;
    return a.index < b.index;
}

pub fn removeNumberAtIndex(number_string: []const u8, index: usize, to_remove: usize) !u512 {
    const start = number_string[0..index];
    var end: []const u8 = "";
    if (index + 1 < number_string.len - to_remove) {
        end = number_string[index + 1 .. number_string.len - to_remove];
    }
    const new_number_string = try std.mem.concat(std.heap.page_allocator, u8, &.{ start, end });
    return try std.fmt.parseInt(u512, new_number_string, 10);
}

pub fn removeFromEnd(number_string: []const u8, to_remove: usize) !u512 {
    const start = number_string[0 .. number_string.len - to_remove];
    return try std.fmt.parseInt(u512, start, 10);
}

pub fn findStartIndex(number_string: []const u8) usize {
    var to_remove: usize = number_string.len - JOLTAGE_DIGITS;
    var index: usize = 0;
    var largest_digit: u512 = 0;
    var largest_index: usize = 0;
    while (to_remove > 0 and index < number_string.len) : (index += 1) {
        const new_number = number_string[index] - '0';
        if (new_number > largest_digit) {
            largest_digit = new_number;
            largest_index = index;
        }
        to_remove -= 1;
    }
    std.debug.print("Largest digit: {d}, Index: {d}\n", .{ largest_digit, largest_index });
    return largest_index;
}

pub fn findJoltage(number_string: []const u8) !u512 {
    var removeIndeces = try std.ArrayList(usize).initCapacity(std.heap.page_allocator, 100);
    defer removeIndeces.deinit(std.heap.page_allocator);
    const trimmed_number_string = std.mem.trimRight(u8, number_string, " \t\n\r");
    const max_index = findStartIndex(number_string);
    var i: usize = 0;
    var to_remove = trimmed_number_string[max_index..].len - JOLTAGE_DIGITS;
    var removed: usize = 0;
    const string_with_max_start = trimmed_number_string[max_index..];
    var current_number_string = string_with_max_start;
    while (to_remove > 0 and i < string_with_max_start.len) : (i += 1) {
        const newNumber = try removeNumberAtIndex(current_number_string, i - removed, to_remove - 1);
        const compareNumber = try removeFromEnd(current_number_string, to_remove);
        std.debug.print("{d} > {d} = {}\n", .{ newNumber, compareNumber, newNumber > compareNumber });
        if (newNumber >= compareNumber) {
            current_number_string = try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{try removeNumberAtIndex(current_number_string, i - removed, 0)});
            to_remove -= 1;
            removed += 1;
            try removeIndeces.append(std.heap.page_allocator, i);
        }
        std.debug.print("{s}\n", .{current_number_string});
    }
    if (to_remove != 0) {
        current_number_string = try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{try removeFromEnd(current_number_string, to_remove)});
    }
    const joltage: u512 = try std.fmt.parseInt(u512, current_number_string, 10);
    return joltage;
}

test "find joltage 234234234234278" {
    const input = "234234234234278";
    const expected = 434234234278;
    const actual = try findJoltage(input);
    try std.testing.expectEqual(expected, actual);
}

test "find joltage 987654321111111" {
    const input = "987654321111111";
    const expected = 987654321111;
    const actual = try findJoltage(input);
    try std.testing.expectEqual(expected, actual);
}

test "find joltage 811111111111119" {
    const input = "811111111111119";
    const expected = 811111111119;
    const actual = try findJoltage(input);
    try std.testing.expectEqual(expected, actual);
}

test "find joltage 818181911112111" {
    const input = "818181911112111";
    const expected = 888911112111;
    const actual = try findJoltage(input);
    try std.testing.expectEqual(expected, actual);
}

test "find joltage 2223223335223234342422322225224113422423142441542233322124236224232234222242262232142124444266221211" {
    const input = "2223223335223234342422322225224113422423142441542233322124236224232234222242262232142124444266221211";
    const expected = 643446324244;
    const actual = try findJoltage(input);
    try std.testing.expectEqual(expected, actual);
}
