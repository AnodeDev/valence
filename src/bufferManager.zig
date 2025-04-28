const std = @import("std");
const buffer_mod = @import("buffer.zig");

const Buffer = buffer_mod.Buffer;

pub const BufferManager = struct {
    buffers: []Buffer,
    buffer_count: usize,
    index: usize,

    pub fn init(allocator: std.mem.Allocator) !BufferManager {
        const scratch = try Buffer.initScratch(allocator);
        var buffers = try allocator.alloc(Buffer, 1);
        const buffer_count = 1;
        buffers[0] = scratch;

        return BufferManager{
            .buffers = buffers,
            .buffer_count = buffer_count,
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

    pub fn addBuffer(self: *BufferManager, allocator: std.mem.Allocator, buffer: Buffer) !void {
        if (self.buffer_count + 1 > self.buffers.len) {
            const buffers = try allocator.alloc(Buffer, self.buffer_count * 2);
            @memcpy(buffers[0..self.buffers.len], self.buffers);

            allocator.free(self.buffers);
            self.buffers = buffers;
        }

        self.buffers[self.buffer_count] = buffer;
        self.buffer_count += 1;
    }
};
