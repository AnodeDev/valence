const std = @import("std");
const rope = @import("rope.zig");

const Rope = rope.Rope;
const Allocator = std.mem.Allocator;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const stdout = std.io.getStdOut().writer();

    const hello = try Rope.initLeaf(allocator, @constCast("Hello "[0..]));
    const my = try Rope.initLeaf(allocator, @constCast("my "[0..]));
    const hello_my = try Rope.concat(allocator, hello, my);
    const name = try Rope.initLeaf(allocator, @constCast("name "[0..]));
    const is = try Rope.initLeaf(allocator, @constCast("is "[0..]));
    const name_is = try Rope.concat(allocator, name, is);
    const dexter = try Rope.initLeaf(allocator, @constCast("Dexter"[0..]));
    const name_is_dexter = try Rope.concat(allocator, name_is, dexter);

    const final = try Rope.concat(allocator, hello_my, name_is_dexter);

    std.debug.print("Content({d}):\n", .{ final.getLength() });
    try final.print(allocator);
    std.debug.print("\n\n", .{});

    std.debug.print("\nNodes:\n", .{});
    try final.tree(stdout, 0);
    std.debug.print("\n\n", .{});

    const substring = try final.substring(allocator, 6, 13);
    std.debug.print("Substring(6, 13): ", .{});
    try substring.print(allocator);
    std.debug.print("\n\n", .{});

    try final.insert_before(allocator, 17, @constCast("J. "[0..]));
    std.debug.print("Content updated({d}):\n", .{ final.getLength() });
    try final.print(allocator);
    std.debug.print("\n\n", .{});
}

// TODO:
//  - Implement rope.
//  - Implement Buffer struct + BufferHandler struct.
//  - File loading.
//
// Late-game TODO:
//  - Bit-pack several characters together (efficient storage).
