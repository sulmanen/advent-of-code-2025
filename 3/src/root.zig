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
