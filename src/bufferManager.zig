const std = @import("std");
const buffer_mod = @import("buffer.zig");

const Buffer = buffer_mod.Buffer;

pub const BufferManager = struct {
    buffers: []Buffer,
    index: usize,

    pub fn init(allocator: std.mem.Allocator) !BufferManager {
        const scratch = try Buffer.initScratch(allocator);
        var buffers = try allocator.alloc(Buffer, 1);
        buffers[0] = scratch;

        return BufferManager{
            .buffers = buffers,
            .index = 0,
        };
    }

    pub fn deinit(self: *const BufferManager, allocator: std.mem.Allocator) void {
        for (0..self.buffers.len) |i| {
            self.buffers[i].deinit(allocator);
        }

        allocator.free(self.buffers);
    }

    pub fn getActiveBuffer(self: *const BufferManager) *Buffer {
        return &self.buffers[self.index];
    }
};
