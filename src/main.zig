const std = @import("std");
const maker = @import("maker.zig");
const memory = @import("memory.zig");

fn makeReg(allocator: std.mem.Allocator) !void {
  var creation = maker.Creation.init(allocator);
  defer creation.deinit();

  const bits = 10;
  
  const register = try memory.makeRegister(&creation, bits, .{0, 0, 0});

  const toggle = try creation.addBlockH(.FLIPFLOP, .{0, 0, -1}, null);
  const input = try creation.addBlockH(.BUTTON, .{1, 0, -1}, null);

  try creation.connect(toggle, memory.getRegisterWrite(register, 3));
  try creation.connect(input, memory.getRegisterInput(register, 3));

  var outw = std.io.getStdOut().writer().any();
  try creation.compile(&outw);
}

fn calcCubeMem(comptime maxX: f64, comptime maxY: f64, comptime maxZ: f64, comptime maxBlocks: u32) comptime_int {
  const id = 2;
  const pad = 5;

  return (id + @ceil(@log10(maxX))  + @ceil(@log10(maxY)) + @ceil(@log10(maxZ)) + pad) * maxBlocks;
}

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
  
  while (x < size) : (x+=1) {
    var y: i16 = 0;

    while (y < size) : (y+=1) {
      var z: i16 = 0;

      while (z < size) : (z+=1) {
        try creation.addBlock(@enumFromInt(id), .{x, y, z}, null);
      }
    }
  }

  std.debug.print("Generation: {}ns\n", .{timer.lap()});

  var out = std.io.getStdOut();
  try creation.compile(&out);

  std.debug.print("Compilation: {}ns\n", .{timer.lap()});
}