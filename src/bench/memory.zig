const std = @import("std");
const benchmark = @import("benchmark.zig");

const maker = @import("../lib/maker.zig");
const memory = @import("../lib/memory.zig");

fn regBench1(allocator: std.mem.Allocator, timer: *std.time.Timer) !void {
    var creation = maker.Creation.init(allocator);
    defer creation.deinit();

    timer.reset();

    var count: usize = 0;
    while (count < 100) : (count += 1) {
        std.mem.doNotOptimizeAway(try memory.makeRegister(&creation, 50, null));
    }
}

fn regBench2(allocator: std.mem.Allocator, timer: *std.time.Timer) !void {
    var creation = maker.Creation.init(allocator);
    defer creation.deinit();

    timer.reset();

    var count: usize = 0;
    while (count < 100) : (count += 1) {
        std.mem.doNotOptimizeAway(try memory.makeRegister(&creation, 50, .{ 0, 0, 0 }));
    }
}

pub fn run() !void {
    (try benchmark.run(regBench1)).print("100x 50 bit register, no pos");
    (try benchmark.run(regBench2)).print("100x 50 bit register");
}
