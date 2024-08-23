const std = @import("std");
const maker = @import("lib/maker.zig");
const memory = @import("lib/memory.zig");

pub fn main() !void {
  var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
  defer arena.deinit();
  const allocator = arena.allocator();

  const args = try std.process.argsAlloc(allocator);
  if (args.len != 2) {
    std.debug.print("Usage: {s} <bits>\n", .{args[0]});
    return error.InvalidParams;
  }

  const bits = try std.fmt.parseInt(u16, args[1], 10);

  var creation = maker.Creation.init(allocator);
  defer creation.deinit();

  var timer = try std.time.Timer.start();

  _ = try memory.makeRegister(&creation, bits, .{0, 0, 0});

  std.debug.print("Generation: {}ns\n", .{timer.lap()});

  var out = std.io.getStdOut();
  try creation.compile(&out);

  std.debug.print("Compilation: {}ns\n", .{timer.lap()});
}