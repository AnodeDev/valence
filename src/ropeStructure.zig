const std = @import("std");

const math = std.math;
const Allocator = std.mem.Allocator;

const TARGET_LEAF_SIZE = 512;

// A Rope is a data structure that builds a tree structure out of the text
// This allows for fast insert, delete, and searches
pub const Rope = struct {
    // A node can either be an end node (leaf), or hold two child nodes (branch)
    const Node = union(enum) {
        leaf: Leaf,
        branch: Branch,
    };

    const Leaf = struct {
        text: []u8,
    };

    const Branch = struct {
        left: *Rope,
        right: *Rope,
        leftLength: usize,
        rightLength: usize,
    };

    // Rope field
    node: Node,

    // Entry point of a Rope should always only be a leaf
    pub fn initLeaf(allocator: Allocator, text: []const u8) !*Rope {
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

    // Gets the total length of Rope, including child nodes
    pub fn getLength(self: *const Rope) usize {
        return switch (self.node) {
            .leaf => |leaf| leaf.text.len,
            .branch => |branch| branch.leftLength + branch.rightLength,
        };
    }

    // Combines two Ropes into one
    pub fn concat(allocator: Allocator, left: *Rope, right: *Rope) !*Rope {
        const rope = try allocator.create(Rope);

        rope.* = .{
            .node = .{
                .branch = .{
                    .left = left,
                    .right = right,
                    .leftLength = left.getLength(),
                    .rightLength = right.getLength(),
                },
            },
        };

        return rope;
    }

    // Extracts part of the Rope into a new Rope
    pub fn substring(self: *Rope, allocator: Allocator, start: usize, end: usize) !*Rope {
        if (start > end or end > self.getLength()) return error.InvalidRange;

        switch (self.node) {
            .leaf => |leaf| return Rope.initLeaf(allocator, leaf.text[start..end]),
            .branch => |branch| {
                if (end <= branch.leftLength) {
                    return branch.left.substring(allocator, start, end);
                } else if (start >= branch.leftLength) {
                    return branch.right.substring(allocator, start - branch.leftLength, end - branch.leftLength);
                } else {
                    const left_sub = try branch.left.substring(allocator, start, branch.leftLength);
                    const right_sub = try branch.right.substring(allocator, 0, end - branch.leftLength);

                    return concat(allocator, left_sub, right_sub);
                }
            },
        }
    }

    pub fn insertBefore(self: *Rope, allocator: Allocator, cursor: usize, text: []const u8) !void {
        if (text.len == 0 or cursor > self.getLength()) return error.IndexOutOfRange;

        switch (self.node) {
            .leaf => |*leaf| {
                // Has to divide the leaf in order to insert the new text
                const left = try Rope.initLeaf(allocator, leaf.*.text[0..cursor]);
                const right = try Rope.initLeaf(allocator, leaf.*.text[cursor..]);
                const new = try Rope.initLeaf(allocator, text);

                const new_left = try Rope.concat(allocator, left, new);
                const new_leaf = try Rope.concat(allocator, new_left, right);

                allocator.free(leaf.text);
                leaf.text = try new_leaf.flatten(allocator);

                new_leaf.deinit(allocator);
            },
            .branch => |*branch| {
                if (cursor <= branch.leftLength) {
                    try branch.left.insertBefore(allocator, cursor, text);
                } else {
                    try branch.right.insertBefore(allocator, cursor - branch.leftLength, text);
                }
            },
        }
    }

    pub fn balance(self: *Rope, allocator: Allocator) !void {
        const buffer = try self.flatten(allocator);
        defer allocator.free(buffer);

        var leaves = std.ArrayList(*Rope).init(allocator);
        var i: usize = 0;

        while (i < buffer.len) {
            const end = @min(i + TARGET_LEAF_SIZE, buffer.len);
            const chunk = buffer[i..end];
            const leaf = try Rope.initLeaf(allocator, chunk);
            try leaves.append(leaf);
            i = end;
        }

        const balanced = try Rope.buildBalancedRope(allocator, leaves.items);
        errdefer balanced.deinit(allocator);

        self.deinitNodes(allocator);

        self.node = balanced.node;
        balanced.node = undefined;
        allocator.destroy(balanced);
    }

    fn buildBalancedRope(allocator: Allocator, nodes: []*Rope) !*Rope {
        if (nodes.len == 1) return nodes[0];

        var parents = std.ArrayList(*Rope).init(allocator);
        defer parents.deinit();

        var i: usize = 0;

        while (i < nodes.len) : (i += 2) {
            if (i + 1 >= nodes.len) {
                try parents.append(nodes[i]);
            } else {
                const combined = try Rope.concat(allocator, nodes[i], nodes[i + 1]);
                try parents.append(combined);
            }
        }

        return Rope.buildBalancedRope(allocator, parents.items);
    }

    // Flattens the Rope into a u8 slice
    // TODO: Optimize by flattening only relevant parts of the Rope
    pub fn flatten(self: *const Rope, allocator: Allocator) ![]u8 {
        const len = self.getLength();
        const result = try allocator.alloc(u8, len);
        var offset: usize = 0;
        try self.copyInto(result, &offset);

        return result;
    }

    // Copies the whole Rope into a u8 slice
    // TODO: Optimize to only copy relevant parts of the Rope
    fn copyInto(self: *const Rope, buffer: []u8, offset: *usize) !void {
        switch (self.node) {
            .leaf => |leaf| {
                const start = offset.*;
                const end = start + leaf.text.len;

                if (end > buffer.len) return error.BufferTooSmall;

                @memcpy(buffer[start..end], leaf.text);
                offset.* = end;
            },
            .branch => |branch| {
                try branch.left.copyInto(buffer, offset);
                try branch.right.copyInto(buffer, offset);
            },
        }
    }

    // Prints the Rope as a tree with proper indentation
    // Mostly for debugging
    pub fn tree(self: *const Rope, writer: anytype, depth: usize) !void {
        const indent = depth * 2;
        try writer.writeByteNTimes(' ', indent);

        switch (self.node) {
            .leaf => |leaf| try writer.print("Leaf: \"{s}\"\n", .{ leaf.text }),
            .branch => |branch| {
                try writer.print("branch({d})\n", .{ branch.leftLength + branch.rightLength });
                try branch.left.tree(writer, depth + 1);
                try branch.right.tree(writer, depth + 1);
            },
        }
    }

    // Prints the contents of the rope as a single u8 slice
    pub fn print(self: *const Rope, allocator: Allocator) !void {
        std.debug.print("\"{s}\"", .{ try self.flatten(allocator) });
    }

    pub fn deinitNodes(self: *Rope, allocator: Allocator) void {
        switch (self.node) {
            .leaf => |leaf| allocator.free(leaf.text),
            .branch => |branch| {
                branch.left.deinit(allocator);
                branch.right.deinit(allocator);
            },
        }
    }

    pub fn deinit(self: *Rope, allocator: Allocator) void {
        self.deinitNodes(allocator);
        allocator.destroy(self);
    }
};
