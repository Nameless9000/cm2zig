const std = @import("std");
const benchmark = @import("benchmark.zig");

const maker = @import("../lib/maker.zig");
const memory = @import("../lib/memory.zig");

fn blockBench1(allocator: std.mem.Allocator, timer: *std.time.Timer) !void {
  var creation = maker.Creation.init(allocator);
  defer creation.deinit();

  timer.reset();
  
  var count: usize = 0;
  while (count < 1_000_000) : (count += 1) {
    std.mem.doNotOptimizeAway(try creation.addBlock(.NOR, null, null));
  }
}

fn blockBench2(allocator: std.mem.Allocator, timer: *std.time.Timer) !void {
  var creation = maker.Creation.init(allocator);
  defer creation.deinit();

  timer.reset();
  
  var count: usize = 0;
  while (count < 1_000_000) : (count += 1) {
    std.mem.doNotOptimizeAway(try creation.addBlock(.NOR, .{1, 2, 3}, null));
  }
}

fn blockBench3(allocator: std.mem.Allocator, timer: *std.time.Timer) !void {
  var creation = maker.Creation.init(allocator);
  defer creation.deinit();

  timer.reset();
  
  var count: usize = 0;
  while (count < 1_000_000) : (count += 1) {
    const x: i16 = @intCast(count % 100);
    const y: i16 = @intCast(count % 1000);
    const z: i16 = @intCast(count % 10000);
    std.mem.doNotOptimizeAway(try creation.addBlock(.NOR, .{x, y, z}, null));
  }
}

fn blockBench4(allocator: std.mem.Allocator, timer: *std.time.Timer) !void {
  var creation = maker.Creation.init(allocator);
  defer creation.deinit();

  timer.reset();
  
  var count: usize = 0;
  while (count < 1_000_000) : (count += 1) {
    const x: i16 = @intCast(count % 100);
    const y: i16 = @intCast(count % 1000);
    const z: i16 = @intCast(count % 10000);
    std.mem.doNotOptimizeAway(try creation.addBlock(.NOR, .{x, y, z}, &[_]i16{x, y, z}));
  }
}

fn connectionBench1(allocator: std.mem.Allocator, timer: *std.time.Timer) !void {
  var creation = maker.Creation.init(allocator);
  defer creation.deinit();

  timer.reset();
  
  var count: u32 = 0;
  while (count < 1_000_000) : (count += 1) {
    std.mem.doNotOptimizeAway(try creation.connect(1,1));
  }
}

fn connectionBench2(allocator: std.mem.Allocator, timer: *std.time.Timer) !void {
  var creation = maker.Creation.init(allocator);
  defer creation.deinit();

  timer.reset();
  
  var count: u32 = 0;
  while (count < 1_000_000) : (count += 1) {
    std.mem.doNotOptimizeAway(try creation.connect(count, count - 5));
  }
}

test {
  (try benchmark.run(blockBench1)).print("1m blocks, no data");
  (try benchmark.run(blockBench2)).print("1m blocks, static position data");
  (try benchmark.run(blockBench3)).print("1m blocks, dynamic position data");
  (try benchmark.run(blockBench4)).print("1m blocks, dynamic position & property data");
  (try benchmark.run(connectionBench1)).print("1m connections, static");
  (try benchmark.run(connectionBench2)).print("1m connections, dynamic");
}