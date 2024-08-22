const std = @import("std");
const testing = std.testing;

const maker = @import("../maker.zig");
const memory = @import("../memory.zig");

const allocator = testing.allocator;

//
// Working tests
//
test "creation led switch" {
  var creation = maker.Creation.init(allocator);
  defer creation.deinit();

  //
  const LED = try creation.addBlockH(.LED, .{0, 5, 0}, null);
  const toggle = try creation.addBlockH(.FLIPFLOP, .{0, 0, 0}, null);

  try creation.connect(toggle, LED);
  //

  try testing.expectEqual(2, creation.handle);

  var out = std.ArrayList(u8).init(allocator);
  defer out.deinit();

  var writer = out.writer().any();
  try creation.compile(&writer);

  try testing.expectEqualStrings(
    "6,,0,5,0,;5,,0,0,0,?2,1?",
    out.items
  );
}


//
// Random data tests
//
test "creation add block" {
  var creation = maker.Creation.init(allocator);
  defer creation.deinit();

  //
  try creation.addBlock(.AND, .{-12,3,2}, null);
  try creation.addBlock(.XOR, null, null);
  try creation.addBlock(.AND, .{0,0,0}, null);

  try creation.addBlock(.LED, .{10,-10,2543}, &[_]i16{123,123,23});
  try creation.addBlock(.NAND, null, &[_]i16{-12,0,0,0,3434});
  try creation.addBlock(.BUTTON, .{0,0,0}, &[_]i16{});
  //

  try testing.expectEqual(6, creation.handle);

  try testing.expectEqualStrings(
    "1,,-12,3,2,;3,,,,,;1,,0,0,0,;6,,10,-10,2543,123+123+23;10,,,,,-12+0+0+0+3434;4,,0,0,0,;",
    creation.data.items
  );
}

test "creation add connection" {
  var creation = maker.Creation.init(allocator);
  defer creation.deinit();

  //
  try creation.connect(0, 0);
  try creation.connect(1, 2);
  try creation.connect(9999, 9999);
  try creation.connect(9999, 1234);
  //

  try testing.expectEqual(0, creation.handle);

  try testing.expectEqualStrings(
    "0,0;1,2;9999,9999;9999,1234;",
    creation.connections.items
  );
}

test "creation compile" {
  var creation = maker.Creation.init(allocator);
  defer creation.deinit();

  //
  try creation.connect(0, 0);
  try creation.connect(1, 2);
  try creation.addBlock(.AND, .{-12,3,2}, null);
  try creation.addBlock(.XOR, null, null);
  try creation.connect(12, 934213);
  try creation.addBlock(.AND, .{0,0,0}, null);
  try creation.connect(77777777, 4435546);
  try creation.addBlock(.LED, .{10,-10,2543}, &[_]i16{123,123,23});
  try creation.addBlock(.NAND, null, &[_]i16{-12,0,0,0,3434});
  try creation.addBlock(.BUTTON, .{0,0,0}, &[_]i16{});
  try creation.connect(9999, 9999);
  try creation.connect(9999, 1234);
  //

  try testing.expectEqual(6, creation.handle);

  var out = std.ArrayList(u8).init(allocator);
  defer out.deinit();

  var writer = out.writer().any();
  try creation.compile(&writer);

  try testing.expectEqualStrings(
    "1,,-12,3,2,;3,,,,,;1,,0,0,0,;6,,10,-10,2543,123+123+23;10,,,,,-12+0+0+0+3434;4,,0,0,0,?0,0;1,2;12,934213;77777777,4435546;9999,9999;9999,1234?",
    out.items
  );
}
