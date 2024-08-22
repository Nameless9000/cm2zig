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

pub const Node = struct { id: NodeType, position: ?@Vector(3, i16) };

pub const Connection = struct { nodeA: u32, nodeB: u32 };


pub const Creation = struct {
  data: std.ArrayList(u8),
  connections: std.ArrayList(u8),
  handle: u32,

  pub fn compile(self: *Creation, writer: anytype) !void {
    if (self.data.items.len > 0) {
      _ = self.data.pop();
      try writer.writeAll(self.data.items);
      try self.data.appendSlice(";");

      try writer.writeAll("?");
    }

    if (self.connections.items.len > 0) {
      _ = self.connections.pop();
      try writer.writeAll(self.connections.items);
      try self.connections.appendSlice(";");

      try writer.writeAll("?");
    }
  }

  pub fn addBlock(self: *Creation, id: NodeType, position: ?@Vector(3, i16), properties: ?[]const i16) !void {
    const idInt = @intFromEnum(id);
    const writer = self.data.writer();

    if (idInt < 10) {
      try self.data.appendSlice(&[_]u8{idInt + '0', ',', ','});
    } if (idInt < 20) {
      try self.data.appendSlice(&[_]u8{'1', idInt % 10 + '0', ',', ','});
    } else {
      try self.data.appendSlice(&[_]u8{'2', idInt % 10 + '0', ',', ','});
    }

    if (position) |pos| {
      try std.fmt.formatInt(pos[0], 10, .lower, .{}, writer);
      try self.data.append(',');
      try std.fmt.formatInt(pos[1], 10, .lower, .{}, writer);
      try self.data.append(',');
      try std.fmt.formatInt(pos[2], 10, .lower, .{}, writer);
      try self.data.append(',');
    } else {
      try self.data.appendSlice(",,,");
    }

    if (properties) |prop| {
      for (prop) |val| {
        try std.fmt.formatInt(val, 10, .lower, .{}, writer);
        try self.data.append('+');
      }
      
      if (prop.len != 0) {
        _ = self.data.pop();
      }
    }
    try self.data.append(';');

    self.handle += 1;
  }
  pub inline fn addBlockH(self: *Creation, id: NodeType, position: ?@Vector(3, i16), properties: ?[]const i16) !u32 {
    try addBlock(self, id, position, properties);
    return self.handle;
  }

  pub inline fn connect(self: *Creation, nodeA: u32, nodeB: u32) !void {
    const writer = self.connections.writer();
    try std.fmt.formatInt(nodeA, 10, .lower, .{}, writer);
    try self.data.append(',');
    try std.fmt.formatInt(nodeB, 10, .lower, .{}, writer);
    try self.data.append(';');
  }

  pub fn init(allocator: std.mem.Allocator) Creation {
    return Creation {
      .data = std.ArrayList(u8).init(allocator),
      .connections = std.ArrayList(u8).init(allocator),
      .handle = 0,
    };
  }

  pub fn deinit(self: Creation) void {
    self.data.deinit();
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
    return Component {
      .creation = creation,
      .position = position,
    };
  }
};