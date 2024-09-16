// https://en.wikipedia.org/wiki/Circular_buffer
const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const copyForwards = std.mem.copyForwards;
const testing = std.testing;

// https://github.com/eapache/queue/tree/main

pub const AutoringError = error{EmptyQueue};

pub fn Queue(comptime T: type) type {
    const min_queue_len = 16;

    return struct {
        buf: []T,
        head: usize,
        tail: usize,
        count: usize,
        allocator: std.mem.Allocator,

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator, queue_len: ?usize) !*Self {
            const len = queue_len orelse min_queue_len;
            assert(math.isPowerOfTwo(len));

            const queue = try allocator.create(Self);
            queue.* = Self{
                .buf = try allocator.alloc(T, len),
                .head = 0,
                .tail = 0,
                .count = 0,
                .allocator = allocator,
            };
            return queue;
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.buf);
            self.allocator.destroy(self);
        }

        pub fn enqueue(self: *Self, element: T) !void {
            if (self.count == self.buf.len) try self.resize();

            self.buf[self.tail] = element;
            self.tail = (self.tail + 1) & (self.buf.len - 1);
            self.count += 1;
        }

        pub fn peek(self: *Self) AutoringError!T {
            if (self.count == 0) return AutoringError.EmptyQueue;
            return self.buf[self.head];
        }

        // Get returns the element at index i in the queue. If the index is
        // invalid, the call will panic. This method accepts both positive and
        // negative index values. Index 0 refers to the first element, and
        // index -1 refers to the last.
        //pub fn get(self: *Self, index: isize) T {
        //    if (index < 0) index += self.count;
        //    if (index < 0 || (index > @as(isize, self.count))) @panic("index out of range");
        //    return self.buf[(self.heal + 1) & (self.buf.len - 1)];
        //}

        pub fn dequeue(self: *Self) AutoringError!T {
            if (self.count == 0) return AutoringError.EmptyQueue;

            const element = self.buf[self.head];
            //self.buf[self.head] = null;
            self.head = (self.head + 1) & (self.buf.len - 1);
            self.count -= 1;

            return element;
        }

        // returns capacity of the buf
        //pub fn capacity(self: *Self) {}

        // returns available free slots
        //pub fn capacity(self: *Self) {}

        fn resize(self: *Self) !void {
            const new_buf = try self.allocator.alloc(T, self.count << 1);

            if (self.tail > self.head) {
                copyForwards(T, new_buf, self.buf[self.head..self.tail]);
            } else {
                copyForwards(T, new_buf, self.buf[self.head..]);
                copyForwards(T, new_buf[(self.buf.len - self.head)..], self.buf[0..self.tail]);
            }
            self.head = 0;
            self.tail = self.count;
            self.buf = new_buf;
        }
    };
}

//test "non power of 2 len should panic" {
//    const q = Queue(u32).init(testing.allocator, 7);
//    testing.expectError(error.Panic, q);
//}

test "default len should be 16" {
    const q = try Queue(u32).init(testing.allocator, null);
    defer q.deinit();
    assert(q.buf.len == 16);
}

test "enqueue dequeue" {
    // +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
    // |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |
    // +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
    // Initially each element is filled with some garbage value
    const q = try Queue(u32).init(testing.allocator, null);
    defer q.deinit();

    try testing.expectError(AutoringError.EmptyQueue, q.dequeue());
    try testing.expectError(AutoringError.EmptyQueue, q.peek());
    assert(q.buf.len == 16);

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
