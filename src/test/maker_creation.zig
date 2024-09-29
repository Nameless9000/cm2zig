const std = @import("std");
const testing = std.testing;

const maker = @import("../lib/maker.zig");
const memory = @import("../lib/memory.zig");

const allocator = testing.allocator;

//
// Working tests
//
test "creation led switch" {
    var creation = try maker.Creation.init(allocator, 2, 1);
    defer creation.deinit();

    //
    const LED: u32 = creation.addBlockH(.LED, .{ 0, 5, 0 }, null);
    const toggle: u32 = creation.addBlockH(.FLIPFLOP, .{ 0, 0, 0 }, null);

    creation.connect(toggle, LED);
    //

    try testing.expectEqual(2, creation.handle);

    var out = std.ArrayList(u8).init(allocator);
    defer out.deinit();

    var writer = out.writer();
    try creation.compile(&writer);

    try testing.expectEqualStrings("6,,0,5,0,;5,,0,0,0,?2,1?", out.items);
}

//
// Random data tests
//
test "creation add block" {
    var creation = try maker.Creation.init(allocator, 6, 0);
    defer creation.deinit();

    //
    creation.addBlock(.AND, .{ -12, 3, 2 }, null);
    creation.addBlock(.XOR, null, null);
    creation.addBlock(.AND, .{ 0, 0, 0 }, null);

    creation.addBlock(.LED, .{ 10, -10, 2543 }, &[_]i16{ 123, 123, 23 });
    creation.addBlock(.NAND, null, &[_]i16{ -12, 0, 0, 0, 3434 });
    creation.addBlock(.BUTTON, .{ 0, 0, 0 }, &[_]i16{});
    //

    try testing.expectEqual(6, creation.handle);

    try testing.expectEqualStrings("1,,-12,3,2,;3,,,,,;1,,0,0,0,;6,,10,-10,2543,123+123+23;10,,,,,-12+0+0+0+3434;4,,0,0,0,;", creation.blocks);
}

test "creation add connection" {
    var creation = try maker.Creation.init(allocator, 0, 4);
    defer creation.deinit();

    //
    creation.connect(0, 0);
    creation.connect(1, 2);
    creation.connect(9999, 9999);
    creation.connect(9999, 1234);
    //

    try testing.expectEqual(0, creation.handle);

    try testing.expectEqualStrings("0,0;1,2;9999,9999;9999,1234;", creation.connections);
}

test "creation compile" {
    var creation = try maker.Creation.init(allocator, 6, 6);
    defer creation.deinit();

    //
    creation.connect(0, 0);
    creation.connect(1, 2);
    creation.addBlock(.AND, .{ -12, 3, 2 }, null);
    creation.addBlock(.XOR, null, null);
    creation.connect(12, 934213);
    creation.addBlock(.AND, .{ 0, 0, 0 }, null);
    creation.connect(77777777, 4435546);
    creation.addBlock(.LED, .{ 10, -10, 2543 }, &[_]i16{ 123, 123, 23 });
    creation.addBlock(.NAND, null, &[_]i16{ -12, 0, 0, 0, 3434 });
    creation.addBlock(.BUTTON, .{ 0, 0, 0 }, &[_]i16{});
    creation.connect(9999, 9999);
    creation.connect(9999, 1234);
    //

    try testing.expectEqual(6, creation.handle);

    var out = std.ArrayList(u8).init(allocator);
    defer out.deinit();

    var writer = out.writer();
    try creation.compile(&writer);

    try testing.expectEqualStrings("1,,-12,3,2,;3,,,,,;1,,0,0,0,;6,,10,-10,2543,123+123+23;10,,,,,-12+0+0+0+3434;4,,0,0,0,?0,0;1,2;12,934213;77777777,4435546;9999,9999;9999,1234?", out.items);
}
