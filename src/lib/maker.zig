const std = @import("std");

pub const NodeType = enum(u8) {
    NOR,
    AND,
    OR,
    XOR,
    BUTTON,
    FLIPFLOP,
    LED,
    SOUND,
    CONDUCTOR,
    CUSTOM,
    NAND,
    XNOR,
    RANDOM,
    TEXT,
    TILE,
    NODE,
    DELAY,
    ANTENNA,
    CONDUCTOR_V2,
    LED_MIXER,
};

fn fastFormatInt(
    value: anytype,
    fbs: *std.io.FixedBufferStream([]u8),
) !void {
    const int_value = if (@TypeOf(value) == comptime_int) blk: {
        const Int = std.math.IntFittingRange(value, value);
        break :blk @as(Int, value);
    } else value;

    const value_info = @typeInfo(@TypeOf(int_value)).Int;
    const min_int_bits = comptime @max(value_info.bits, 8);
    const MinInt = std.meta.Int(.unsigned, min_int_bits);

    const abs_value = @abs(int_value);
    var a: MinInt = abs_value;

    if (value_info.signedness == .signed) {
        if (value < 0) {
            fbs.buffer[fbs.pos] = '-';
            fbs.pos += 1;
        }
    }

    if (a < 10) {
        fbs.buffer[fbs.pos] = '0' + @as(u8, @intCast(a));
        fbs.pos += 1;
    } else if (a < 100) {
        fbs.buffer[fbs.pos..][0..2].* = std.fmt.digits2(@as(usize, @intCast(a)));
        fbs.pos += 2;
    } else {
        var buf: [5]u8 = undefined;
        var p = buf.len;

        while (a >= 100) : (a = @divTrunc(a, 100)) {
            p -= 1;
            buf[p] = @intCast(a % 100);
        }
        p -= 1;
        buf[p] = @intCast(a);

        for (buf[p..]) |v| {
            fbs.buffer[fbs.pos..][0..2].* = std.fmt.digits2(@as(usize, @intCast(v)));
            fbs.pos += 2;
        }
    }
}

pub fn generateBlock(buf: []u8, id: NodeType, position: ?@Vector(3, i16), properties: ?[]const i16) !usize {
    var fbs = std.io.fixedBufferStream(buf);
    const idInt = @intFromEnum(id);

    if (idInt < 10) {
        fbs.buffer[fbs.pos] = idInt + '0';
        fbs.pos += 1;
    } else {
        fbs.buffer[fbs.pos..][0..2].* = std.fmt.digits2(idInt);
        fbs.pos += 2;
    }

    fbs.buffer[fbs.pos..][0..2].* = .{ ',', ',' };
    fbs.pos += 2;

    if (position) |pos| {
        try fastFormatInt(pos[0], &fbs);
        fbs.buffer[fbs.pos] = ',';
        fbs.pos += 1;
        try fastFormatInt(pos[1], &fbs);
        fbs.buffer[fbs.pos] = ',';
        fbs.pos += 1;
        try fastFormatInt(pos[2], &fbs);
        fbs.buffer[fbs.pos] = ',';
        fbs.pos += 1;
    } else {
        fbs.buffer[fbs.pos..][0..3].* = .{ ',', ',', ',' };
        fbs.pos += 3;
    }

    if (properties) |prop| {
        for (prop) |val| {
            try fastFormatInt(val, &fbs);
            fbs.buffer[fbs.pos] = '+';
            fbs.pos += 1;
        }

        if (prop.len != 0) {
            fbs.pos -= 1;
        }
    }
    fbs.buffer[fbs.pos] = ';';
    fbs.pos += 1;

    return fbs.pos;
}

pub const Creation = struct {
    blocks: std.ArrayList(u8),
    connections: std.ArrayList(u8),
    handle: u32,

    pub fn compile(self: *Creation, writer: anytype) !void {
        if (self.blocks.items.len > 0) {
            _ = self.blocks.pop();
            try writer.writeAll(self.blocks.items);
            try self.blocks.append(';');

            try writer.writeAll("?");
        }

        if (self.connections.items.len > 0) {
            _ = self.connections.pop();
            try writer.writeAll(self.connections.items);
            try self.connections.append(';');

            try writer.writeAll("?");
        }
    }

    pub fn addBlock(self: *Creation, id: NodeType, position: ?@Vector(3, i16), properties: ?[]const i16) !void {
        // buffer for the block format with a maximum of 5 properties
        const bufsize = 2 + 1 + 1 + 6 + 1 + 6 + 1 + 6 + 1 + (5 * 6) + 1;
        const len = self.blocks.items.len;
        try self.blocks.ensureUnusedCapacity(bufsize);
        self.blocks.expandToCapacity();

        const buf = self.blocks.items[len .. len + bufsize];

        const end = try generateBlock(buf, id, position, properties);
        self.blocks.items.len = len + end;

        self.handle += 1;
    }
    pub inline fn addBlockH(self: *Creation, id: NodeType, position: ?@Vector(3, i16), properties: ?[]const i16) !u32 {
        try addBlock(self, id, position, properties);
        return self.handle;
    }

    pub inline fn connect(self: *Creation, nodeA: u32, nodeB: u32) !void {
        const bufsize = 1 + 10 + 1 + 10 + 1;
        const len = self.connections.items.len;
        try self.connections.ensureUnusedCapacity(bufsize);
        self.connections.expandToCapacity();

        const buf = self.connections.items[len .. len + bufsize];
        var fbs = std.io.fixedBufferStream(buf);

        try fastFormatInt(nodeA, &fbs);
        fbs.buffer[fbs.pos] = ',';
        fbs.pos += 1;
        try fastFormatInt(nodeB, &fbs);
        fbs.buffer[fbs.pos] = ';';
        fbs.pos += 1;

        self.connections.items.len = len + fbs.pos;
    }

    pub fn init(allocator: std.mem.Allocator) Creation {
        return Creation{
            .blocks = std.ArrayList(u8).init(allocator),
            .connections = std.ArrayList(u8).init(allocator),
            .handle = 0,
        };
    }

    pub fn deinit(self: Creation) void {
        self.blocks.deinit();
        self.connections.deinit();
    }
};

pub const Component = struct {
    creation: *Creation,
    position: ?@Vector(3, i16),

    pub inline fn addBlock(self: *Component, id: NodeType, position: ?@Vector(3, i16), properties: ?[]const i16) !void {
        if (position) |pos| {
            try self.creation.addBlock(id, if (self.position) |cpos| cpos + pos else pos, properties);
        } else {
            try self.creation.addBlock(id, null, properties);
        }
    }
    pub inline fn addBlockH(self: *Component, id: NodeType, position: ?@Vector(3, i16), properties: ?[]const i16) !u32 {
        try addBlock(self, id, position, properties);
        return self.creation.handle;
    }

    pub inline fn connect(self: *Component, nodeA: u32, nodeB: u32) !void {
        try self.creation.connect(nodeA, nodeB);
    }

    pub fn init(creation: *Creation, position: ?@Vector(3, i16)) Component {
        return Component{
            .creation = creation,
            .position = position,
        };
    }
};
