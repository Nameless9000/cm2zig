pub fn main() !void {
    try @import("bench/maker.zig").run();
    try @import("bench/memory.zig").run();
}
