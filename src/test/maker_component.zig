const std = @import("std");
const testing = std.testing;

const maker = @import("../lib/maker.zig");

const allocator = testing.allocator;

//
// Working tests
//
test "component led switch" {
    var creation = maker.Creation.init(allocator);
    defer creation.deinit();

    var component = maker.Component.init(&creation, .{ 1, 1, 1 });

    //
    const LED = try component.addBlockH(.LED, .{ 0, 5, 0 }, null);
    const toggle = try component.addBlockH(.FLIPFLOP, .{ 0, -1, 0 }, null);

    try component.connect(toggle, LED);
    //

    try testing.expectEqual(2, creation.handle);

    var out = std.ArrayList(u8).init(allocator);
    defer out.deinit();

    var writer = out.writer();
    try creation.compile(&writer);

    try testing.expectEqualStrings("6,,1,6,1,;5,,1,0,1,?2,1?", out.items);
}

//
// Random data tests
//
test "component add block" {
    var creation = maker.Creation.init(allocator);
    defer creation.deinit();

    var component = maker.Component.init(&creation, .{ 1, 1, 1 });

    //
    try component.addBlock(.AND, .{ -12, 3, 2 }, null);
    try component.addBlock(.XOR, null, null);
    try component.addBlock(.AND, .{ 0, 0, 0 }, null);

    try component.addBlock(.LED, .{ 10, -10, 2543 }, &[_]i16{ 123, 123, 23 });
    try component.addBlock(.NAND, null, &[_]i16{ -12, 0, 0, 0, 3434 });
    try component.addBlock(.BUTTON, .{ 0, 0, 0 }, &[_]i16{});
    //

    try testing.expectEqual(6, creation.handle);

    try testing.expectEqualStrings("1,,-11,4,3,;3,,,,,;1,,1,1,1,;6,,11,-9,2544,0123+0123+23;10,,,,,-12+0+0+0+3434;4,,1,1,1,;", component.creation.blocks.items);
}

test "component add connection" {
    var creation = maker.Creation.init(allocator);
    defer creation.deinit();

    var component = maker.Component.init(&creation, .{ 1, 1, 1 });

    //
    try component.connect(0, 0);
    try component.connect(1, 2);
    try component.connect(9999, 9999);
    try component.connect(9999, 1234);
    //

    try testing.expectEqual(0, creation.handle);

    try testing.expectEqualStrings("0,0;1,2;9999,9999;9999,1234;", component.creation.connections.items);
}

test "component compile" {
    var creation = maker.Creation.init(allocator);
    defer creation.deinit();

    var component = maker.Component.init(&creation, .{ 1, 1, 1 });

    //
    try component.connect(0, 0);
    try component.connect(1, 2);
    try component.addBlock(.AND, .{ -12, 3, 2 }, null);
    try component.addBlock(.XOR, null, null);
    try component.connect(12, 934213);
    try component.addBlock(.AND, .{ 0, 0, 0 }, null);
    try component.connect(77777777, 4435546);
    try component.addBlock(.LED, .{ 10, -10, 2543 }, &[_]i16{ 123, 123, 23 });
    try component.addBlock(.NAND, null, &[_]i16{ -12, 0, 0, 0, 3434 });
    try component.addBlock(.BUTTON, .{ 0, 0, 0 }, &[_]i16{});
    try component.connect(9999, 9999);
    try component.connect(9999, 1234);
    //

    try testing.expectEqual(6, creation.handle);

    var out = std.ArrayList(u8).init(allocator);
    defer out.deinit();

    var writer = out.writer();
    try creation.compile(&writer);

    try testing.expectEqualStrings("1,,-11,4,3,;3,,,,,;1,,1,1,1,;6,,11,-9,2544,0123+0123+23;10,,,,,-12+0+0+0+3434;4,,1,1,1,?0,0;1,2;12,934213;77777777,04435546;9999,9999;9999,1234?", out.items);
}
