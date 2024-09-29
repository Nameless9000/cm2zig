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
    buf: []u8,
) usize {
    const int_value = if (@TypeOf(value) == comptime_int) blk: {
        const Int = std.math.IntFittingRange(value, value);
        break :blk @as(Int, value);
    } else value;

    const value_info = @typeInfo(@TypeOf(int_value)).Int;
    const min_int_bits = comptime @max(value_info.bits, 8);
    const MinInt = std.meta.Int(.unsigned, min_int_bits);

    const abs_value = @abs(int_value);
    const n: MinInt = abs_value;

    var p: usize = 0;
    if (value_info.signedness == .signed) {
        if (value < 0) {
            buf[0] = '-';
            p = 1;
        }
    }

    if (n < 100) {
        if (n < 10) {
            buf[p] = "0123456789"[n];
            return p + 1;
        }

        buf[p..][0..2].* = dd(n);
        return p + 2;
    }

    var b = buf[p..];

    if (n < (1_000_000)) {
        if (n < (10_000)) {
            const f0: u64 = @as(u64, 167773) * n;

            if (n < (1_000)) {
                buf[p] = "0123456789"[f0 >> 24];

                const f2: u64 = (f0 & mask24) * 100;
                b[1..3].* = dd(f2 >> 24);
                return p + 3;
            }

            b[0..2].* = dd(f0 >> 24);
            const f2: u64 = (f0 & mask24) * 100;
            b[2..4].* = dd(f2 >> 24);
            return p + 4;
        }

        const f0: u64 = @as(u64, 429497) * n;

        if (n < 100_000) {
            buf[p] = "0123456789"[f0 >> 32];

            const f2: u64 = (f0 & mask32) * 100;
            b[1..3].* = dd(f2 >> 32);
            const f4: u64 = (f2 & mask32) * 100;
            b[3..5].* = dd(f4 >> 32);
            return 5;
        }

        b[0..2].* = dd(f0 >> 32);
        const f2: u64 = (f0 & mask32) * 100;
        b[2..4].* = dd(f2 >> 32);
        const f4: u64 = (f2 & mask32) * 100;
        b[4..6].* = dd(f4 >> 32);
        return p + 6;
    }

    if (n < 100_000_000) {
        const f0: u64 = @as(u64, 281474977) * n >> 16;

        if (n < 10_000_000) {
            buf[p] = "0123456789"[f0 >> 32];
            const f2: u64 = (f0 & mask32) * 100;
            b[1..3].* = dd(f2 >> 32);
            const f4: u64 = (f2 & mask32) * 100;
            b[3..5].* = dd(f4 >> 32);
            const f6: u64 = (f4 & mask32) * 100;
            b[5..7].* = dd(f6 >> 32);
            return p + 7;
        }

        b[0..2].* = dd(f0 >> 32);
        const f2: u64 = (f0 & mask32) * 100;
        b[2..4].* = dd(f2 >> 32);
        const f4: u64 = (f2 & mask32) * 100;
        b[4..6].* = dd(f4 >> 32);
        const f6: u64 = (f4 & mask32) * 100;
        b[6..8].* = dd(f6 >> 32);
        return p + 8;
    }

    const f0: u64 = 1441151881 * n;

    if (n < 1_000_000_000) {
        buf[p] = "0123456789"[f0 >> 57];
        const f2: u64 = (f0 & mask57) * 100;
        b[1..3].* = dd(f2 >> 57);
        const f4: u64 = (f2 & mask57) * 100;
        b[3..5].* = dd(f4 >> 57);
        const f6: u64 = (f4 & mask57) * 100;
        b[5..7].* = dd(f6 >> 57);
        const f8: u64 = (f6 & mask57) * 100;
        b[7..9].* = dd(f8 >> 57);
        return p + 9;
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
    return p + 10;
}

pub const Creation = struct {
    blocks: []u8,
    bpos: usize,
    connections: []u8,
    cpos: usize,
    handle: u32,

    pub fn compile(self: *Creation, writer: anytype) !void {
        if (self.bpos > 0) {
            try writer.writeAll(self.blocks[0 .. self.bpos - 1]);
            try writer.writeAll("?");
        }

        if (self.cpos > 0) {
            try writer.writeAll(self.connections[0 .. self.cpos - 1]);
            try writer.writeAll("?");
        }
    }

    pub inline fn addBlock(self: *Creation, id: NodeType, position: ?[3]i16, properties: ?[]const i16) void {
        const idInt = @intFromEnum(id);

        if (idInt < 10) {
            self.blocks[self.bpos] = idInt + '0';
            self.bpos += 1;
        } else {
            self.blocks[self.bpos..][0..2].* = dd(idInt);
            self.bpos += 2;
        }

        @as(*u16, @ptrFromInt(@intFromPtr(&self.blocks[self.bpos]))).* = 0x2C2C;
        self.bpos += 2;

        if (position) |pos| {
            self.bpos += fastFormatInt(pos[0], self.blocks[self.bpos..]);
            self.blocks[self.bpos] = ',';
            self.bpos += 1;
            self.bpos += fastFormatInt(pos[1], self.blocks[self.bpos..]);
            self.blocks[self.bpos] = ',';
            self.bpos += 1;
            self.bpos += fastFormatInt(pos[2], self.blocks[self.bpos..]);
            self.blocks[self.bpos] = ',';
            self.bpos += 1;
        } else {
            @as(*u32, @ptrFromInt(@intFromPtr(&self.blocks[self.bpos]))).* = 0x2C2C2C;
            self.bpos += 3;
        }

        if (properties) |prop| {
            for (prop) |val| {
                self.bpos += fastFormatInt(val, self.blocks[self.bpos..]);
                self.blocks[self.bpos] = '+';
                self.bpos += 1;
            }

            if (prop.len != 0) {
                self.bpos -= 1;
            }
        }
        self.blocks[self.bpos] = ';';
        self.bpos += 1;

        self.handle += 1;
    }
    pub inline fn addBlockH(self: *Creation, id: NodeType, position: ?[3]i16, properties: ?[]const i16) u32 {
        self.addBlock(id, position, properties);
        return self.handle;
    }

    pub inline fn connect(self: *Creation, nodeA: u32, nodeB: u32) void {
        self.cpos += fastFormatInt(nodeA, self.connections[self.cpos..]);
        self.connections[self.cpos] = ',';
        self.cpos += 1;
        self.cpos += fastFormatInt(nodeB, self.connections[self.cpos..]);
        self.connections[self.cpos] = ';';
        self.cpos += 1;
    }

    pub fn init(allocator: std.mem.Allocator, max_blocks: u32, max_connections: u32) !Creation {
        const block = 2 + 1 + 1 + 6 + 1 + 6 + 1 + 6 + 1 + (5 * 6) + 1;
        const connection = 10 + 1 + 10 + 1;

        return Creation{
            .blocks = try allocator.alloc(u8, block * max_blocks),
            .bpos = 0,
            .connections = try allocator.alloc(u8, connection * max_connections),
            .cpos = 0,
            .handle = 0,
        };
    }

    pub fn deinit(self: *Creation) void {
        self.* = undefined;
    }
};
