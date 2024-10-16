const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const copyForwards = std.mem.copyForwards;
const testing = std.testing;

pub const AutoringError = error{EmptyQueue};

/// Returns a non thread safe ring buffer type with dynamic resizing
pub fn Autoring(comptime T: type) type {
    const min_len = 16;

    return struct {
        // users should not read/write directly from/to raw_buf
        raw_buf: []T,
        head: usize,
        tail: usize,
        count: usize,
        bitmask: usize,
        allocator: std.mem.Allocator,

        const Self = @This();

        /// Initializes the ring buffer with the given length if provided.
        /// `length` must be a power of 2 otherwise it will panic.
        pub fn init(allocator: std.mem.Allocator, length: ?usize) !*Self {
            const len = length orelse min_len;
            assert(math.isPowerOfTwo(len));

            const queue = try allocator.create(Self);
            queue.* = Self{
                .raw_buf = try allocator.alloc(T, len),
                .head = 0,
                .tail = 0,
                .count = 0,
                .bitmask = len - 1,
                .allocator = allocator,
            };
            return queue;
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.raw_buf);
            self.allocator.destroy(self);
        }

        /// Adds an element to the tail end of the queue.
        pub fn enqueue(self: *Self, element: T) !void {
            if (self.count == self.raw_buf.len) try self.resize();

            self.raw_buf[self.tail] = element;
            // will storing this bit mask once somewhere help with perf?
            self.tail = (self.tail + 1) & self.bitmask;
            self.count += 1;
        }

        /// Returns a copy of the element at the head of the queue.
        pub fn peek(self: *Self) AutoringError!T {
            if (self.count == 0) return AutoringError.EmptyQueue;
            return self.raw_buf[self.head];
        }

        /// Removes and returns the element at the head of the queue.
        pub fn dequeue(self: *Self) AutoringError!T {
            if (self.count == 0) return AutoringError.EmptyQueue;

            const element = self.raw_buf[self.head];
            // For now we can't set dequeued slots to null
            // as using a []?T was complicating our code
            //self.raw_buf[self.head] = null;
            self.head = (self.head + 1) & self.bitmask;
            self.count -= 1;

            return element;
        }

        fn resize(self: *Self) !void {
            const new_buf = try self.allocator.alloc(T, self.count << 1);

            if (self.tail > self.head) {
                copyForwards(T, new_buf, self.raw_buf[self.head..self.tail]);
            } else {
                copyForwards(T, new_buf, self.raw_buf[self.head..]);
                copyForwards(T, new_buf[(self.raw_buf.len - self.head)..], self.raw_buf[0..self.tail]);
            }
            self.head = 0;
            self.tail = self.count;
            self.raw_buf = new_buf;
            self.bitmask = (self.raw_buf.len - 1);
        }
    };
}

test "enqueue dequeue" {
    // +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
    // |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |
    // +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
    // Initially each element is filled with some garbage value
    const q = try Autoring(u32).init(testing.allocator, null);
    defer q.deinit();

    try testing.expectError(AutoringError.EmptyQueue, q.dequeue());
    try testing.expectError(AutoringError.EmptyQueue, q.peek());
    assert(q.raw_buf.len == 16);

    // Next we fill up the queue except the last element
    // +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
    // | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |10 |11 |12 |13 |14 |   |
    // +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
    //  ^                                                           ^
    // head(0)                                                      tail(15)
    const arr: [15]u8 = [_]u8{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 };
    for (arr) |i| {
        try q.enqueue(i);
    }

    assert(q.count == 15);
    assert(q.head == 0);
    assert(q.tail == 15);

    // on the next enqueue tail should wrap around & resizes
    // since (15 + 1) & ((16 - 1) = 0
    // +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---++---+. . . . .+---+
    // | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |10 |11 |12 |13 |14 |15 ||   |. . . . .|   |
    // +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---++---+. . . . .+---+
    //  ^                                                                   New slots added
    // head(0)                                                              len(32)
    // tail(0)
    try q.enqueue(15);
    assert(q.count == 16);
    assert(q.head == 0);
    assert(q.tail == 0);

    // head becomes larger than tail
    // +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+. . . . .+---+
    // | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |10 |11 |12 |13 |14 |15 |   |. . . . .|   |
    // +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+. . . . .+---+
    //  ^    ^
    // t(0)  h(1)
    //
    assert(try q.dequeue() == 0);
    assert(q.count == 15);
    assert(q.head == 1);
    assert(try q.peek() == 1);

    // drain buffer
    for (0..15) |_| {
        _ = try q.dequeue();
    }

    assert(q.count == 0);
    assert(q.head == 0);
    assert(q.tail == 0);
}
