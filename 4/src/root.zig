//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
const Rectangle = struct {
    width: usize,
    height: usize,
};
const CoOrdinate = struct {
    row: i64,
    column: i64,
};
const GRID_WIDTH: usize = 140;
const GRID_HEIGHT: usize = 140;

pub fn findSize(filename: []const u8) !Rectangle {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var file_buffer: [4096]u8 = undefined;
    var reader = file.reader(&file_buffer);

    var grid_width: usize = 0;
    var grid_height: usize = 0;
    while (try reader.interface.takeDelimiter('\n')) |line| {
        grid_width = line.len;
        grid_height += 1;

        const right_trimmed = std.mem.trimRight(u8, line, " \t\n\r");
        std.debug.print("{s}\n", .{right_trimmed});
    }
    std.debug.print("width: {d}\n", .{grid_width});
    std.debug.print("height: {d}\n", .{grid_height});

    return Rectangle{ .width = grid_width, .height = grid_height };
}
pub fn populatePapers(filename: []const u8, grid: *[GRID_WIDTH][GRID_HEIGHT]bool) !void {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    var file_buffer: [4096]u8 = undefined;
    var reader = file.reader(&file_buffer);
    var i: usize = 0;
    while (try reader.interface.takeDelimiter('\n')) |line| : (i += 1) {
        const right_trimmed = std.mem.trimRight(u8, line, " \t\n\r");
        var k: usize = 0;
        while (k < right_trimmed.len) : (k += 1) {
            grid[i][k] = right_trimmed[k] == '@';
        }
    }
}

pub fn forkLiftCanAccess(grid: *[GRID_HEIGHT][GRID_WIDTH]bool, row_index: usize, column_index: usize) bool {
    var has_paper: usize = 0;
    const top_left: CoOrdinate = .{ .row = if (row_index > 0) @intCast(row_index - 1) else -1, .column = if (column_index > 0) @intCast(column_index - 1) else -1 };
    const top: CoOrdinate = .{ .row = if (row_index > 0) @intCast(row_index - 1) else -1, .column = @intCast(column_index) };
    const top_right: CoOrdinate = .{ .row = if (row_index > 0) @intCast(row_index - 1) else -1, .column = @intCast(column_index + 1) };
    const right: CoOrdinate = .{ .row = @intCast(row_index), .column = @intCast(column_index + 1) };
    const bottom_right: CoOrdinate = .{ .row = @intCast(row_index + 1), .column = @intCast(column_index + 1) };
    const bottom: CoOrdinate = .{ .row = @intCast(row_index + 1), .column = @intCast(column_index) };
    const bottom_left: CoOrdinate = .{ .row = @intCast(row_index + 1), .column = if (column_index > 0) @intCast(column_index - 1) else -1 };
    const left: CoOrdinate = .{ .row = @intCast(row_index), .column = if (column_index > 0) @intCast(column_index - 1) else -1 };

    if (grid[row_index][column_index]) {
        if (top_left.row >= 0 and top_left.row < GRID_HEIGHT and top_left.column >= 0 and top_left.column < GRID_WIDTH and grid[@intCast(top_left.row)][@intCast(top_left.column)]) {
            has_paper += 1;
        }
        if (top.row >= 0 and top.row < GRID_HEIGHT and top.column >= 0 and top.column < GRID_WIDTH and grid[@intCast(top.row)][@intCast(top.column)]) {
            has_paper += 1;
        }
        if (top_right.row >= 0 and top_right.row < GRID_HEIGHT and top_right.column >= 0 and top_right.column < GRID_WIDTH and grid[@intCast(top_right.row)][@intCast(top_right.column)]) {
            has_paper += 1;
        }
        if (right.row >= 0 and right.row < GRID_HEIGHT and right.column >= 0 and right.column < GRID_WIDTH and grid[@intCast(right.row)][@intCast(right.column)]) {
            has_paper += 1;
        }
        if (bottom_right.row >= 0 and bottom_right.row < GRID_HEIGHT and bottom_right.column >= 0 and bottom_right.column < GRID_WIDTH and grid[@intCast(bottom_right.row)][@intCast(bottom_right.column)]) {
            has_paper += 1;
        }
        if (bottom.row >= 0 and bottom.row < GRID_HEIGHT and bottom.column >= 0 and bottom.column < GRID_WIDTH and grid[@intCast(bottom.row)][@intCast(bottom.column)]) {
            has_paper += 1;
        }
        if (bottom_left.row >= 0 and bottom_left.row < GRID_HEIGHT and bottom_left.column >= 0 and bottom_left.column < GRID_WIDTH and grid[@intCast(bottom_left.row)][@intCast(bottom_left.column)]) {
            has_paper += 1;
        }
        if (left.row >= 0 and left.row < GRID_HEIGHT and left.column >= 0 and left.column < GRID_WIDTH and grid[@intCast(left.row)][@intCast(left.column)]) {
            has_paper += 1;
        }
    } else {
        return false;
    }
    return has_paper < 4;
}

pub fn solveOne(filename: []const u8) !void {
    const grid_width: usize = GRID_WIDTH;
    const grid_height: usize = GRID_HEIGHT;

    var grid: [grid_height][grid_width]bool = std.mem.zeroes([grid_height][grid_width]bool);
    try populatePapers(filename, &grid);

    var i: usize = 0;
    var forklift_can_access: usize = 0;
    while (i < grid_height) : (i += 1) {
        var j: usize = 0;
        while (j < grid_width) : (j += 1) {
            if (forkLiftCanAccess(&grid, i, j)) {
                forklift_can_access += 1;
            }
        }
    }
    std.log.info("Forklift can access {d} papers", .{forklift_can_access});
}
