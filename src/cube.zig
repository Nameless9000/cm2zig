const std = @import("std");
const maker = @import("lib/maker.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);
    if (args.len != 3) {
        std.debug.print("Usage: {s} <block id> <cube size>\n", .{args[0]});
        return error.InvalidParams;
    }

    const id = try std.fmt.parseInt(u8, args[1], 10);
    const size = try std.fmt.parseInt(u32, args[2], 10);

    var creation = try maker.Creation.init(allocator, size * size * size, 0);
    defer creation.deinit();

    var timer = try std.time.Timer.start();

    var x: i16 = 0;

    while (x < size) : (x += 1) {
        var y: i16 = 0;

        while (y < size) : (y += 1) {
            var z: i16 = 0;

            while (z < size) : (z += 1) {
                creation.addBlock(@enumFromInt(id), .{ x, y, z }, null);
            }
        }
    }

    std.debug.print("Generation: {}us\n", .{@divTrunc(timer.lap(), 1000)});

    var out = std.io.getStdOut();
    try creation.compile(&out);

    std.debug.print("Compilation: {}us\n", .{@divTrunc(timer.lap(), 1000)});
}
