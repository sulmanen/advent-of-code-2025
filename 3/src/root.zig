//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
const JOLTAGE_DIGITS = 12;

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

pub fn findMax(number_string: []const u8, current_index: usize, numbers: *[12]u8, completed: usize, remove_window: usize) void {
    std.debug.print("current index: {d}, completed: {d}, remove_window: {d}\n", .{ current_index, completed, remove_window });
    if (completed == JOLTAGE_DIGITS) {
        return;
    }

    var largest_digit = number_string[current_index] - '0';
    var largest_digit_index = current_index;
    var i = current_index;
    while (i <= current_index + remove_window) : (i += 1) {
        const current_digit = number_string[i] - '0';
        if (current_digit > largest_digit) {
            largest_digit = current_digit;
            largest_digit_index = i;
        }
    }
    numbers[completed] = @intCast(largest_digit + '0');
    std.debug.print("largest_digit: {d}, rwindow: {d} \n", .{ largest_digit, remove_window - (largest_digit_index - current_index) });
    return findMax(number_string, largest_digit_index + 1, numbers, completed + 1, remove_window - (largest_digit_index - current_index));
}

pub fn findJoltage(number_string: []const u8) !u512 {
    std.debug.print("\n", .{});
    var numbers = [_]u8{'0'} ** 12;
    const trimmed_number_string = std.mem.trimRight(u8, number_string, " \t\n\r");
    findMax(trimmed_number_string, 0, &numbers, 0, trimmed_number_string.len - JOLTAGE_DIGITS);
    std.debug.print("Max Joltage: {s}\n", .{numbers});
    const joltage: u512 = try std.fmt.parseInt(u512, &numbers, 10);
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
    const expected = 664466221211;
    const actual = try findJoltage(input);
    try std.testing.expectEqual(expected, actual);
}
