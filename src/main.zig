const std = @import("std");
const ropeStructure = @import("ropeStructure.zig");
const buffer = @import("buffer.zig");

const Rope = ropeStructure.Rope;
const Allocator = std.mem.Allocator;

pub fn main() !void {
    std.debug.print("VALENCE!", .{});
}

test "initLeaf initializes with correct content and length" {
    const allocator = std.testing.allocator;
    const rope = try Rope.initLeaf(allocator, @constCast("test"[0..]));
    defer rope.deinit(allocator);

    try std.testing.expectEqual(@as(usize, 4), rope.getLength());

    const slice = try rope.flatten(allocator);
    defer allocator.free(slice);

    try std.testing.expectEqualStrings("test", slice);
}

test "concat combines two ropes correctly" {
    const allocator = std.testing.allocator;
    const rope1 = try Rope.initLeaf(allocator, "Hello ");
    const rope2 = try Rope.initLeaf(allocator, "World!");

    const rope = try Rope.concat(allocator, rope1, rope2);
    defer rope.deinit(allocator);

    try std.testing.expectEqual(@as(usize, 12), rope.getLength());

    const slice = try rope.flatten(allocator);
    defer allocator.free(slice);

    try std.testing.expectEqualStrings("Hello World!", slice);
}

test "insertBefore inserts at the correct position" {
    const allocator = std.testing.allocator;
    const rope = try Rope.initLeaf(allocator, "abcd");
    defer rope.deinit(allocator);

    try rope.insertBefore(allocator, 2, "xyz");

    try std.testing.expectEqual(@as(usize, 7), rope.getLength());

    const slice = try rope.flatten(allocator);
    defer allocator.free(slice);

    try std.testing.expectEqualStrings("abxyzcd", slice);
}

// TODO:
//  - Implement rope.
//  - Implement Buffer struct + BufferHandler struct.
//  - File loading.
//
// Late-game TODO:
//  - Bit-pack several characters together (efficient storage).
