const maker = @import("maker.zig");

// sizeX: 3, sizeY: <bits>, sizeZ: 1
pub fn makeRegister(creation: *maker.Creation, bits: u16, position: ?@Vector(3, i16)) u32 {
    const handle: u32 = creation.handle + 1;

    var i: i16 = 0;
    while (i < bits) : (i += 1) {
        const start = creation.handle;
        if (position) |pos| {
            creation.addBlock(.XOR, pos + @as(@Vector(3, i16), .{ 2, i, 0 }), null);
            creation.addBlock(.AND, pos + @as(@Vector(3, i16), .{ 1, i, 0 }), null);
            creation.addBlock(.FLIPFLOP, pos + @as(@Vector(3, i16), .{ 0, i, 0 }), null);
        } else {
            creation.addBlock(.XOR, null, null);
            creation.addBlock(.AND, null, null);
            creation.addBlock(.FLIPFLOP, null, null);
        }

        creation.connect(start + 1, start + 2);
        creation.connect(start + 2, start + 3);
        creation.connect(start + 3, start + 1);
    }

    return handle;
}

pub fn getRegisterInput(handle: u32, bit: u16) u32 {
    return handle + (bit * 3);
}
pub fn getRegisterWrite(handle: u32, bit: u16) u32 {
    return handle + (bit * 3) + 1;
}
pub fn getRegisterOutput(handle: u32, bit: u16) u32 {
    return handle + (bit * 3) + 2;
}
