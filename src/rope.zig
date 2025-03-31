const std = @import("std");

const math = std.math;
const Allocator = std.mem.Allocator;

pub const Rope = struct {
    const Node = union(enum) {
        leaf: Leaf,
        internal: Internal,
    };

    const Leaf = struct {
        text: []u8,
    };

    const Internal = struct {
        left: *Rope,
        right: *Rope,
        length: usize, // Total length of left subtree
    };

    node: Node,

    pub fn initLeaf(allocator: Allocator, text: []u8) !*Rope {
        const duped_text = try allocator.dupe(u8, text);
        const rope = try allocator.create(Rope);

        rope.* = .{
            .node = .{
                .leaf = .{
                    .text = duped_text,
                },
            },
        };

        return rope;
    }

    pub fn getLength(self: *Rope) usize {
        return switch (self.node) {
            .leaf => |leaf| leaf.text.len,
            .internal => |internal| internal.length + internal.right.getLength(),
        };
    }

    pub fn concat(allocator: Allocator, left: *Rope, right: *Rope) !*Rope {
        const rope = try allocator.create(Rope);

        rope.* = .{
            .node = .{
                .internal = .{
                    .left = left,
                    .right = right,
                    .length = left.getLength(),
                },
            },
        };

        return rope;
    }

    pub fn substring(self: *Rope, allocator: Allocator, start: usize, end: usize) !*Rope {
        if (start > end or end > self.getLength()) return error.IndexOutOfRange;

        switch (self.node) {
            .leaf => |leaf| return Rope.initLeaf(allocator, leaf.text[start..end]),
            .internal => |internal| {
                if (end <= internal.length) {
                    return internal.left.substring(allocator, start, end);
                } else if (start >= internal.length) {
                    return internal.right.substring(allocator, start - internal.length, end - internal.length);
                } else {
                    const left_sub = try internal.left.substring(allocator, start, internal.length);
                    const right_sub = try internal.right.substring(allocator, 0, end - internal.length);

                    return concat(allocator, left_sub, right_sub);
                }
            },
        }
    }

    pub fn insert_before(self: *Rope, allocator: Allocator, cursor: usize, text: []u8) !void {
        if (text.len == 0 or cursor > self.getLength()) {
            std.debug.print("{d} == 0: {}\n", .{ text.len, text.len == 0 });
            std.debug.print("{d} + {d} > {d}: {}\n", .{ cursor, text.len, self.getLength(), cursor + text.len > self.getLength() });
            std.debug.print("Node: {s}\n", .{ try self.combine(allocator) });

            return error.IndexOutOfRange;
        }

        switch (self.node) {
            .leaf => |*leaf| {
                const left = try Rope.initLeaf(allocator, leaf.*.text[0..cursor]);
                const right = try Rope.initLeaf(allocator, leaf.*.text[cursor..]);
                const new = try Rope.initLeaf(allocator, text);

                const new_left = try Rope.concat(allocator, left, new);
                const new_leaf = try Rope.concat(allocator, new_left, right);

                allocator.free(leaf.text);

                leaf.text = try new_leaf.combine(allocator);

                allocator.destroy(new_leaf);
            },
            .internal => |*internal| {
                if (cursor <= internal.length) {
                    try internal.left.insert_before(allocator, cursor, text);
                } else {
                    try internal.right.insert_before(allocator, cursor - internal.left.getLength(), text);
                }
            },
        }
    }

    pub fn tree(self: *const Rope, writer: anytype, depth: usize) !void {
        const indent = depth * 2;
        try writer.writeByteNTimes(' ', indent);

        switch (self.node) {
            .leaf => |leaf| try writer.print("Leaf: \"{s}\"\n", .{ leaf.text }),
            .internal => |internal| {
                try writer.print("Internal({d})\n", .{ internal.length });
                try internal.left.tree(writer, depth + 1);
                try internal.right.tree(writer, depth + 1);
            },
        }
    }

    pub fn combine(self: *const Rope, allocator: Allocator) ![]u8 {
        switch (self.node) {
            .leaf => |leaf| return leaf.text,
            .internal => |internal| {
                const left = try internal.left.combine(allocator);
                const right = try internal.right.combine(allocator);

                return std.mem.concat(allocator, u8, ([_][]u8{ left, right })[0..]);
            },
        }
    }

    pub fn print(self: *const Rope, allocator: Allocator) !void {
        std.debug.print("\"{s}\"", .{ try self.combine(allocator) });
    }

    pub fn deinit(self: *Rope, allocator: Allocator) void {
        switch (self.node) {
            .leaf => |leaf| allocator.free(leaf.text),
            .internal => |internal| {
                internal.left.deinit(allocator);
                internal.right.deinit(allocator);
            },
        }

        allocator.destroy(self);
    }
};
