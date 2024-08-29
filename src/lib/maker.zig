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

const mask24: u64 = (1 << 24) - 1;
const mask32: u64 = (1 << 32) - 1;
const mask57: u64 = (1 << 57) - 1;

inline fn dd(n: anytype) [2]u8 {
    return ("0001020304050607080910111213141516171819" ++
        "2021222324252627282930313233343536373839" ++
        "4041424344454647484950515253545556575859" ++
        "6061626364656667686970717273747576777879" ++
        "8081828384858687888990919293949596979899")[n * 2 ..][0..2].*;
}

/// Ported https://github.com/jeaiii/itoa to zig
/// likely decreased performance too
inline fn fastFormatInt(
    value: anytype,
    fbs: *std.io.FixedBufferStream([]u8),
) void {
    const int_value = if (@TypeOf(value) == comptime_int) blk: {
        const Int = std.math.IntFittingRange(value, value);
        break :blk @as(Int, value);
    } else value;

    const value_info = @typeInfo(@TypeOf(int_value)).Int;
    const min_int_bits = comptime @max(value_info.bits, 8);
    const MinInt = std.meta.Int(.unsigned, min_int_bits);

    const abs_value = @abs(int_value);
    const n: MinInt = abs_value;

    if (value_info.signedness == .signed) {
        if (value < 0) {
            fbs.buffer[fbs.pos] = '-';
            fbs.pos += 1;
        }
    }

    if (n < 100) {
        if (n < 10) {
            fbs.buffer[fbs.pos] = "0123456789"[n];
            fbs.pos += 1;
            return;
        }

        fbs.buffer[fbs.pos..][0..2].* = dd(n);
        fbs.pos += 2;
        return;
    }

    var b = fbs.buffer[fbs.pos..];

    if (n < (1_000_000)) {
        if (n < (10_000)) {
            const f0: u64 = @as(u64, 167773) * n;

            if (n < (1_000)) {
                fbs.buffer[fbs.pos] = "0123456789"[f0 >> 24];

                const f2: u64 = (f0 & mask24) * 100;
                b[1..3].* = dd(f2 >> 24);
                fbs.pos += 3;
                return;
            }

            b[0..2].* = dd(f0 >> 24);
            const f2: u64 = (f0 & mask24) * 100;
            b[2..4].* = dd(f2 >> 24);
            fbs.pos += 4;
            return;
        }

        const f0: u64 = @as(u64, 429497) * n;

        if (n < 100_000) {
            fbs.buffer[fbs.pos] = "0123456789"[f0 >> 32];

            const f2: u64 = (f0 & mask32) * 100;
            b[1..3].* = dd(f2 >> 32);
            const f4: u64 = (f2 & mask32) * 100;
            b[3..5].* = dd(f4 >> 32);
            fbs.pos += 5;
            return;
        }

        b[0..2].* = dd(f0 >> 32);
        const f2: u64 = (f0 & mask32) * 100;
        b[2..4].* = dd(f2 >> 32);
        const f4: u64 = (f2 & mask32) * 100;
        b[4..6].* = dd(f4 >> 32);
        fbs.pos += 6;
        return;
    }

    if (n < 100_000_000) {
        const f0: u64 = @as(u64, 281474977) * n >> 16;

        if (n < 10_000_000) {
            fbs.buffer[fbs.pos] = "0123456789"[f0 >> 32];
            const f2: u64 = (f0 & mask32) * 100;
            b[1..3].* = dd(f2 >> 32);
            const f4: u64 = (f2 & mask32) * 100;
            b[3..5].* = dd(f4 >> 32);
            const f6: u64 = (f4 & mask32) * 100;
            b[5..7].* = dd(f6 >> 32);
            fbs.pos += 7;
            return;
        }

        b[0..2].* = dd(f0 >> 32);
        const f2: u64 = (f0 & mask32) * 100;
        b[2..4].* = dd(f2 >> 32);
        const f4: u64 = (f2 & mask32) * 100;
        b[4..6].* = dd(f4 >> 32);
        const f6: u64 = (f4 & mask32) * 100;
        b[6..8].* = dd(f6 >> 32);
        fbs.pos += 8;
        return;
    }

    const f0: u64 = 1441151881 * n;

    if (n < 1_000_000_000) {
        fbs.buffer[fbs.pos] = "0123456789"[f0 >> 57];
        const f2: u64 = (f0 & mask57) * 100;
        b[1..3].* = dd(f2 >> 57);
        const f4: u64 = (f2 & mask57) * 100;
        b[3..5].* = dd(f4 >> 57);
        const f6: u64 = (f4 & mask57) * 100;
        b[5..7].* = dd(f6 >> 57);
        const f8: u64 = (f6 & mask57) * 100;
        b[7..9].* = dd(f8 >> 57);
        fbs.pos += 9;
        return;
    }

    b[0..2].* = dd(f0 >> 57);
    const f2: u64 = (f0 & mask57) * 100;
    b[2..4].* = dd(f2 >> 57);
    const f4: u64 = (f2 & mask57) * 100;
    b[4..6].* = dd(f4 >> 57);
    const f6: u64 = (f4 & mask57) * 100;
    b[6..8].* = dd(f6 >> 57);
    const f8: u64 = (f6 & mask57) * 100;
    b[8..10].* = dd(f8 >> 57);
    fbs.pos += 10;
}

pub inline fn generateBlock(fbs: *std.io.FixedBufferStream([]u8), id: NodeType, position: ?[3]i16, properties: ?[]const i16) usize {
    const idInt = @intFromEnum(id);

    if (idInt < 10) {
        fbs.buffer[fbs.pos] = idInt + '0';
        fbs.pos += 1;
    } else {
        fbs.buffer[fbs.pos..][0..2].* = dd(idInt);
        fbs.pos += 2;
    }

    fbs.buffer[fbs.pos..][0..2].* = .{ ',', ',' };
    fbs.pos += 2;

    if (position) |pos| {
        fastFormatInt(pos[0], fbs);
        fbs.buffer[fbs.pos] = ',';
        fbs.pos += 1;
        fastFormatInt(pos[1], fbs);
        fbs.buffer[fbs.pos] = ',';
        fbs.pos += 1;
        fastFormatInt(pos[2], fbs);
        fbs.buffer[fbs.pos] = ',';
        fbs.pos += 1;
    } else {
        fbs.buffer[fbs.pos..][0..3].* = .{ ',', ',', ',' };
    }

    if (properties) |prop| {
        for (prop) |val| {
            fastFormatInt(val, fbs);
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

    pub inline fn addBlock(self: *Creation, id: NodeType, position: ?[3]i16, properties: ?[]const i16) !void {
        // buffer for the block format with a maximum of 5 properties
        const bufsize = 2 + 1 + 1 + 6 + 1 + 6 + 1 + 6 + 1 + (5 * 6) + 1;
        const len = self.blocks.items.len;
        try self.blocks.ensureUnusedCapacity(bufsize);
        self.blocks.expandToCapacity();

        const buf = self.blocks.items[len .. len + bufsize];
        var fbs = std.io.fixedBufferStream(buf);

        const end = generateBlock(&fbs, id, position, properties);
        self.blocks.items.len = len + end;

        self.handle += 1;
    }
    pub inline fn addBlockH(self: *Creation, id: NodeType, position: @Vector(3, i16), properties: ?[]const i16) !u32 {
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

        fastFormatInt(nodeA, &fbs);
        fbs.buffer[fbs.pos] = ',';
        fbs.pos += 1;
        fastFormatInt(nodeB, &fbs);
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
