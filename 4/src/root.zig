//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
const Rectangle = struct {
    width: usize,
    height: usize,
};
const GRID_WIDTH: usize = 10;
const GRID_HEIGHT: usize = 10;

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

pub fn forkLiftCanAccess(grid: *[GRID_HEIGHT][GRID_WIDTH]bool, rowIndex: usize, columnIndex: usize) bool {
    if (grid[rowIndex][columnIndex]) {
        return true;
    }
    return false;
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
