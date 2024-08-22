const std = @import("std");
const testing = std.testing;

const maker = @import("../maker.zig");
const memory = @import("../memory.zig");

const allocator = testing.allocator;

//
// Feature tests
//
test "memory 8b register" {
  var creation = maker.Creation.init(allocator);
  defer creation.deinit();

  //
  const register = memory.makeRegister(&creation, 4, .{0,0,0});
  //

  try testing.expectEqual(1, register);

  var out = std.ArrayList(u8).init(allocator);
  defer out.deinit();

  var writer = out.writer();
  try creation.compile(&writer);

  try testing.expectEqualStrings(
    "3,,2,0,0,;1,,1,0,0,;5,,0,0,0,;3,,2,1,0,;1,,1,1,0,;5,,0,1,0,;3,,2,2,0,;1,,1,2,0,;5,,0,2,0,;3,,2,3,0,;1,,1,3,0,;5,,0,3,0,?1,2;2,3;3,1;4,5;5,6;6,4;7,8;8,9;9,7;10,11;11,12;12,10?",
    out.items
  );
}

test "memory get register" {
  var creation = maker.Creation.init(allocator);
  defer creation.deinit();

  //
  const register = try memory.makeRegister(&creation, 4, .{0,0,0});

  const bit = 2;
  const input = memory.getRegisterInput(register, bit);
  const output = memory.getRegisterOutput(register, bit);
  const write = memory.getRegisterWrite(register, bit);
  //

  try testing.expectEqual(1, register);

  try testing.expectEqual(7, input);
  try testing.expectEqual(9, output);
  try testing.expectEqual(8, write);
}