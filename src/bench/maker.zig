const std = @import("std");
const benchmark = @import("benchmark.zig");

const maker = @import("../lib/maker.zig");
const memory = @import("../lib/memory.zig");

fn blockBench1(allocator: std.mem.Allocator, timer: *std.time.Timer) !void {
    var creation = try maker.Creation.init(allocator, 100_000, 0);
    defer creation.deinit();

    timer.reset();

    var count: usize = 0;
    while (count < 100_000) : (count += 1) {
        std.mem.doNotOptimizeAway(creation.addBlock(.NOR, null, null));
    }
}

fn blockBench2(allocator: std.mem.Allocator, timer: *std.time.Timer) !void {
    var creation = try maker.Creation.init(allocator, 100_000, 0);
    defer creation.deinit();

    timer.reset();

    var count: usize = 0;
    while (count < 100_000) : (count += 1) {
        std.mem.doNotOptimizeAway(creation.addBlock(.NOR, .{ 1, 2, 3 }, null));
    }
}

fn blockBench3(allocator: std.mem.Allocator, timer: *std.time.Timer) !void {
    var creation = try maker.Creation.init(allocator, 100_000, 0);
    defer creation.deinit();

    timer.reset();

    var count: usize = 0;
    while (count < 100_000) : (count += 1) {
        const x: i16 = @intCast(count % 100);
        const y: i16 = @intCast(count % 1000);
        const z: i16 = @intCast(count % 10000);
        std.mem.doNotOptimizeAway(creation.addBlock(.NOR, .{ x, y, z }, null));
    }
}

fn blockBench4(allocator: std.mem.Allocator, timer: *std.time.Timer) !void {
    var creation = try maker.Creation.init(allocator, 100_000, 0);
    defer creation.deinit();

    timer.reset();

    var count: usize = 0;
    while (count < 100_000) : (count += 1) {
        const x: i16 = @intCast(count % 100);
        const y: i16 = @intCast(count % 1000);
        const z: i16 = @intCast(count % 10000);
        std.mem.doNotOptimizeAway(creation.addBlock(.NOR, .{ x, y, z }, &[_]i16{ x, y, z }));
    }
}

fn connectionBench1(allocator: std.mem.Allocator, timer: *std.time.Timer) !void {
    var creation = try maker.Creation.init(allocator, 0, 100_000);
    defer creation.deinit();

    timer.reset();

    var count: u32 = 0;
    while (count < 100_000) : (count += 1) {
        std.mem.doNotOptimizeAway(creation.connect(1, 1));
    }
}

fn connectionBench2(allocator: std.mem.Allocator, timer: *std.time.Timer) !void {
    var creation = try maker.Creation.init(allocator, 0, 100_000);
    defer creation.deinit();

    timer.reset();

    var count: u32 = 0;
    while (count < 100_000) : (count += 1) {
        std.mem.doNotOptimizeAway(creation.connect(count, count - 5));
    }
}

fn cubeBench1(allocator: std.mem.Allocator, timer: *std.time.Timer) !void {
    var creation = try maker.Creation.init(allocator, 1_000_000, 0);
    defer creation.deinit();

    timer.reset();

    var x: i16 = 0;

    while (x < 100) : (x += 1) {
        var y: i16 = 0;

        while (y < 100) : (y += 1) {
            var z: i16 = 0;

            while (z < 100) : (z += 1) {
                std.mem.doNotOptimizeAway(creation.addBlock(.NOR, .{ x, y, z }, null));
            }
        }
    }
}

pub fn run() !void {
    (try benchmark.run(cubeBench1)).print("100x100x100 cube");
    (try benchmark.run(blockBench1)).print("100k blocks, no data");
    (try benchmark.run(blockBench2)).print("100k blocks, static position data");
    (try benchmark.run(blockBench3)).print("100k blocks, dynamic position data");
    (try benchmark.run(blockBench4)).print("100k blocks, dynamic position & property data");
    (try benchmark.run(connectionBench1)).print("100k connections, static");
    (try benchmark.run(connectionBench2)).print("100k connections, dynamic");
}
