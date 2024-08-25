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

    var creation = maker.Creation.init(allocator);
    defer creation.deinit();

    const id = try std.fmt.parseInt(u8, args[1], 10);
    const size = try std.fmt.parseInt(u16, args[2], 10);

    var timer = try std.time.Timer.start();

    var x: i16 = 0;

    while (x < size) : (x += 1) {
        var y: i16 = 0;

        while (y < size) : (y += 1) {
            var z: i16 = 0;

            while (z < size) : (z += 1) {
                try creation.addBlock(@enumFromInt(id), .{ x, y, z }, null);
            }
        }
    }

    std.debug.print("Generation: {}ns\n", .{timer.lap()});

    var out = std.io.getStdOut();
    try creation.compile(&out);

    std.debug.print("Compilation: {}ns\n", .{timer.lap()});
}
