//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

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

pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

pub fn readInput(filename: []const u8) !void {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var file_buffer: [4096]u8 = undefined;
    var reader = file.reader(&file_buffer);
    var line_no: usize = 0;
    var password: i32 = 0;
    var currentValue: i32 = 50;

    while (try reader.interface.takeDelimiter('\n')) |line| {
        line_no += 1;
        std.mem.replaceScalar(u8, line, 'L', '-');
        std.mem.replaceScalar(u8, line, 'R', ' ');

        const left_trimmed = std.mem.trimLeft(u8, line, " \t\n\r");

        const by = try std.fmt.parseInt(i32, left_trimmed, 10);
        const rotation = rotate(currentValue, by);
        currentValue = rotation.remainder;
        password = password + rotation.quotient;

        std.debug.print("{d}--{d}\n", .{ currentValue, by });
    }

    std.debug.print("Password: {d}\n", .{password});
}

pub fn rotate(value: i32, by: i32) struct { quotient: i32, remainder: i32 } {
    var result = value + by;
    var crossed_zero: i32 = 0;

    if ((result < 0) or result == 0) {
        crossed_zero = crossed_zero + 1;
    }

    var position: i32 = 0;

    if (result < 0) {
        position = (100 - @mod(result, 100));
    } else if (result > 0) {
        position = @mod(result, 100);
    }

    if (result < 0) {
        result = result * -1;
    }

    return .{ .quotient = @divTrunc(result, 100) + crossed_zero, .remainder = position };
}

test "basic add functionality" {
    try std.testing.expect(add(3, 7) == 10);
}

test "rotate past zero" {
    const result = rotate(50, -51);
    try std.testing.expect(result.quotient == 1);
    try std.testing.expect(result.remainder == 99);
}

test "rotate past 99" {
    const result = rotate(50, 50);
    try std.testing.expect(result.quotient == 1);
    try std.testing.expect(result.remainder == 0);
}
