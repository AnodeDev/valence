const std = @import("std");
const ropeStructure = @import("ropeStructure.zig");

const Rope = ropeStructure.Rope;
const Allocator = std.mem.Allocator;

pub const Buffer = struct {
    content: *Rope,
    cursor: usize,

    pub fn init(allocator: Allocator) !Buffer {
        const rope = try Rope.initLeaf(allocator, "");

        return Buffer{
            .content = rope,
            .cursor = 0,
        };
    }

    pub fn moveCursorForward(self: *Buffer) void {
        if (self.cursor < self.content.getLength() - 1) {
            self.cursor += 1;
        }
    }

    pub fn moveCursorBackward(self: *Buffer) void {
        if (self.cursor > 0) {
            self.cursor -= 1;
        }
    }

    pub fn moveCursorToIndex(self: *Buffer, index: usize) void {
        if (index > 0 and index < self.content.getLength()) {
            self.cursor = index;
        }
    }

    pub fn insertBefore(self: *Buffer, allocator: Allocator, input: u8) !void {
        try self.content.insertBefore(allocator, self.cursor, input);
        self.cursor += 1;
    }

    pub fn deleteBefore(self: *Buffer, allocator: Allocator) !void {
        try self.content.deleteBefore(allocator, self.cursor);

        if (self.cursor > 0) {
            self.cursor -= 1;
        }
    }

    pub fn deinit(self: *const Buffer, allocator: Allocator) void {
        self.content.deinit(allocator);
    }
};
