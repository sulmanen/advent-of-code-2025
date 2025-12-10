const std = @import("std");
const c = @cImport({
    @cDefine("PCRE2_CODE_UNIT_WIDTH", "8");
    @cInclude("pcre2.h");
});

extern fn pcre2_compile_8(
    pattern: [*c]const u8,
    length: usize,
    options: u32,
    errorcode: *c_int,
    erroroffset: *usize,
    ccontext: ?*anyopaque,
) ?*anyopaque;

extern fn pcre2_match_8(
    code: ?*const anyopaque,
    subject: [*c]const u8,
    length: usize,
    startoffset: usize,
    options: u32,
    match_data: ?*anyopaque,
    mcontext: ?*anyopaque,
) c_int;

extern fn pcre2_match_data_create_from_pattern_8(
    code: ?*const anyopaque,
    gcontext: ?*anyopaque,
) ?*anyopaque;

extern fn pcre2_match_data_free_8(match_data: ?*anyopaque) void;
extern fn pcre2_code_free_8(code: ?*anyopaque) void;

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
    var invalidIds = try std.ArrayList(usize).initCapacity(std.heap.page_allocator, 100);
    defer invalidIds.deinit(std.heap.page_allocator);
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
            std.debug.print("left {s}, right {s}\n", .{ left, right });
            const left_trimmed = std.mem.trimRight(u8, left, " \t\n\r");
            const right_trimmed = std.mem.trimRight(u8, right, " \t\n\r");

            const left_int = try std.fmt.parseInt(usize, left_trimmed, 10);
            const right_int = try std.fmt.parseInt(usize, right_trimmed, 10);
            std.debug.print("left {d}, right {d}\n", .{ left_int, right_int });
            try findInvalidIDBetween(left_int, right_int, &invalidIds, std.heap.page_allocator);
        }
    }
    var result: usize = 0;
    for (invalidIds.items) |item| {
        result += item;
    }
    std.debug.print("Sum of invalid IDs: {d}\n", .{result});
}

pub fn findInvalidIDBetween(left: usize, right: usize, invalidIds: *std.ArrayList(usize), allocator: std.mem.Allocator) !void {
    for (left..right + 1) |id| {
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

pub fn numberRepeatsBackToBack(number: []const u8) bool {
    const pattern = "^(\\d+)\\1$";

    var errcode: c_int = 0;
    var erroffset: usize = 0;

    const re = pcre2_compile_8(
        pattern.ptr,
        pattern.len,
        0,
        &errcode,
        &erroffset,
        null,
    );

    if (re == null) {
        std.debug.print("PCRE2 compilation failed at offset {}: error {}\n", .{ erroffset, errcode });
        return false;
    }
    defer pcre2_code_free_8(re);
    // Create match data
    const match_data = pcre2_match_data_create_from_pattern_8(re, null);
    if (match_data == null) {
        std.debug.print("Failed to create match data\n", .{});
        return false;
    }
    defer pcre2_match_data_free_8(match_data);

    const rc = pcre2_match_8(
        re,
        number.ptr,
        number.len,
        0,
        0,
        match_data,
        null,
    );

    if (rc >= 0) {
        std.debug.print("✓ '{s}'\n", .{number});
        return true;
    } else if (rc == c.PCRE2_ERROR_NOMATCH) {
        std.debug.print("✗ '{s}'\n", .{number});
    } else {
        std.debug.print("Error {}: '{s}'\n", .{ rc, number });
    }
    return false;
}

test "12 does not repeat" {
    const number: [:0]const u8 = "12";
    try std.testing.expect(numberRepeatsBackToBack(number) == false);
}

test "11 repeats" {
    const number: [:0]const u8 = "11";
    try std.testing.expect(numberRepeatsBackToBack(number) == true);
}

test "22 repeats" {
    const number: [:0]const u8 = "22";
    try std.testing.expect(numberRepeatsBackToBack(number) == true);
}

test "1212 repeats" {
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
    try std.testing.expect(list.items[1] == 22);
}
