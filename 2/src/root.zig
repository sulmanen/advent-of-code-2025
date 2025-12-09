const std = @import("std");

const c = @cImport(@cInclude("regex.h"));

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
    var invalidIds = std.ArrayList(usize).initCapacity(std.heap.page_allocator, 100);
    defer invalidIds.deinit();

    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var file_buffer: [4096]u8 = undefined;
    var reader = file.reader(&file_buffer);
    var line_no: usize = 0;

    while (try reader.interface.takeDelimiter(',')) |line| {
        line_no += 1;

        var iter = std.mem.splitSequence(u8, line, ",");

        while (iter.next()) |part| {
            var partIter = std.mem.splitSequence(u8, part, "-");
            const left = partIter.next().?;
            const right = partIter.next().?;

            std.debug.print("Left: {s}, Right: {s}\n", .{ left, right });
        }
    }
}

pub fn findInvalidIDBetween(left: usize, right: usize, invalidIds: *std.ArrayList(usize), allocator: std.mem.Allocator) !void {
    for (left..right) |id| {
        const id_str = std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{id}) catch unreachable;
        defer std.heap.page_allocator.free(id_str);
        const id_str_z = try allocator.dupeZ(u8, id_str);
        defer allocator.free(id_str_z);

        if (numberRepeatsBackToBack(id_str_z)) {
            std.debug.print("Invalid ID: {d}\n", .{id});
            try invalidIds.append(allocator, id);
        }
    }
}

pub fn numberRepeatsBackToBack(number: [*c]const u8) bool {
    var regex: c.regex_t = undefined;

    const pattern: [*c]const u8 = "^([[:digit:]]+)\\1";
    const compileSuccess = c.regcomp(&regex, pattern, c.REG_EXTENDED);

    if (compileSuccess != 0) {
        std.debug.print("Failed to compile Regular Expression\n", .{});
        return false;
    }
    defer c.regfree(&regex);
    var matches: [5]c.regmatch_t = undefined;
    const result = c.regexec(&regex, number, matches.len, &matches, 0);

    if (result == 0) {
        std.debug.print("Match found!\n", .{});
        for (matches, 0..) |m, i| {
            const start_offset = m.rm_so;
            if (start_offset == -1) break;

            const end_offset = m.rm_eo;

            const match = number[@intCast(start_offset)..@intCast(end_offset)];
            std.debug.print("matches[{d}] = {s}\n", .{ i, match });
        }
        return true;
    } else if (result == c.REG_NOMATCH) {
        std.debug.print("No match found\n", .{});
    } else {
        std.debug.print("Regex execution error\n", .{});
    }
    return false;
}

test "number does not repeat" {
    try std.testing.expect(numberRepeatsBackToBack("12") == false);
}

test "small number repeats" {
    try std.testing.expect(numberRepeatsBackToBack("11") == true);
}

test "number repeats" {
    try std.testing.expect(numberRepeatsBackToBack("22") == true);
}

test "number repeats simply" {
    const number: [:0]const u8 = "1212";
    try std.testing.expect(numberRepeatsBackToBack(number) == true);
}

test "bigger number repeats" {
    const number: [:0]const u8 = "1188511885";
    try std.testing.expect(numberRepeatsBackToBack(number) == true);
}

test "find invalid ID between" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var list = try std.ArrayList(usize).initCapacity(gpa.allocator(), 100);
    defer list.deinit(gpa.allocator());
    try findInvalidIDBetween(11, 22, &list, gpa.allocator());
    try std.testing.expect(list.items.len == 2);
    try std.testing.expect(list.items[0] == 11);
    try std.testing.expect(list.items[1] == 21);
}
