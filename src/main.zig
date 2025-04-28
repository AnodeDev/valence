const std = @import("std");
const rope_structure_mod = @import("ropeStructure.zig");
const buffer_mod = @import("buffer.zig");
const buffer_manager_mod = @import("bufferManager.zig");

const Rope = rope_structure_mod.Rope;
const Buffer = buffer_mod.Buffer;
const BufferManager = buffer_manager_mod.BufferManager;
const Allocator = std.mem.Allocator;

pub fn main() !void {}

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

    try rope.insertBefore(allocator, 2, 'x');

    try std.testing.expectEqual(@as(usize, 5), rope.getLength());

    const slice = try rope.flatten(allocator);
    defer allocator.free(slice);

    try std.testing.expectEqualStrings("abxcd", slice);
}

test "Buffer insert and delete" {
    const allocator = std.testing.allocator;
    var testBuffer = try Buffer.init(allocator);
    defer testBuffer.deinit(allocator);

    try testBuffer.insertBefore(allocator, 'H');
    try testBuffer.insertBefore(allocator, 'e');
    try testBuffer.insertBefore(allocator, 'l');
    try testBuffer.insertBefore(allocator, 'l');
    try testBuffer.insertBefore(allocator, 'l');
    try testBuffer.insertBefore(allocator, 'o');

    testBuffer.moveCursorBackward();
    try testBuffer.deleteBefore(allocator);

    try std.testing.expectEqual(@as(usize, 5), testBuffer.content.getLength());

    const slice = try testBuffer.content.flatten(allocator);
    defer allocator.free(slice);

    try std.testing.expectEqualStrings("Hello", slice);
}

test "BufferManager buffer adding and switching" {
    const allocator = std.testing.allocator;
    var manager = try BufferManager.init(allocator);
    defer manager.deinit(allocator);

    const buffer = try Buffer.init(allocator);
    try manager.addBuffer(allocator, buffer);

    try std.testing.expectEqual(2, manager.buffer_count);

    manager.index += 1;

    var second_buffer = manager.getActiveBuffer();
    try second_buffer.insertLine(allocator, "Hello from the second buffer!");
    
    try std.testing.expectEqual(1, manager.index);

    const slice = try second_buffer.content.flatten(allocator);
    defer allocator.free(slice);

    try std.testing.expectEqualStrings("Hello from the second buffer!", slice);
}

// TODO:
//  - Implement Buffer struct + BufferHandler struct.
//  - File loading.
//
// Late-game TODO:
//  - Bit-pack several characters together (efficient storage).
